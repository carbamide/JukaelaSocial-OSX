//
//  PreferencesWindowController.m
//  Jukaela Social
//
//  Created by Josh on 9/5/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "PreferencesWindow.h"

@interface PreferencesWindow ()

@end

@implementation PreferencesWindow

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"]) {
        [[self twitterCheckBox] setState:1];
    }
    else {
        [[self twitterCheckBox] setState:0];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"]) {
        [[self facebookCheckBox] setState:1];
    }
    else {
        [[self facebookCheckBox] setState:0];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"confirm_posting"]) {
        [[self confirmPosting] setState:1];
    }
    else {
        [[self confirmPosting] setState:0];
    }
}

-(IBAction)twitterChangePreferences:(id)sender
{
    if ([[self twitterCheckBox] state] == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"post_to_twitter"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"post_to_twitter"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)facebookChangePreferences:(id)sender
{
    if ([[self facebookCheckBox] state] == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"post_to_facebook"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"post_to_facebook"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)confirmPostingChangePrefernces:(id)sender
{
    if ([[self confirmPosting] state] == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"confirm_posting"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"confirm_posting"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
