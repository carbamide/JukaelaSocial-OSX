//
//  AppDelegate.h
//  Jukaela Social
//
//  Created by Josh on 9/4/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) IBOutlet NSToolbar *toolbar;
@property (strong, nonatomic) IBOutlet NSToolbarItem *buttonWithView;
@property (strong, nonatomic) NSProgressIndicator *progressIndicator;
@property (strong, nonatomic) NSMutableDictionary *testDictionary;
@property (strong, nonatomic) NSCache *externalImageCache;
@property (strong, nonatomic) NSArray *selectedDownloads;
@property (nonatomic) NSRect currentRowRect;

-(IBAction)postToJukaela:(id)sender;
-(IBAction)logout:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)refreshFeed:(id)sender;

@end
