//
//  AppDelegate.h
//  Jukaela Social
//
//  Created by Josh on 9/4/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "ANSegmentedControl.h"
#import "INAppStoreWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate>

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSMutableDictionary *testDictionary;
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSArray *selectedDownloads;
@property (nonatomic) NSRect currentRowRect;

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet ANSegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet NSView *titleView;
@property (strong, nonatomic) IBOutlet NSButton *postButton;

-(IBAction)postToJukaela:(id)sender;
-(IBAction)logout:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)refreshFeed:(id)sender;

-(IBAction)changeViews:(ANSegmentedControl *)sender;
-(IBAction)showWindow:(id)sender;

@end
