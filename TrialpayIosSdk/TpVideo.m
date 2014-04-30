//
//  TpVideo.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2014 TrialPay, Inc. All Rights Reserved.
//

#import "TpVideo.h"
#import "TpVideoViewController.h"
#import "TpVideoEndcapViewController.h"
#import "TpAppStoreViewController.h"
#import "BaseTrialpayManager.h"
#import "TpDataStore.h"
#import "TpArcSupport.h"
#import "TpUtils.h"

@interface TpVideo ()
// Forward declare these methods so they're available to TpVideoConnectionDelegate
- (NSString *)getLocalVideoPathForURL:(NSString *)downloadURL;
- (id)getMetaDataWithKey:(NSString *)key forURL:(NSString *)downloadURL;
- (BOOL)setMetaData:(id)data withKey:(NSString *)key forURL:(NSString *)downloadURL;
- (void)markDownloadCompleteForURL:(NSString *)downloadURL withSuccess:(BOOL)isSuccess withReattempt:(BOOL)isReattempt;
@end

@interface TpVideoConnectionDelegate : NSObject
@end

@implementation TpVideoConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSString *downloadURL = [[[connection originalRequest] URL] absoluteString];
    TPLog(@"Connection failure for resource %@ -- Error code: %d. Error description: %@", downloadURL, (int)error.code, error.localizedDescription);
    [connection cancel];
    [[TpVideo sharedInstance] markDownloadCompleteForURL:downloadURL withSuccess:NO withReattempt:YES];
}

// This function is always called unless we encounter an error before the response could be created, in which case connection:didFailWithError: will be called.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSString *downloadURL = [[[connection originalRequest] URL] absoluteString];
    long long expectedContentLength = [response expectedContentLength];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSInteger statusCode = [httpResponse statusCode];
    NSString *statusDescription = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
    TPLog(@"Received response from %@ with expected content length %lld and status: %ld - %@", downloadURL, expectedContentLength, (long)statusCode, statusDescription);
    if ((statusCode >= 200) && (statusCode < 400)) {
        if ((statusCode == 206) && ![[TpVideo sharedInstance] getMetaDataWithKey:@"hasRetriedRequest" forURL:downloadURL]) {
            // Occassionally CloudFront will give partial content responses even when we've requested the entire file. Possibly
            // a cache issue? It seems to be providing the response to a previous, valid request for partial content (which we send
            // after an originial request fails). This happens rarely and until we track down the solution, check for partial-
            // content responses on our first request (before we've set hasRetriedRequest). A partial-content response here
            // should never happen and indicates a problem.
            // Don't reattempt the request because if it happens again we won't be able to detect the error (since we'll be on
            // our 2nd request then).
            // UPDATE: turns out this was from Apple's local caching. We can bypass the cache to solve the problem. We'll remove
            // this failsafe here once we've confirmed the fix.
            TPLog(@"Received partial-content response on first request for resource %@ - incoming data is likely corrupted. Cancelling the request.", downloadURL);
            [connection cancel];
            [[TpVideo sharedInstance] markDownloadCompleteForURL:downloadURL withSuccess:NO withReattempt:NO];
            return;
        }
        // The request was successful. Video data will now be progressively downloaded and received by connection:didReceiveData:.
        if (![[TpVideo sharedInstance] getMetaDataWithKey:@"expectedFileSize" forURL:downloadURL]) {
            // We haven't already recorded an expected file size for the video. Attempt to record it now.
            if (expectedContentLength != NSURLResponseUnknownLength) {
                // We'll mark the download as complete within connection:didReceiveData:.
                [[TpVideo sharedInstance] setMetaData:[NSNumber numberWithLongLong:expectedContentLength] withKey:@"expectedFileSize" forURL:downloadURL];
            } else {
                // We're unable to determine the expected size of the video, so we'll be unable to determine when the download is complete.
                // Just mark the video as complete now.
                [[TpVideo sharedInstance] markDownloadCompleteForURL:downloadURL withSuccess:YES withReattempt:NO];
            }
        }
    } else {
        // We've received a non-success status code.
        [connection cancel];
        [[TpVideo sharedInstance] markDownloadCompleteForURL:downloadURL withSuccess:NO withReattempt:YES];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)receivedData {
    NSString *downloadURL = [[[connection originalRequest] URL] absoluteString];
    // Determine the local file path
    NSString *filePath = [[TpVideo sharedInstance] getLocalVideoPathForURL:downloadURL];
    if (filePath == nil) {
        // We could not determine or create the local path. We won't reattempt the request since we expect the same failure.
        TPLog(@"Could not determine file path in connection:didReceiveData. Cancelling the connection.");
        [connection cancel];
        [[TpVideo sharedInstance] markDownloadCompleteForURL:downloadURL withSuccess:NO withReattempt:NO];
        return;
    }
    // Append new data to existing data, if any
    NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:filePath];
    if (fileData == nil) {
        fileData = [NSMutableData dataWithCapacity:[receivedData length]];
    }
    [fileData appendData:receivedData];
    // Write the updated data
    NSError *writeError = nil;
    [fileData writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
    if (writeError != nil) {
        TPLog(@"Reattempting video download - failed to write local video file during load. Error code: %ld. Error description: %@", (long)writeError.code, writeError.localizedDescription);
        [connection cancel];
        [[TpVideo sharedInstance] markDownloadCompleteForURL:downloadURL withSuccess:NO withReattempt:YES];
        return;
    }
    long long storedBytes = (long long)[fileData length];
    TPLog(@"connection:didReceiveData: stored %lld bytes from resource %@", storedBytes, downloadURL);
    // Check if the video download is complete.
    if (![[TpVideo sharedInstance] getMetaDataWithKey:@"isCompleteVideoStored" forURL:downloadURL]) {
        NSNumber *expectedFileSize = [[TpVideo sharedInstance] getMetaDataWithKey:@"expectedFileSize" forURL:downloadURL];
        // We should always have the expectedFileSize here, because connection:didReceiveResponse: should have marked the video as
        // complete if we were unable to determine the expected size. But if we somehow fail to retrieve the expected file size, it's
        // safer to just mark the video as complete.
        if ((expectedFileSize == nil) || (storedBytes >= [expectedFileSize longLongValue])) {
            [[TpVideo sharedInstance] markDownloadCompleteForURL:downloadURL withSuccess:YES withReattempt:NO];
        }
    }
}

@end

@implementation TpVideo {
    NSMutableDictionary *_tpVideoMetaData; // A mapping from remote resource URL (downloadURL) to subdictionaries of video metadata
    NSString *_tpVideoFileDirectory; // The directory in which local video files are stored
    NSOperationQueue *_tpVideoOperationQueue; // Create our own operation queue so we don't have to pass the queue from BaseTrialpayManager
    BOOL _didHideStatusBar;

    TpVideoViewController *_videoViewController; // View controller for playing the video.
    UIWebView *_endcapWebView; // Used for displaying the endcap after video completion.
    TpVideoEndcapViewController *_endcapViewController; // View controller for endcap webview.
    TpAppStoreViewController *_storeViewController; // View controller for in-app app store.
    void (^_closeTrailerBlock)(void);
    BOOL _isStoreViewLoaded;
    BOOL _isStoreViewOpened;
    BOOL _isWebViewLoaded;
    BOOL _isWebViewOpened;
    BOOL _isVideoBeingShown;
}

#pragma mark - Init, Dealloc, and Singleton

- (id)init {
    if ((self = [super init])) {
        _isVideoBeingShown = NO;
        _isStoreViewOpened = NO;
        _isWebViewOpened = NO;

        _tpVideoOperationQueue = [[NSOperationQueue alloc] init];
        _tpVideoOperationQueue.name = @"TP Video Operation Queue";

        // Load the collected metadata
        _tpVideoMetaData = [[[TpDataStore sharedInstance] dataValueForKey:kTPKeyVideoMetaData] TP_RETAIN];
        if (_tpVideoMetaData == nil) {
            _tpVideoMetaData = [[NSMutableDictionary alloc] init];
        }

        // Determine the directory for storing local video files. Create the directory if it does not exist.
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *tpVidDirectory = [[cachesDirectory stringByAppendingPathComponent:@"tpv"] TP_RETAIN];
        if ([[NSFileManager defaultManager] fileExistsAtPath:tpVidDirectory]) {
            _tpVideoFileDirectory = tpVidDirectory;
        } else {
            NSError *createDirectoryError = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:tpVidDirectory withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
            if (createDirectoryError == nil) {
                _tpVideoFileDirectory = tpVidDirectory;
            } else {
                [tpVidDirectory TP_RELEASE];
                _tpVideoFileDirectory = nil;
                TPLog(@"Failure creating tpv directory. Error code: %ld. Error description: %@", (long)createDirectoryError.code, createDirectoryError.localizedDescription);
            }
        }
    }
    return self;
}

- (void)dealloc {
    [_tpVideoOperationQueue TP_RELEASE];
    [_tpVideoFileDirectory TP_RELEASE];
    [_tpVideoMetaData TP_RELEASE];
    _tpVideoMetaData = nil;
    [_videoViewController TP_RELEASE];
    [_endcapWebView TP_RELEASE];
    [_endcapViewController TP_RELEASE];
    [_storeViewController TP_RELEASE];
    [_closeTrailerBlock TP_RELEASE];
    [super TP_DEALLOC];
}

TpVideo *__tpVideoSingleton;
+(TpVideo *)sharedInstance {
    if (__tpVideoSingleton == nil) __tpVideoSingleton = [[TpVideo alloc] init];
    return __tpVideoSingleton;
}

#pragma mark - Video Metadata

/*
  Video metadata should be accessed and modified through 4 helper methods for access, storage, and deletion:
    - (id)getMetaDataWithKey:(NSString *)key forURL:(NSString *)downloadURL;
    - (BOOL)setMetaData:(id)data withKey:(NSString *)key forURL:(NSString *)downloadURL;
    - (BOOL)removeMetaDataWithKey:(NSString *)key forURL:(NSString *)downloadURL;
    - (BOOL)removeAllMetaDataForURL:(NSString *)downloadURL;

  The following 2 methods should NOT be called outside of the above 4 helper methods! These 2 functions work on the entire metadata for an offer:
    - (NSMutableDictionary *)getMetaDataForURL:(NSString *)downloadURL;
    - (BOOL)saveMetaData:(NSMutableDictionary *)metaData forURL:(NSString *)downloadURL;

*/

- (NSMutableDictionary *)getMetaDataForURL:(NSString *)downloadURL {
    NSMutableDictionary *metaData = [_tpVideoMetaData objectForKey:downloadURL];
    if (metaData == nil) {
        metaData = [[[NSMutableDictionary alloc] init] TP_AUTORELEASE];
        [_tpVideoMetaData setObject:metaData forKey:downloadURL];
    }
    return metaData;
}

- (BOOL)saveMetaData:(NSMutableDictionary *)metaData forURL:(NSString *)downloadURL {
    [_tpVideoMetaData setObject:metaData forKey:downloadURL];
    BOOL res = [[TpDataStore sharedInstance] setDataWithValue:_tpVideoMetaData forKey:kTPKeyVideoMetaData];
    return res;
}

- (BOOL)removeAllMetaDataForURL:(NSString *)downloadURL {
    [_tpVideoMetaData removeObjectForKey:downloadURL];
    BOOL res = [[TpDataStore sharedInstance] setDataWithValue:_tpVideoMetaData forKey:kTPKeyVideoMetaData];
    return res;
}

- (id)getMetaDataWithKey:(NSString *)key forURL:(NSString *)downloadURL {
    NSMutableDictionary *metaData = [self getMetaDataForURL:downloadURL];
    return [metaData valueForKey:key];
}

- (BOOL)setMetaData:(id)data withKey:(NSString *)key forURL:(NSString *)downloadURL {
    NSMutableDictionary *metaData = [self getMetaDataForURL:downloadURL];
    if (data && ![data isEqual:[metaData valueForKey:key]]) {
        [metaData setValue:data forKey:key];
        return [self saveMetaData:metaData forURL:downloadURL];
    }
    return YES; // The data was already stored on the metadata.
}

- (BOOL)removeMetaDataWithKey:(NSString *)key forURL:(NSString *)downloadURL {
    NSMutableDictionary *metaData = [self getMetaDataForURL:downloadURL];
    if ([metaData valueForKey:key]) {
        [metaData removeObjectForKey:key];
        return [self saveMetaData:metaData forURL:downloadURL];
    }
    return YES; // The key was already absent from metadata.
}

#pragma mark - Removing Video Data

// Delete the local video file and discard metadata.
- (void)removeDataForDownloadURL:(NSString *)downloadURL {
    TPLog(@"Removing local file and metadata for resource %@", downloadURL);
    NSString *filePath = [self getLocalVideoPathForURL:downloadURL];
    if (filePath != nil && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *deleteError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&deleteError];
        if (deleteError != nil) {
            TPLog(@"Error deleting local video %@ for resource %@. Error code: %ld. Error Description: %@", filePath, downloadURL, (long)deleteError.code, deleteError.description);
            return;
        }
    }
    // Either the file didn't exist to begin with or we've successfully deleted it.
    [self removeAllMetaDataForURL:downloadURL];
}

// Scan for expired videos.
- (void)removeAllExpiredVideoData {
    NSDate *now = [NSDate date];
    NSString *downloadURL;
    NSDate *expirationDate;
    for (downloadURL in [_tpVideoMetaData allKeys]) {
        expirationDate = [self getMetaDataWithKey:@"expirationTime" forURL:downloadURL];
        if ([now compare:expirationDate] == NSOrderedDescending) { // The current time is past the expiration time
            TPLog(@"Removing expired video data for resource %@", downloadURL);
            [self removeDataForDownloadURL:downloadURL];
        }
    }
}

// Check that the total number of stored videos does not exceed the given limit.
// If we have too many videos, delete the oldest videos (with the nearest expiration dates).
- (void)removeExcessVideosBeyondCount:(int)videoLimit {
    NSUInteger existingResourceCount = [[_tpVideoMetaData allKeys] count];
    if (existingResourceCount > videoLimit) {
        // Sort the resources from oldest to newest (i.e. from nearest to farthest expiration times).
        NSArray *sortedURLs = [_tpVideoMetaData keysSortedByValueUsingComparator:^(id resource1, id resource2) {
            NSDate *resource1expirationDate = [resource1 objectForKey:@"expirationTime"];
            NSDate *resource2expirationDate = [resource2 objectForKey:@"expirationTime"];
            return [resource1expirationDate compare:resource2expirationDate];
        }];
        // Remove resources until we're within our limit.
        NSString *resourceToRemove;
        int resourcesRemovedCount = 0;
        while ((existingResourceCount - resourcesRemovedCount) > videoLimit) {
            resourceToRemove = [sortedURLs objectAtIndex:resourcesRemovedCount];
            [self removeDataForDownloadURL:resourceToRemove];
            resourcesRemovedCount++;
        }
    }
}

- (void)pruneVideoStorage {
    [self removeAllExpiredVideoData];
    [self removeExcessVideosBeyondCount:10];
}

#pragma mark - Downloading Video

// A simple wrapper to reset hasRetriedRequest
- (void)loadVideo:(NSString *)downloadURL {
    [self removeMetaDataWithKey:@"hasRetriedRequest" forURL:downloadURL];
    [self downloadVideoFromURL:downloadURL];
}

// Download the video file to local storage
- (void)downloadVideoFromURL:(NSString *)downloadURL {

    if ([self getMetaDataWithKey:@"isCompleteVideoStored" forURL:downloadURL]) {
        TPLog(@"Resource %@ is already downloaded to device. Download attempt cancelled.", downloadURL);
        return;
    }
    NSString *localFilePath = [self getLocalVideoPathForURL:downloadURL];
    if (localFilePath == nil) {
        TPLog(@"Cannot determine local video file path. Download attempt cancelled.");
        return;
    }

    // Ensure that we don't create duplicate requests if the developer checks availability very frequently.
    // This isn't a perfect lock but that's fine in this case.
    if ([self getMetaDataWithKey:@"isDownloadInProgress" forURL:downloadURL]) {
        TPLog(@"Resource %@ is currently being downloaded to device. Download attempt cancelled.", downloadURL);
        return;
    }
    [self setMetaData:@1 withKey:@"isDownloadInProgress" forURL:downloadURL];

    // Assemble the request, adding a Range header if we've already downloaded a portion of the file.
    // Ignore local cache data for this request. We do this for 2 reasons:
    //  1 - Sometimes the local cache will cache a partial content response, which we get when we've
    //      already downloaded part of the file and are only requesting the remainder (using range
    //      headers, below). But the local cache will return this cached response even when we're
    //      requesting - and need - the entire file.
    //  2 - If we make a request which ignores the cache, the cache system won't cache the response
    //      to this request. This prevents us from filling the cache system with large responses we
    //      won't use. (These video files can be several MBs.)
    NSMutableURLRequest *videoURLRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:downloadURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60]; // Use default timeout for now.
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
        NSError *fileAccessError = nil;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:localFilePath error:&fileAccessError];
        if (fileAccessError == nil) {
            unsigned long long fileSize = [fileAttributes fileSize]; // fileSize is a convenience method on NSDictionary
            NSString *rangeHeader = [NSString stringWithFormat:@"bytes=%llu-", fileSize];
            [videoURLRequest setValue:rangeHeader forHTTPHeaderField:@"Range"];
        }
    }

    // Construct the delegate and initiate the asynchronous request
    TpVideoConnectionDelegate *videoConnectionDelegate = [[[TpVideoConnectionDelegate alloc] init] TP_AUTORELEASE];
    [NSURLConnection connectionWithRequest:videoURLRequest delegate:videoConnectionDelegate];
}

- (void)reattemptDownload:(NSString *)downloadURL {
    if ([self getMetaDataWithKey:@"hasRetriedRequest" forURL:downloadURL]) return;

    // Reattempt the download. Confirm that we've set the flag before reattempting, or we could retry forever.
    if ([self setMetaData:@1 withKey:@"hasRetriedRequest" forURL:downloadURL]) {
        TPLog(@"Download will be reattempted in 15 seconds.");
        [self performSelector:@selector(downloadVideoFromURL:) withObject:downloadURL afterDelay:15];
    }
}

- (void)markDownloadCompleteForURL:(NSString *)downloadURL withSuccess:(BOOL)isSuccess withReattempt:(BOOL)isReattempt {
    [self removeMetaDataWithKey:@"isDownloadInProgress" forURL:downloadURL];
    if (isSuccess) {
        [self setMetaData:@1 withKey:@"isCompleteVideoStored" forURL:downloadURL];
    } else {
        // In a few cases we'll mark the video as downloaded at the beginning of the download (because we're unable to determine
        // when the download is finished). We've determined there's a problem with the download so we want to remove that flag.
        [self removeMetaDataWithKey:@"isCompleteVideoStored" forURL:downloadURL];
    }
    if (isReattempt) {
        [self reattemptDownload:downloadURL];
    }
}

#pragma mark - Misc

- (NSString *)getLocalVideoPathForURL:(NSString *)downloadURL {
    if (_tpVideoFileDirectory == nil) {
        TPLog(@"getLocalVideoPathForOffer - video directory not available, unable to determine full path to file");
        return nil;
    }
    NSString *videoFileName = [downloadURL lastPathComponent];
    NSString *videoPath = [_tpVideoFileDirectory stringByAppendingPathComponent:videoFileName];
    return videoPath;
}

// Returns an array of encoded offer ids for all video trailer offers that have preloaded completely.
- (NSArray *)getAllStoredVideoOffers {
    NSMutableArray *storedVideoOffers = [[[NSMutableArray alloc] init] TP_AUTORELEASE];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        // Right now there's a strange crash that can happen when loading video trailers from the OW in iOS 6.
        // Until we track down and fix the cause, indicate to touchpoints that no videos have been loaded.
        // (We also don't preload videos for OW touchpoints, but we have this check as well in case the app also
        // has an interstitial touchpoint which loaded some video trailers.)
        return storedVideoOffers;
    }
    for (NSString *downloadURL in [_tpVideoMetaData allKeys]) {
        // Grab the oid if the video is completely stored on the device.
        // The only time the oid will not be present is if the user has just updated from an
        // old SDK version that did not store it. (We call this function before getting new offers -
        // after that the oid will be stored.)
        if ([self getMetaDataWithKey:@"isCompleteVideoStored" forURL:downloadURL] &&
            [self getMetaDataWithKey:@"oid" forURL:downloadURL]) {
            [storedVideoOffers addObject:[self getMetaDataWithKey:@"oid" forURL:downloadURL]];
        }
    }
    return storedVideoOffers;
}

#pragma mark - Pixels (clicks, completion, impression)

// extraBlock is optional (use nil if no block is needed). If provided, this block will fire when the pixel completes.
- (void)firePixel:(NSString *)pixelName forURL:(NSString *)downloadURL withBlock:(void (^)(NSURLResponse *, NSData *, NSError *))extraBlock {
    NSURL *URL = [NSURL URLWithString:[self getMetaDataWithKey:pixelName forURL:downloadURL]];
    NSURLRequest *pixelRequest = [NSURLRequest requestWithURL:URL];
    void (^completionBlock)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpResponse statusCode];
        NSString *statusDescription = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
        if (error != nil) {
            TPLog(@"Pixel to %@ encountered an error. Error code: %ld. Description: %@", URL, (long)error.code, error.localizedDescription);
        } else if ((statusCode < 200) || (statusCode >= 400)) {
            // Try to decode the response to look for an error message.
            NSString *errorMessage = @"";
            NSError *decodeError = nil;
            NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            if (!decodeError && [responseJSON objectForKey:@"error"]) {
                errorMessage = [responseJSON objectForKey:@"error"];
            }
            TPLog(@"Pixel to %@ responded with invalid status: %ld - %@. Error message: %@", URL, (long)statusCode, statusDescription, errorMessage);
        } else {
            TPLog(@"Pixel to %@ completed without error.", URL);
        }
        // Fire extraBlock, if provided
        if (extraBlock != nil) extraBlock(response, data, error);
    };
    [NSURLConnection sendAsynchronousRequest:pixelRequest queue:_tpVideoOperationQueue completionHandler:completionBlock];
}

- (void)fireImpressionForURL:(NSString *)downloadURL {
    [self firePixel:@"impressionURL" forURL:downloadURL withBlock:nil];
}

- (void)fireClickForURL:(NSString *)downloadURL {
    [self firePixel:@"clickURL" forURL:downloadURL withBlock:nil];
}

- (void)fireCompletionIfNotFiredForURL:(NSString *)downloadURL {
    if (![self getMetaDataWithKey:@"hasFiredCompletion" forURL:downloadURL]) {
        [self setMetaData:@1 withKey:@"hasFiredCompletion" forURL:downloadURL];
        [self firePixel:@"completionURL" forURL:downloadURL withBlock:nil];
    }
}

- (void)createEndcapClickForURL:(NSString *)downloadURL {
    void (^clickGenerationBlock)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            // decode the response
            NSError *decodeError = nil;
            NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
            if (decodeError != nil) {
                TPLog(@"Error decoding click API data from URL %@ for resource %@. Error code: %ld. Error Description: %@", response.URL, downloadURL, (long)decodeError.code, decodeError.description);
            } else {
                NSString *endcapClickID = [responseJSON objectForKey:@"subid"];
                if (endcapClickID != nil) {
                    TPLog(@"Received endcap click id: %@", endcapClickID);
                    [self setMetaData:endcapClickID withKey:@"endcapClickID" forURL:downloadURL];
                    // Attempt to set the click id on the endcap, in case the endcap has already been opened.
                    [self performSelectorOnMainThread:@selector(provideEndcapWithClickID:) withObject:endcapClickID waitUntilDone:NO];
                }
            }
        }
    };
    [self firePixel:@"endcapClickURL" forURL:downloadURL withBlock:clickGenerationBlock];
}

#pragma mark - Status Bar
// In iOS 7.0 and up we use the method prefersStatusBarHidden: on each of the view controllers.
// On earlier OSes we rely on the following functions to hide and restore the status bar.

// Ensure the status bar is hidden
- (void)hideStatusBar {
    if (![UIApplication sharedApplication].statusBarHidden) {
        [UIApplication sharedApplication].statusBarHidden = YES;
        _didHideStatusBar = YES;
    } else {
        _didHideStatusBar = NO;
    }
}

// Show the status bar if we hid it previously
- (void)revertStatusBar {
    if (_didHideStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
}

#pragma mark - Core Operations

// Initialize and download a video
// Required parameters:
//  - NSString *dl_url - the URL of the raw video file
//  - NSString *toi_url - pixel URL for logging impression
//  - NSString *ck_url - pixel URL for creating user, session and click
//  - NSString *cn_url - pixel URL for logging completion
//  - NSNumber *ec_slcb - 1 or 0, whether to show a native close button while the endcap webview is loading, if the user reaches the endcap before it's loaded
//  - NSNumber *ec_to - timeout to use for the request to the endcap webview, in seconds. used only when loading that endcap, not for request made from that page.
//  - NSString *ec_url - URL for interstitial endcap webview
//  - NSString *ec_ck_url - pixel URL for creating the click for the endcap/installation offer
//  - NSString *app_id - app ID, used when opening the in-app app store
//  - NSNumber *completion_time - number of seconds until we fire the completion. Negative values are calculated from the end of the video. (e.g. -3 means 3 seconds from the end)
//  - NSNumber *exit_delay - number of seconds until we show the exit button. A value of -1 means the button is never shown.
//  - NSNumber *use_cd - 1 or 0, whether to display the countdown text
//  - NSString *tc - color for countdown text and exit button. Must correspond to a UIColor color name without the 'Color' suffix. (e.g. 'black', 'lightGray')
//  - NSNumber *exp - the time at which to remove local video data, given in seconds from now
//  - NSString *oid - the encoded offer id
//
// Optional parameters:
//  - NSString *cd_text - The countdown text to display, with %time% used as placeholder for the numeric countdown. e.g. "Video ends in %time% seconds".
- (void)initializeVideoWithParams:(NSDictionary *)params {
    // A mapping from incoming API parameters and the required SDK parameters to which they map.
    NSDictionary *requiredParamNames = @{@"dl_url" :          @"downloadURL",
                                         @"toi_url" :         @"impressionURL",
                                         @"ck_url" :          @"clickURL",
                                         @"cn_url" :          @"completionURL",
                                         @"ec_slcb" :         @"isShowEndcapLoadingCloseButton",
                                         @"ec_to" :           @"endcapTimeoutSeconds",
                                         @"ec_url" :          @"endcapURL",
                                         @"ec_ck_url" :       @"endcapClickURL",
                                         @"app_id" :          @"appID",
                                         @"completion_time" : @"completionTime",
                                         @"exit_delay" :      @"exitButtonDelay",
                                         @"use_cd" :          @"isShowCountdown",
                                         @"tc" :              @"textColor",
                                         @"exp" :             @"expirationTime",
                                         @"oid" :             @"oid"};
    // Check presence of required params
    for (NSString *incomingParamName in [requiredParamNames allKeys]) {
        if ([params objectForKey:incomingParamName] == nil) {
            TPLog(@"Video trailer initialization aborted - missing parameter %@", incomingParamName);
            return;
        }
    }

    NSString *downloadURL = [params objectForKey:@"dl_url"];

    // Store required attributes.
    for (NSString *incomingParamName in [requiredParamNames allKeys]) {
        NSString *SDKParamName = [requiredParamNames objectForKey:incomingParamName];
        id paramValue = [params objectForKey:incomingParamName];
        // Special parameter handling
        if ([SDKParamName isEqualToString:@"textColor"]) {
            // Convert the text color string to the UIColor name
            paramValue = [NSString stringWithFormat:@"%@Color", paramValue];
        } else if ([SDKParamName isEqualToString:@"expirationTime"]) {
            // Convert the expiration time from a time interval to a date
            paramValue = [NSDate dateWithTimeIntervalSinceNow:[paramValue intValue]];
        } else if ([SDKParamName isEqualToString:@"downloadURL"]) {
            // The downloadURL is the key on which we store the video data. We don't also need it as a stored value.
            continue;
        }
        [self setMetaData:paramValue withKey:SDKParamName forURL:downloadURL];
    }
    // Store optional attributes.
    NSString *countdownText = [params objectForKey:@"cd_text"] ? [params objectForKey:@"cd_text"] : @"";
    [self setMetaData:countdownText withKey:@"countdownText" forURL:downloadURL];

    // Clear the hasFiredCompletion flag
    [self removeMetaDataWithKey:@"hasFiredCompletion" forURL:downloadURL];
    // Download the video to local storage. The request must be made from the main thread.
    [self performSelectorOnMainThread:@selector(loadVideo:) withObject:downloadURL waitUntilDone:NO];
}

- (BOOL)isResourceReady:(NSString *)downloadURL {
    [self pruneVideoStorage];
    // If we've already fired a completion then we need to check the availability API before allowing the
    // video to be shown again. We'll clear the hasFiredCompletion flag when we recheck availability.
    if ([self getMetaDataWithKey:@"isCompleteVideoStored" forURL:downloadURL] && ![self getMetaDataWithKey:@"hasFiredCompletion" forURL:downloadURL]) {
        return YES;
    }
    return NO;
}

// Enter the video trailer flow, starting with the display of the video trailer.
// The flow will be presented modally from baseViewController.
// completionBlock will be executed when we close the video trailer flow (i.e. from inside closeTrailer). This can be nil.
- (void)playVideoWithURL:(NSString *)downloadURL fromViewController:(UIViewController *)baseViewController withBlock:(void (^)(void))completionBlock {
    // Gather necessary information.
    if (![self getMetaDataWithKey:@"isCompleteVideoStored" forURL:downloadURL]) {
        TPLog(@"Video resource %@ is not stored locally. Aborting video playback.", downloadURL);
        return;
    }
    NSString *filePath = [self getLocalVideoPathForURL:downloadURL];
    if (filePath == nil) {
        TPLog(@"Cannot determine local video file path for resource %@. Aborting video playback.", downloadURL);
        return;
    }
    // Check if we already have the video up, this prevents a "double-click" making 2 video objects to run, resulting in frozen UI. (iOS6/iphone4)
    if (_isVideoBeingShown) {
        return;
    }
    _isVideoBeingShown = YES;

    // Store the completionBlock
    [_closeTrailerBlock TP_RELEASE]; // Release the existing block, if present.
    _closeTrailerBlock = completionBlock;
    [_closeTrailerBlock TP_RETAIN];

    // Load the interstitial endcap and app store view controllers in the background.
    [self createEndcap:downloadURL];
    [self createAppStoreController:[self getMetaDataWithKey:@"appID" forURL:downloadURL]];

    // Present the video.
    NSDictionary *viewControllerParams = [NSDictionary dictionaryWithObjectsAndKeys:
        downloadURL,                                                     @"downloadURL",
        [self getMetaDataWithKey:@"isShowCountdown" forURL:downloadURL], @"isShowCountdown",
        [self getMetaDataWithKey:@"textColor" forURL:downloadURL],       @"textColor",
        [self getMetaDataWithKey:@"completionTime" forURL:downloadURL],  @"completionTime",
        [self getMetaDataWithKey:@"exitButtonDelay" forURL:downloadURL], @"exitButtonDelay",
        [self getMetaDataWithKey:@"countdownText" forURL:downloadURL],   @"countdownText",
        nil];
    [_videoViewController TP_RELEASE]; // Release any existing controller.
    _videoViewController = [[TpVideoViewController alloc] initWithContentURL:[NSURL fileURLWithPath:filePath] andParams:viewControllerParams];
    _videoViewController.moviePlayer.controlStyle = MPMovieControlStyleNone;
    [_videoViewController.moviePlayer prepareToPlay];

    [baseViewController presentViewController:_videoViewController animated:YES completion:nil];
    [_videoViewController.moviePlayer play];
}

// Close the entire video trailer flow
- (void)closeTrailer {
    // Grab the view controller at the root of our view hierachy. This should be the view from which the user entered the interstitial flow.
    UIViewController *baseViewController = _videoViewController.presentingViewController;
    if (baseViewController == nil) {
        baseViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    // Dismiss the video view controller. All the CPI view controllers are presented from the video view controller, so
    // dismissing it will also dismiss the endcap and app store controllers, if present.
    [self revertStatusBar];

    [baseViewController dismissViewControllerAnimated:YES completion:^{
        _isWebViewOpened = NO;
        _isStoreViewOpened = NO;
        _isVideoBeingShown = NO;

        // Fire the closeTrailerBlock, if present
        if (_closeTrailerBlock != nil) {
            _closeTrailerBlock();
        }
    }];
}

#pragma mark - Interstitial Webview Endcap

// Create and load the endcap webview in the background
- (void)createEndcap:(NSString *)downloadURL {
    NSString *endcapURL = [self getMetaDataWithKey:@"endcapURL" forURL:downloadURL];
    if (endcapURL != nil) {
        // Create the click for the endcap offer. Do this now because the click id must be returned by the time the user opens the appstore from within the endcap.
        [self removeMetaDataWithKey:@"endcapClickID" forURL:downloadURL]; // Remove the old endcap click id, if present.
        [self createEndcapClickForURL:downloadURL];

        // Assume the webview loads correctly. If it fails to load then we'll set this flag to NO.
        _isWebViewLoaded = YES;

        // Load the new endcap in the background.
        [_endcapWebView TP_RELEASE]; // Release the existing webview, if present.
        UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        _endcapWebView = [[UIWebView alloc] initWithFrame:rootView.bounds];
        _endcapWebView.delegate = self;
        // Use the default cache policy and a configurable timeout interval.
        NSTimeInterval endcapTimeoutSeconds = [[self getMetaDataWithKey:@"endcapTimeoutSeconds" forURL:downloadURL] doubleValue];
        [_endcapWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:endcapURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:endcapTimeoutSeconds]];

        // Create the endcap view controller.
        [_endcapViewController TP_RELEASE]; // Release the existing controller, if present.
        _endcapViewController = [[TpVideoEndcapViewController alloc] init];
        // If the user clicks through to the endcap before it's finished loading, they may be stuck there until the webview
        // loads or times out (usually it will load very soon). Determine whether to display a native close button during
        // this time. The button will be hidden once loading completes.
        BOOL isShowEndcapLoadingCloseButton = [[self getMetaDataWithKey:@"isShowEndcapLoadingCloseButton" forURL:downloadURL] boolValue];
        _endcapViewController.shouldShowExitButton = isShowEndcapLoadingCloseButton;
        // Add the webview to the view controller.
        [_endcapViewController.view addSubview:_endcapWebView];
    } else {
        TPLog(@"Could not create video endcap for resource %@ - missing endcap URL", downloadURL);
        _isWebViewLoaded = NO;
    }
}

// Send the endcap click id to the endcap, overwriting a click id previously stored there. It is safe to call this function
// multiple times. The endcap will not use the click id until and unless the user chooses to open the app store.
// Params:
//  - NSString *endcapClickID - the click id for the endcap offer. This may be nil.
- (void)provideEndcapWithClickID:(NSString *)endcapClickID {
    if (_endcapWebView != nil) {
        if (endcapClickID == nil) endcapClickID = @"";
        TPLog(@"Providing click id '%@' to endcap", endcapClickID);
        [_endcapWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"storeEndcapSID('%@');", endcapClickID]];
    }
}

// Display the previously-loaded endcap. This is an interstitial webview element allowing the user to continue through to the in-app app store.
- (void)openEndcap:(NSString *)downloadURL {
    if (_isWebViewLoaded) {
        TPLog(@"Displaying interstitial webview endcap with URL %@", [self getMetaDataWithKey:@"endcapURL" forURL:downloadURL]);
        _isWebViewOpened = YES;
        [_videoViewController presentViewController:_endcapViewController animated:YES completion:nil];
        // Ensure the webview is sized to the view controller.
        _endcapWebView.frame = _endcapViewController.view.bounds;

        // Pass the click ID to the endcap. We may not have this yet, but will call this again when the click API completes.
        [self provideEndcapWithClickID:[self getMetaDataWithKey:@"endcapClickID" forURL:downloadURL]];
    } else {
        [self closeTrailer];
    }
}

// Delegate methods for the endcap webview

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.host isEqualToString:@"showAppStore"]) {
        [self openAppStore];
        return NO;
    }
    if ([request.URL.host isEqualToString:@"closeEndcap"]) {
        [self closeTrailer];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    TPLog(@"Failed to load interstitial webview -- Error code: %ld. Error description: %@", (long)error.code, error.localizedDescription);
    // Mark the webview as unloaded so that we abort any future requests to open it. If we've already opened the webview, abort now.
    _isWebViewLoaded = NO;
    if (_isWebViewOpened) [self closeTrailer];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [_endcapViewController hideNativeExitButton];
}

#pragma mark - In-App App Store

// Create and load the app store view controller in the background
- (void)createAppStoreController:(NSString *)appID {
    if (appID == nil) {
        TPLog(@"Cannot create app store controller - missing app id");
        _isStoreViewLoaded = NO;
        return;
    }

    // Assume the store loads correctly. If it fails to load then we'll set this flag to NO.
    _isStoreViewLoaded = YES;

    // Remove the existing controller, if present.
    [_storeViewController TP_RELEASE];

    _storeViewController = [[TpAppStoreViewController alloc] init];
    [_storeViewController setDelegate:self];
    [_storeViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier : appID} completionBlock:^(BOOL result, NSError *error) {
        if (error) {
            TPLog(@"Failed to load app store for application %@ -- Error code: %ld. Error description: %@", appID, (long)error.code, error.localizedDescription);
            // Mark the store as unloaded so that we abort any future requests to open it. If we've already opened the store, abort now.
            _isStoreViewLoaded = NO;
            if (_isStoreViewOpened) [self closeTrailer];
        }
    }];
}

// Display the previously-loaded in-app app store.
- (void)openAppStore {
    if (_isStoreViewLoaded) {
        _isStoreViewOpened = YES;
        [_endcapViewController presentViewController:_storeViewController animated:YES completion:nil];
    } else {
        [self closeTrailer];
    }
}

// Delegate method for app store view.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self closeTrailer];
}

@end
