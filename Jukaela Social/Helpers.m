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

@end
