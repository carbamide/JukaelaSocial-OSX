//
//  TMImgurUploader.m
//  xtendr
//
//  Created by Tony Million on 21/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "TMImgurUploader.h"
#import "TMHTTPClient.h"

@implementation TMImgurUploader

+(TMImgurUploader *)sharedInstance
{
	static dispatch_once_t pred = 0;
    
    __strong static id _sharedObject = nil;
    
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}

-(TMHTTPRequest *)uploadImage:(NSImage *)image finishedBlock:(uploadBlock)completionBlock
{
    NSBitmapImageRep *imgRep = [[image representations] objectAtIndex: 0];
    
    NSData *encodedImage = [imgRep representationUsingType: NSJPEGFileType properties: nil];
    
	NSMutableDictionary	*params = [NSMutableDictionary dictionaryWithCapacity:3];

	[params setObject:self.APIKey
			   forKey:@"key"];

    TMHTTPClient *imgurclient = [[[TMHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.imgur.com/2/"]] autorelease];

	NSMutableURLRequest *request = [imgurclient multipartFormRequestWithMethod:@"POST"
																		  path:@"upload.json"
																	parameters:params
													 constructingBodyWithBlock:^(id<TMMultipartFormData> formData) {
																 [formData appendPartWithFileData:encodedImage
																							 name:@"image"
																						 fileName:@"image.jpg"
																						 mimeType:@"image/jpeg"];
															 }];

	TMHTTPRequest	* req = [imgurclient HTTPRequestOperationWithRequest:request
															   success:^(TMHTTPRequest *operation, id responseObject) {
																   NSLog(@"IMGURUPLOAD S: %@", responseObject);
																   if(completionBlock)
																   {
																	   completionBlock(responseObject, nil);
																   }
															   }
															   failure:^(TMHTTPRequest *operation, NSError *error) {
																   NSLog(@"IMGURUPLOAD F: %@", operation.responseString);

																   if(completionBlock)
																   {
																	   completionBlock(nil, error);
																   }
															   }];

	[imgurclient enqueueHTTPRequestOperation:req];

	return req;
}


@end
