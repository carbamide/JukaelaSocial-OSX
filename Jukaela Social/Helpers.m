//
//  Helpers.m
//  Jukaela
//
//  Created by Josh on 9/25/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "Helpers.h"

@implementation Helpers

+(NSString *)applicationSupportPath
{
    NSArray *tempArray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = tempArray[0];
    
    return documentsDirectory;
}

+(void)saveImage:(NSImage *)image withFileName:(NSString *)emailAddress
{
    if (image != nil) {
        NSString *path = [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithString:[NSString stringWithFormat:@"%@.png", emailAddress]]];
        
        NSBitmapImageRep *imgRep = [[image representations] objectAtIndex:0];
        
        NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
        
        [data writeToFile:path atomically: NO];
    }
}

+(NSArray *)arrayOfURLsFromString:(NSString *)httpLine error:(NSError *)error
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *arrayOfAllMatches = [regex matchesInString:httpLine options:0 range:NSMakeRange(0, [httpLine length])];
    
    NSMutableArray *arrayOfURLs = [[NSMutableArray alloc] init];
    
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        NSString* substringForMatch = [httpLine substringWithRange:match.range];
        
        [arrayOfURLs addObject:substringForMatch];
    }
    
    // return non-mutable version of the array
    return [NSArray arrayWithArray:arrayOfURLs];
}

@end
