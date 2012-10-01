//
//  UsersListWindowController.h
//  Jukaela
//
//  Created by Josh on 10/1/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//



#import <Cocoa/Cocoa.h>
#import "PullToRefreshScrollView.h"

@class UserInformationWindowController;

@interface UsersListWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, PullToRefreshDelegate, NSWindowDelegate>

@property (strong, nonatomic) NSArray *usersArray;

@property (weak) IBOutlet PullToRefreshScrollView *ptrScrollView;
@property (strong, nonatomic) UserInformationWindowController *userInfoWindowController;

@property (strong, nonatomic) IBOutlet NSTableView *aTableView;

-(IBAction)showUser:(id)sender;

@end
