//
//  GravatarHelper.m
//  TestBed
//
//  Created by Josh Barrow on 5/4/12.
//  Copyright (c) 2012 Jukaela Enterprises All rights reserved.
//

#import "GravatarHelper.h"
#import <CommonCrypto/CommonDigest.h>

@implementation GravatarHelper

+(NSURL *)getGravatarURL:(NSString *)emailAddress
{
    if (!emailAddress) {
        return nil;
    }
    
	NSString *curatedEmail = [[emailAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    
	const char *cStr = [curatedEmail UTF8String];
    
    unsigned char result[16];
    
    CC_MD5(cStr, strlen(cStr), result);
    
	NSString *md5email = [NSString stringWithFormat:
                          @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          result[0], result[1], result[2], result[3],
                          result[4], result[5], result[6], result[7],
                          result[8], result[9], result[10], result[11],
                          result[12], result[13], result[14], result[15]
                          ];
    
	NSString *gravatarEndPoint = [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@?s=75&d=mm", md5email];
    
	return [NSURL URLWithString:gravatarEndPoint];
}

@end
