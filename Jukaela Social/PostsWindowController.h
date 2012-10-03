//
//  PostsWindowController.h
//  Jukaela
//
//  Created by Josh on 10/1/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UserInformationWindowController;

@interface PostsWindowController : NSWindowController

@property (strong, nonatomic) NSArray *theFeed;

@property (strong, nonatomic) IBOutlet NSTableView *aTableView;
@property (strong, nonatomic) UserInformationWindowController *userInfoWindowController;

-(IBAction)showUser:(id)sender;

@end
