//
//  NSString+BackslashEscape.m
//  Jukaela
//
//  Created by Josh Barrow on 5/13/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "NSString+BackslashEscape.h"

@implementation NSString (BackslashEscape)

-(NSString *)stringWithSlashEscapes 
{
    NSString *escapedString = nil;
    
    escapedString = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"-" withString:@"\\-"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"&" withString:@"\\&"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"!" withString:@"\\!"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"~" withString:@"\\~"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"*" withString:@"\\*"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"?" withString:@"\\?"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@":" withString:@"\\:"];
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    return escapedString;
}

@end
