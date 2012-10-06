//
//  Helpers.h
//  Jukaela
//
//  Created by Josh on 9/25/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helpers : NSObject

+(NSString *)applicationSupportPath;
+(void)saveImage:(NSImage *)image withFileName:(NSString *)emailAddress;
+(NSArray *)arrayOfURLsFromString:(NSString *)httpLine error:(NSError *)error;

@end
