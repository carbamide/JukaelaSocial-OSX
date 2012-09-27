//
//  UsersCellView.m
//  Jukaela
//
//  Created by Josh on 9/27/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "UsersCellView.h"

static BOOL kLargeSizeRequested = YES;

@implementation UsersCellView

-(void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
    
	[self layoutViewsForLargeSize:kLargeSizeRequested animated:NO];
}

-(void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
}

-(void)layoutViewsForLargeSize:(BOOL)largeSize animated:(BOOL)animated
{
	kLargeSizeRequested = largeSize;
	    
	CGFloat iconSize = largeSize ? 32.0f : 16.0f;
	NSRect iconFrame = NSMakeRect(2.0f, 2.0f, iconSize, iconSize);
	
	CGFloat nameLeft = iconFrame.origin.x + iconFrame.size.width + 5.0f;
	CGFloat nameBottom = iconFrame.origin.y + iconFrame.size.height - (largeSize ? 18.0f : 16.0f);
	CGFloat nameWidth = self.bounds.size.width - nameLeft - 2.0f;
	CGFloat nameHeight = 16.0f;
	NSRect nameFrame = NSMakeRect(nameLeft, nameBottom, nameWidth, nameHeight);
	
	if (animated) {
		[[[self imageView] animator] setFrame:iconFrame];
		[[[self textField] animator] setFrame:nameFrame];
	}
    else {
		[[self imageView] setFrame:iconFrame];
		[[self textField] setFrame:nameFrame];
	}
}

@end
