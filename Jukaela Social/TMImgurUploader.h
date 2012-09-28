//
//  TMImgurUploader.h
//  xtendr
//
//  Created by Tony Million on 21/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMHTTPRequest.h"

typedef void (^uploadBlock)(NSDictionary *result, NSError * error);

@interface TMImgurUploader : NSObject

@property (copy) NSString *APIKey;

+(TMImgurUploader *)sharedInstance;

-(TMHTTPRequest *)uploadImage:(NSImage *)image finishedBlock:(uploadBlock)completionBlock;

@end
