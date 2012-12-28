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

NS_ENUM(NSInteger, ChangeType) {
    INSERT_POST,
    DELETE_POST,
    OTHER_CHANGE_TYPE
};

@interface FeedViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSSharingServiceDelegate, PullToRefreshDelegate, NSOpenSavePanelDelegate>

@property (strong, nonatomic) NSMutableArray *theFeed;

@property (strong, nonatomic) IBOutlet NSTableView *aTableView;
@property (strong, nonatomic) IBOutlet NSTextView *aTextView;
@property (strong, nonatomic) IBOutlet NSButton *sendButton;
@property (strong, nonatomic) IBOutlet NSButton *picButton;
@property (strong, nonatomic) IBOutlet NSPopover *popover;
@property (strong, nonatomic) IBOutlet NSTextField *characterCountLabel;
@property (nonatomic) enum ChangeType currentChangeType;
@property (strong, nonatomic) IBOutlet NSProgressIndicator *postProgressIndicator;
@property (strong, nonatomic) UserInformationWindowController *userInfoWindowController;
@property (strong, nonatomic) IBOutlet PullToRefreshScrollView *aScrollView;
@property (strong) IBOutlet NSButton *twitterCheck;
@property (strong) IBOutlet NSButton *facebookCheck;

-(IBAction)sendPost:(id)sender;
-(IBAction)deletePost:(id)sender;
-(IBAction)repostPost:(id)sender;
-(IBAction)replyToPost:(id)sender;
-(IBAction)closePopover:(id)sender;
-(IBAction)showUser:(id)sender;
-(IBAction)openImage:(id)sender;
-(IBAction)deselectRow:(id)sender;
-(IBAction)sharingAction:(id)sender;
-(IBAction)shareToFacebook:(id)sender;
-(IBAction)shareToTwitter:(id)sender;

-(void)showPopover:(NSRect)rect ofView:(NSView *)aView;
-(void)getFeed:(NSInteger)row;

@end
