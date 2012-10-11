//
//  AppDelegate.h
//  Jukaela Social
//
//  Created by Josh on 9/4/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "INAppStoreWindow.h"
#import "FeedViewController.h"
#import "UserInformationWindowController.h"
#import "EditProfileWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate>

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSMutableDictionary *testDictionary;
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSArray *selectedDownloads;
@property (nonatomic) NSRect currentRowRect;

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet NSSegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet NSView *titleView;
@property (strong, nonatomic) IBOutlet NSButton *postButton;
@property (strong, nonatomic) FeedViewController *feedViewController;
@property (strong, nonatomic) UserInformationWindowController *userInfoWindowController;
@property (strong, nonatomic) EditProfileWindowController *editProfileWindowController;
@property (nonatomic) BOOL onlyToFacebook;
@property (nonatomic) BOOL onlyToTwitter;
@property (nonatomic) BOOL onlyToJukaela;

-(IBAction)postToJukaela:(id)sender;
-(IBAction)logout:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)refreshFeed:(id)sender;
-(IBAction)changeViews:(NSSegmentedControl *)sender;
-(IBAction)showWindow:(id)sender;
-(IBAction)postOnlyToFacebook:(id)sender;
-(IBAction)postOnlyToTwitter:(id)sender;
-(IBAction)postOnlyToJukaela:(id)sender;
-(IBAction)editProfile:(id)sender;
-(IBAction)submitFeedback:(id)sender;
-(IBAction)closeWindow:(id)sender;

@end
