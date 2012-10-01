//
//  PostsWindowController.h
//  Jukaela
//
//  Created by Josh on 10/1/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PostsWindowController : NSWindowController

@property (strong, nonatomic) NSArray *theFeed;

@property (strong, nonatomic) IBOutlet NSTableView *aTableView;

@end
