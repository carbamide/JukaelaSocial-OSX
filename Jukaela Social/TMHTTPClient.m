//
//  TMHTTPClient.m
//  ZummZumm
//
//  Created by Tony Million on 26/05/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import "TMHTTPClient.h"
#import "TMHTTPRequest.h"

static NSString * encodeURL(NSString *string, NSStringEncoding encoding)
{
    NSString *newString = ( NSString *)
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            ( CFStringRef)string,
                                            NULL,
                                            CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                            CFStringConvertNSStringEncodingToEncoding(encoding));
    if (newString)
    {
        return newString;
    }

    return @"";
}


//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

static NSString * const kAFMultipartFormBoundary = @"Boundary+0xAbCdEfGbOuNdArY";

@interface TMMultipartFormData : NSObject <TMMultipartFormData> {
@private
    NSStringEncoding _stringEncoding;
    NSMutableData *_mutableData;
}

@property (readonly) NSData *data;

- (id)initWithStringEncoding:(NSStringEncoding)encoding;

@end


//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

#pragma mark -

@interface AFQueryStringComponent : NSObject {
@private
    NSString *_key;
    NSString *_value;
}

@property (readwrite, nonatomic, retain) id key;
@property (readwrite, nonatomic, retain) id value;

- (id)initWithKey:(id)key value:(id)value;
- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;

@end

@implementation AFQueryStringComponent
@synthesize key = _key;
@synthesize value = _value;

- (id)initWithKey:(id)key value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.key = key;
    self.value = value;

    return self;
}


- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    return [NSString stringWithFormat:@"%@=%@", self.key, encodeURL([self.value description], stringEncoding)];
}

@end


extern NSArray * AFQueryStringComponentsFromKeyAndValue(NSString *key, id value);
extern NSArray * AFQueryStringComponentsFromKeyAndDictionaryValue(NSString *key, NSDictionary *value);
extern NSArray * AFQueryStringComponentsFromKeyAndArrayValue(NSString *key, NSArray *value);
extern NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding);

NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutableComponents = [NSMutableArray array];
    for (AFQueryStringComponent *component in AFQueryStringComponentsFromKeyAndValue(nil, parameters)) {
        [mutableComponents addObject:[component URLEncodedStringValueWithEncoding:stringEncoding]];
    }

    return [mutableComponents componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringComponentsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    if([value isKindOfClass:[NSDictionary class]]) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndDictionaryValue(key, value)];
    } else if([value isKindOfClass:[NSArray class]]) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndArrayValue(key, value)];
    } else {
        [mutableQueryStringComponents addObject:[[AFQueryStringComponent alloc] initWithKey:key value:value]];
    }

    return mutableQueryStringComponents;
}

NSArray * AFQueryStringComponentsFromKeyAndDictionaryValue(NSString *key, NSDictionary *value){
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    [value enumerateKeysAndObjectsUsingBlock:^(id nestedKey, id nestedValue, BOOL *stop) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
    }];

    return mutableQueryStringComponents;
}

NSArray * AFQueryStringComponentsFromKeyAndArrayValue(NSString *key, NSArray *value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    [value enumerateObjectsUsingBlock:^(id nestedValue, NSUInteger idx, BOOL *stop) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
    }];

    return mutableQueryStringComponents;
}


//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

static NSString * TMURLStringFromParameters(NSDictionary *parameters, NSStringEncoding encoding)
{
    NSMutableString * paramString = [NSMutableString stringWithString:@""];
    for(NSString *key in parameters)
    {
        //TODO: encode this shit eh?
        id temp = [parameters objectForKey:key];
        NSString * strParam = [NSString stringWithFormat:@"%@", temp];

        [paramString appendFormat:@"%@=%@&", key, encodeURL(strParam, encoding)];
    }

    return paramString;
}

static NSString * TMJSONStringFromParameters(NSDictionary *parameters)
{
    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:0
                                                         error:&error];

    if (!error) {
        return [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}


@interface TMHTTPClient ()

@property(nonatomic, strong) NSURL *baseURL;
@property(nonatomic, strong) NSMutableDictionary *defaultHeaders;
@property(strong) NSOperationQueue		*operationQueue;

@end

@implementation TMHTTPClient

@synthesize baseURL             = _baseURL;
@synthesize stringEncoding      = _stringEncoding;
@synthesize parameterEncoding   = _parameterEncoding;
@synthesize defaultHeaders      = _defaultHeaders;

+ (TMHTTPClient *)clientWithBaseURL:(NSURL *)url {
    return [[self alloc] initWithBaseURL:url];
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.baseURL = url;

    self.stringEncoding     = NSUTF8StringEncoding;
    self.parameterEncoding  = TMFormURLParameterEncoding;
	self.defaultHeaders     = [NSMutableDictionary dictionary];

	// Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
	[self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];

	// Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
	NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
	[self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];

    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    [self setDefaultHeader:@"User-Agent"
					 value:[NSString stringWithFormat:@"%@/%@",
							[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey],
							[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]]];

	self.operationQueue = [[NSOperationQueue alloc] init];

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, baseURL: %@, defaultHeaders: %@>", NSStringFromClass([self class]), self, [self.baseURL absoluteString], self.defaultHeaders];
}

#pragma mark -

- (NSString *)defaultValueForHeader:(NSString *)header {
	return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	if(value)
	{
		[self.defaultHeaders setValue:value
							   forKey:header];
	}
	else
	{
		[self.defaultHeaders removeObjectForKey:header];
	}
}

#pragma mark -

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.defaultHeaders];

    if (parameters)
    {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"])
        {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", TMURLStringFromParameters(parameters, self.stringEncoding)]];
            [request setURL:url];
        }
        else
        {
            NSString *charset = ( NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
            switch (self.parameterEncoding) {
                case TMFormURLParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
                   forHTTPHeaderField:@"Content-Type"];

                    [request setHTTPBody:[TMURLStringFromParameters(parameters, self.stringEncoding) dataUsingEncoding:self.stringEncoding]];
                    break;
                case TMJSONParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset]
                   forHTTPHeaderField:@"Content-Type"];

                    [request setHTTPBody:[TMJSONStringFromParameters(parameters) dataUsingEncoding:self.stringEncoding]];
                    break;
            }
        }
    }

	return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <TMMultipartFormData>formData))block
{

    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:nil];
    __block TMMultipartFormData *formData = [[TMMultipartFormData alloc] initWithStringEncoding:self.stringEncoding];

    for(AFQueryStringComponent *component in AFQueryStringComponentsFromKeyAndValue(nil, parameters))
    {
        NSData *data = nil;
        if ([component.value isKindOfClass:[NSData class]])
        {
            data = component.value;
        }
        else
        {
            data = [[component.value description] dataUsingEncoding:self.stringEncoding];
        }

        [formData appendPartWithFormData:data name:[component.key description]];
    }

    if (block)
    {
        block(formData);
    }

    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kAFMultipartFormBoundary]
   forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody:[formData data]];

    return request;
}

- (TMHTTPRequest *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
										   success:(void (^)(TMHTTPRequest *operation, id responseObject))success
										   failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure
{
    TMHTTPRequest *operation = nil;

    operation = [[TMHTTPRequest alloc] initWithRequest:urlRequest];

    operation.successBlock = success;
    operation.failureBlock = failure;

    return operation;
}

#pragma mark -

- (void)enqueueHTTPRequestOperation:(TMHTTPRequest *)request {
	[request setOperationQueue:self.operationQueue];
	[request start];
}

- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method path:(NSString *)path {
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[TMHTTPRequest class]]) {
            continue;
        }

        if ((!method || [method isEqualToString:[[(TMHTTPRequest *)operation request] HTTPMethod]]) && [path isEqualToString:[[[(TMHTTPRequest *)operation request] URL] path]]) {
            [operation cancel];
        }
    }
}

#pragma mark -

- (TMHTTPRequest*)getPath:(NSString *)path
			   parameters:(NSDictionary *)parameters
				  success:(void (^)(TMHTTPRequest *operation, id responseObject))success
				  failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
    TMHTTPRequest *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];

    return operation;
}

- (TMHTTPRequest*)postPath:(NSString *)path
				parameters:(NSDictionary *)parameters
				   success:(void (^)(TMHTTPRequest *operation, id responseObject))success
				   failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
	TMHTTPRequest *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];

    return operation;
}

- (TMHTTPRequest*)putPath:(NSString *)path
			   parameters:(NSDictionary *)parameters
				  success:(void (^)(TMHTTPRequest *operation, id responseObject))success
				  failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
	TMHTTPRequest *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];

    return operation;
}

- (TMHTTPRequest*)deletePath:(NSString *)path
				  parameters:(NSDictionary *)parameters
					 success:(void (^)(TMHTTPRequest *operation, id responseObject))success
					 failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters];
	TMHTTPRequest *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
    return operation;
}

- (TMHTTPRequest*)patchPath:(NSString *)path
				 parameters:(NSDictionary *)parameters
					success:(void (^)(TMHTTPRequest *operation, id responseObject))success
					failure:(void (^)(TMHTTPRequest *operation, NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:@"PATCH" path:path parameters:parameters];
	TMHTTPRequest *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
    return operation;
}

@end




///
#pragma mark -

static NSString * const kAFMultipartFormCRLF = @"\r\n";

static inline NSString * AFMultipartFormInitialBoundary() {
    return [NSString stringWithFormat:@"--%@%@", kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormEncapsulationBoundary() {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormFinalBoundary() {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

@interface TMMultipartFormData ()
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@property (readwrite, nonatomic, retain) NSMutableData *mutableData;
@end

@implementation TMMultipartFormData

@synthesize stringEncoding = _stringEncoding;
@synthesize mutableData = _mutableData;

- (id)initWithStringEncoding:(NSStringEncoding)encoding {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.stringEncoding = encoding;
    self.mutableData = [NSMutableData dataWithLength:0];

    return self;
}

- (NSData *)data {
    NSMutableData *finalizedData = [NSMutableData dataWithData:self.mutableData];
    [finalizedData appendData:[AFMultipartFormFinalBoundary() dataUsingEncoding:self.stringEncoding]];
    return finalizedData;
}

#pragma mark - AFMultipartFormData

- (void)appendPartWithHeaders:(NSDictionary *)headers body:(NSData *)body {
    if ([self.mutableData length] == 0) {
        [self appendString:AFMultipartFormInitialBoundary()];
    } else {
        [self appendString:AFMultipartFormEncapsulationBoundary()];
    }

    for (NSString *field in [headers allKeys]) {
        [self appendString:[NSString stringWithFormat:@"%@: %@%@", field, [headers valueForKey:field], kAFMultipartFormCRLF]];
    }

    [self appendString:kAFMultipartFormCRLF];
    [self appendData:body];
}

- (void)appendPartWithFormData:(NSData *)data name:(NSString *)name {
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];

    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];

    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error {
    if (![fileURL isFileURL]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:fileURL forKey:NSURLErrorFailingURLErrorKey];
        [userInfo setValue:NSLocalizedString(@"Expected URL to be a file URL", nil) forKey:NSLocalizedFailureReasonErrorKey];
        if (error != NULL) {
            *error = [[NSError alloc] initWithDomain:@"com.tonymillion.tmhttprequest.error"
												code:NSURLErrorBadURL userInfo:userInfo];
        }

        return NO;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];

    if (data && response) {
        [self appendPartWithFileData:data name:name fileName:[response suggestedFilename] mimeType:[response MIMEType]];

        return YES;
    } else {
        return NO;
    }
}

- (void)appendData:(NSData *)data {
    [self.mutableData appendData:data];
}

- (void)appendString:(NSString *)string {
    [self appendData:[string dataUsingEncoding:self.stringEncoding]];
}

@end

