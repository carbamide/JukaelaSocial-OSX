//
//  AppDelegate.h
//  Jukaela Social
//
//  Created by Josh on 9/4/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) IBOutlet NSToolbar *toolbar;
@property (strong, nonatomic) IBOutlet NSToolbarItem *buttonWithView;
@property (strong, nonatomic) NSProgressIndicator *progressIndicator;
@property (strong, nonatomic) NSMutableDictionary *testDictionary;
@property (strong, nonatomic) NSCache *externalImageCache;

-(IBAction)postToJukaela:(id)sender;
-(IBAction)logout:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)refreshFeed:(id)sender;

@end
