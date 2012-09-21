//
//  PreferencesWindow.h
//  Jukaela Social
//
//  Created by Josh on 9/5/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindow : NSWindowController

@property (strong, nonatomic) IBOutlet NSButton *twitterCheckBox;
@property (strong, nonatomic) IBOutlet NSButton *facebookCheckBox;
@property (strong, nonatomic) IBOutlet NSButton *confirmPosting;

-(IBAction)twitterChangePreferences:(id)sender;
-(IBAction)facebookChangePreferences:(id)sender;
-(IBAction)confirmPostingChangePrefernces:(id)sender;

@end
