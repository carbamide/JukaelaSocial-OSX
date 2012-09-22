//
//  TMHTTPRequest.h
//  xtendr
//
//  Created by Tony Million on 18/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMHTTPRequest;

typedef void (^TMHTTPSuccessBlock)(TMHTTPRequest * operation, id responseObject);
typedef void (^TMHTTPFailureBlock)(TMHTTPRequest * operation, NSError * error);

@interface TMHTTPRequest : NSObject

/**
 The request used by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSURLRequest *request;
/**
 The last response received by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSHTTPURLResponse *response;

/**
 The error, if any, that occured in the lifecycle of the request.
 */
@property (readonly, nonatomic, retain) NSError *error;

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 The data received during the request.
 */
@property (readonly) NSData *responseData;

/**
 The string representation of the response data.

 @discussion This method uses the string encoding of the response, or if UTF-8 if not specified, to construct a string from the response data.
 */
@property (readonly) NSString *responseString;

@property (copy) TMHTTPSuccessBlock  successBlock;
@property (copy) TMHTTPFailureBlock  failureBlock;

-(id)initWithRequest:(NSURLRequest*)request;
-(void)setOperationQueue:(NSOperationQueue*)queue;

-(BOOL)start;
-(BOOL)cancel;

@end
