//#import "ASIHTTPRequest.h"
@interface ASIHTTPRequest : NSOperation <NSCopying> 

	// The url for this operation, should include GET params in the query string where appropriate
-	(NSURL *) url; 

	// Will always contain the original url used for making the request (the value of url can change when a request is redirected)
	NSURL *originalURL;

	// Temporarily stores the url we are about to redirect to. Will be nil again when we do redirect
	NSURL *redirectURL;

	// HTTP method to use (eg: GET / POST / PUT / DELETE / HEAD etc). Defaults to GET
-	(NSString *) requestMethod;

	// Request body - only used when the whole body is stored in memory (shouldStreamPostDataFromDisk is false)
-    (NSMutableData *) postBody;

-   (void)buildPostBody;

	// If an error occurs, error will contain an NSError
	// If error code is = ASIConnectionFailureErrorType (1, Connection failure occurred) - inspect [[error userInfo] objectForKey:NSUnderlyingErrorKey] for more information
-	(NSError *) error;

// Response data, automatically uncompressed where appropriate
- (NSData *)responseData;

// Called when a request completes successfully, lets the delegate know via didFinishSelector
- (void)requestFinished;
@end

static void logRequest(ASIHTTPRequest* self, NSString* name) {
    NSLog(@"[ASIHTTPRequest %@]", name);
    NSLog(@"URL: %@ %@", [self requestMethod], [self url]);
    if ([[self requestMethod] isEqualToString:@"POST"]) {
        [self buildPostBody];
        NSString *strData = [[NSString alloc]initWithData:[self postBody] encoding:NSUTF8StringEncoding];
        NSLog(@"postBody: %@", strData);
    }
}

static void logResponse(ASIHTTPRequest* self) {
    NSURL* url = [self url];
    NSError * error = [self error];
    NSData * response = [self responseData];
    NSString *strResponse = [[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding];
    NSLog(@"Response for %@ (err: %@): %@", url, error, strResponse);
}

%hook ASIHTTPRequest

- (void)startSynchronous 
{
    logRequest(self, @"startSynchronous");
    %orig;
}

// Run request in the background
- (void)startAsynchronous
{
    logRequest(self, @"startAsynchronous");
    %orig;
}

// Called when a request completes successfully, lets the delegate know via didFinishSelector
- (void)requestFinished 
{
    logResponse(self);
    %orig;
}
%end