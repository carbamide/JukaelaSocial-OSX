//
//  GravatarHelper.h
//  TestBed
//
//  Created by Josh Barrow on 5/4/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GravatarHelper : NSObject

+(NSURL *)getGravatarURL:(NSString *)emailAddress;

@end
