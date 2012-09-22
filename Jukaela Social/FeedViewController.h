//
//  FeedViewController.h
//  Jukaela Social
//
//  Created by Josh on 9/4/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UserInformationWindowController.h"
#import "PullToRefreshScrollView.h"
#import "PullToRefreshDelegate.h"
#import "TMImgurUploader.h"

typedef enum {
    INSERT_POST = 0,
    DELETE_POST,
    OTHER_CHANGE_TYPE
} ChangeType;

@interface FeedViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSSharingServiceDelegate, PullToRefreshDelegate, NSOpenSavePanelDelegate>

@property (strong, nonatomic) NSMutableArray *theFeed;

@property (strong, nonatomic) IBOutlet NSTableView *aTableView;
@property (strong, nonatomic) IBOutlet NSTextView *aTextView;
@property (strong, nonatomic) IBOutlet NSButton *sendButton;
@property (assign) IBOutlet NSPopover *popover;
@property (strong, nonatomic) IBOutlet NSTextField *characterCountLabel;
@property (nonatomic) ChangeType currentChangeType;
@property (strong, nonatomic) IBOutlet NSProgressIndicator *postProgressIndicator;

@property (strong, nonatomic) UserInformationWindowController *userInfoWindowController;

@property (weak) IBOutlet PullToRefreshScrollView *ptrScrollView;

-(IBAction)sendPost:(id)sender;
-(IBAction)deletePost:(id)sender;
-(IBAction)repostPost:(id)sender;
-(IBAction)replyToPost:(id)sender;
-(IBAction)closePopover:(id)sender;
-(IBAction)showUser:(id)sender;
-(IBAction)openImage:(id)sender;

-(void)showPopover:(NSRect)rect ofView:(NSView *)aView;
-(void)getFeed:(NSInteger)row;

@end
