//
//  JButton.m
//  Jukaela
//
//  Created by Josh on 9/26/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "JButton.h"

@implementation NSColor (colorFromHexRGB)


+ (NSColor *) colorFromHexRGB:(NSString *) inColorString
{
	NSColor *result = nil;
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	if (nil != inColorString)
	{
		NSScanner *scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode];	// ignore error
	}
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	result = [NSColor
              colorWithCalibratedRed:		(float)redByte	/ 0xff
              green:	(float)greenByte/ 0xff
              blue:	(float)blueByte	/ 0xff
              alpha:1.0];
	return result;
}

@end

@implementation JButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(dirtyRect, 2, 2) xRadius:8 yRadius:8];
    
    [path setLineWidth:2];
    [path addClip];
    
    [[self image] drawAtPoint: NSZeroPoint fromRect:dirtyRect operation:NSCompositeSourceOver fraction: 1.0];
    
    [super drawRect:dirtyRect];
    
    NSColor *strokeColor = [NSColor colorFromHexRGB:@"000000"];
    
    [strokeColor set];
    [NSBezierPath setDefaultLineWidth:2];
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(dirtyRect, 2, 2) xRadius:8 yRadius:8] stroke];
}

@end
