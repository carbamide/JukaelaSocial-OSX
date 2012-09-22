//
//  TMHTTPRequest.m
//  xtendr
//
//  Created by Tony Million on 18/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "TMHTTPRequest.h"
#import "TMNetworkActivityIndicatorManager.h"

NSString * const TMNetworkingErrorDomain = @"com.tonymillion.tmhttprequest.error";

static NSString * AFStringFromIndexSet(NSIndexSet *indexSet) {
    NSMutableString *string = [NSMutableString string];

    NSRange range = NSMakeRange([indexSet firstIndex], 1);
    while (range.location != NSNotFound) {
        NSUInteger nextIndex = [indexSet indexGreaterThanIndex:range.location];
        while (nextIndex == range.location + range.length) {
            range.length++;
            nextIndex = [indexSet indexGreaterThanIndex:nextIndex];
        }

        if (string.length) {
            [string appendString:@","];
        }

        if (range.length == 1) {
            [string appendFormat:@"%lu", range.location];
        } else {
            NSUInteger firstIndex = range.location;
            NSUInteger lastIndex = firstIndex + range.length - 1;
            [string appendFormat:@"%lu-%lu", firstIndex, lastIndex];
        }

        range.location = nextIndex;
        range.length = 1;
    }

    return string;
}


@interface TMHTTPRequest ()

@property(strong) NSOperationQueue *requestOperationQueue;

@end

@implementation TMHTTPRequest

@synthesize responseString = _responseString;


+ (NSIndexSet *)acceptableStatusCodes {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
}

- (BOOL)hasAcceptableStatusCode {
    return ![[self class] acceptableStatusCodes] || [[[self class] acceptableStatusCodes] containsIndex:[self.response statusCode]];
}

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
}
- (BOOL)hasAcceptableContentType {
    return ![[self class] acceptableContentTypes] || [[[self class] acceptableContentTypes] containsObject:[self.response MIMEType]];
}

-(id)initWithRequest:(NSURLRequest*)URLRequest
{
    self = [super init];
    if (!self) {
		return nil;
    }

    _request = URLRequest;

    return self;
}

-(void)setOperationQueue:(NSOperationQueue*)queue
{
	self.requestOperationQueue = queue;
}

-(BOOL)start
{
    [NSURLConnection sendAsynchronousRequest:self.request
                                       queue:self.requestOperationQueue
                           completionHandler:^(NSURLResponse *response, NSData *remoteData, NSError *error) {

							   [[TMNetworkActivityIndicatorManager sharedManager] decrementActivityCount];

                               _responseData    = remoteData;
                               _response        = (NSHTTPURLResponse*)response;

                               if(!error)
                               {
                                   if(![self hasAcceptableStatusCode])
                                   {
                                       NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                                       [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected status code in (%@), got %d", nil),
                                                           AFStringFromIndexSet([[self class] acceptableStatusCodes]),
                                                           [self.response statusCode]]
                                                   forKey:NSLocalizedDescriptionKey];

                                       [userInfo setValue:[self.request URL]
                                                   forKey:NSURLErrorFailingURLErrorKey];

                                       NSError * httpError = [[NSError alloc] initWithDomain:TMNetworkingErrorDomain
                                                                                        code:NSURLErrorBadServerResponse
                                                                                    userInfo:userInfo];

                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           if(self.failureBlock)
                                               self.failureBlock(self, httpError);
                                       });

                                       return;
                                   }

                                   //TODO: REPLACE THIS WITH IN SET of responses
                                   if([[response.MIMEType lowercaseString] isEqualToString:@"application/json"] && remoteData && remoteData.length)
                                   {
                                       NSError *JSONerror = nil;

                                       id JSON = [NSJSONSerialization JSONObjectWithData:remoteData
                                                                                 options:0
                                                                                   error:&JSONerror];
                                       if(JSON)
                                       {
                                           if(self.successBlock)
                                           {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   if(self.successBlock)
                                                       self.successBlock(self, JSON);
                                               });
                                           }
                                       }
                                       else
                                       {
                                           if(self.failureBlock)
                                           {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   if(self.failureBlock)
                                                       self.failureBlock(self, JSONerror);
                                               });
                                           }
                                       }
                                   }
                                   else
                                   {
                                       if(self.successBlock)
                                       {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if(self.successBlock)
                                                   self.successBlock(self, remoteData);
                                           });
                                       }
                                   }
                               }
                               else
                               {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if(self.failureBlock)
                                           self.failureBlock(self, error);
                                   });
                               }

                           }];

	return YES;
}

-(BOOL)cancel
{
    NSLog(@"TMHTTPRequest CANCEL!");

    // when we cancel we clear out the callback blocks which means our API wont be hit with unnecessary data
    // NOTE: THIS DOES NOT CURRENTLY STOP THE DOWNLOAD FROM HAPPENING!!!!!!
    self.successBlock = nil;
    self.failureBlock = nil;

	return YES;
}

- (NSString *)responseString
{
    // this is allocated on demand!
    if (!_responseString && self.response && self.responseData)
    {
        NSStringEncoding textEncoding = NSUTF8StringEncoding;
        if(self.response.textEncodingName)
        {
            textEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(( CFStringRef)self.response.textEncodingName));
        }

        _responseString = [[NSString alloc] initWithData:self.responseData encoding:textEncoding];
    }

    return _responseString;
}

@end
