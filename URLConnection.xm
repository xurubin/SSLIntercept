#import <Foundation/Foundation.h>

void printDict(NSDictionary* dict) {
    for(NSString* key in [dict allKeys]) 
        NSLog(@"    %@: %@", key, [dict objectForKey:key]);
}

__attribute__((visibility("hidden")))
@interface URLConnectionLogDelegate : NSObject {
@private
	id realDelegate;
}
@end

@implementation URLConnectionLogDelegate

- (id)initWithRealDelegate:(id)_realDelegate
{
	if ((self = [super init])) {
		realDelegate = [_realDelegate retain];
	}
	return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    NSString* selName = NSStringFromSelector(aSelector);
    
    //NSLog(@"respondsToSelector called for '%@'", selName);
    
    // Should reflect whether the real delegate responds to these selectors or not.
    if ([selName isEqualToString: @"connection:willSendRequestForAuthenticationChallenge:"] ||
        [selName isEqualToString: @"connection:canAuthenticateAgainstProtectionSpace:"] ||
        [selName isEqualToString: @"connection:didReceiveAuthenticationChallenge:"]) {
        return [realDelegate respondsToSelector:aSelector];
    }

    return ([[self class] instancesRespondToSelector:aSelector]);
}

- (void)dealloc
{
	//NSLog(@"-[NSURLConnectionDelegate dealloc]");
	[realDelegate release];
	[super dealloc];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    //NSLog(@"-[NSURLConnectionDelegate canAuthenticateAgainstProtectionSpace]");
	if ([realDelegate respondsToSelector:_cmd])
		return [realDelegate connection:connection canAuthenticateAgainstProtectionSpace:protectionSpace];
    else 
        NSLog(@"[canAuthenticateAgainstProtectionSpace] Should not happen!");
	return YES;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	//NSLog(@"-[NSURLConnectionDelegate didCancelAuthenticationChallenge]");
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connection:connection didCancelAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	//NSLog(@"-[NSURLConnectionDelegate didReceiveAuthenticationChallenge]");
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connection:connection didReceiveAuthenticationChallenge:challenge];
    else
        NSLog(@"[didReceiveAuthenticationChallenge] Should not happen!");
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	//NSLog(@"-[NSURLConnectionDelegate willSendRequestForAuthenticationChallenge]");
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connection:connection willSendRequestForAuthenticationChallenge:challenge];
    else
        NSLog(@"[willSendRequestForAuthenticationChallenge] Should not happen!");
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
	//NSLog(@"-[NSURLConnectionDelegate connectionShouldUseCredentialStorage]");
	if ([realDelegate respondsToSelector:_cmd])
		return [realDelegate connectionShouldUseCredentialStorage:connection];
	return YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	//NSLog(@"-[NSURLConnectionDelegate didFailWithError]");
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connection:connection didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	//NSLog(@"-[NSURLConnectionDelegate connectionDidFinishLoading]");
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connectionDidFinishLoading:connection];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	//NSLog(@"-[NSURLConnectionDelegate didSendBodyData]");
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connection:connection didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSLog(@"-[NSURLConnectionDelegate didReceiveData: %@]", data);
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connection:connection didReceiveData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"-[NSURLConnectionDelegate didReceiveResponse:%@]", [response URL]);
    if ([response respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary* headers = [(NSHTTPURLResponse *)response allHeaderFields];
        printDict(headers);
    } 
    
	if ([realDelegate respondsToSelector:_cmd])
		[realDelegate connection:connection didReceiveResponse:response];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	//NSLog(@"-[NSURLConnectionDelegate willCacheResponse]");
	if ([realDelegate respondsToSelector:_cmd])
		return [realDelegate connection:connection willCacheResponse:cachedResponse];
	return cachedResponse;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	//NSLog(@"-[NSURLConnectionDelegate willSendRequest]");
	if ([realDelegate respondsToSelector:_cmd])
		return [realDelegate connection:connection willSendRequest:request redirectResponse:redirectResponse];
	return request;
}

@end

%hook NSURLConnection

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
	NSLog(@"+[NSURLConnection sendSynchronousRequest:%@ returningResponse:%p error:%p]", [request URL], response, error);
    printDict([request allHTTPHeaderFields]);
    NSLog(@"%@", [request HTTPBody]);
	return %orig;
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
	NSLog(@"-[NSURLConnection initWithRequest:%@ delegate:%@ startImmediately:%d]", [request URL], delegate, startImmediately);
    printDict([request allHTTPHeaderFields]);
    NSLog(@"%@", [request HTTPBody]);
    
	id newDelegate = [[[URLConnectionLogDelegate alloc] initWithRealDelegate:delegate] autorelease];
	return %orig(request, newDelegate, startImmediately);
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	NSLog(@"-[NSURLConnection initWithRequest:%@ delegate:%@]", [request URL], delegate);
    printDict([request allHTTPHeaderFields]);
    NSLog(@"%@", [request HTTPBody]);

	id newDelegate = [[[URLConnectionLogDelegate alloc] initWithRealDelegate:delegate] autorelease];
	return %orig(request, newDelegate);
}

%end
