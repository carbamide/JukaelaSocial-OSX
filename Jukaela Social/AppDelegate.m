//
//  AppDelegate.m
//  Jukaela Social
//
//  Created by Josh on 9/4/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#include "FeedViewController.h"
#import "LoginWindow.h"
#import "PreferencesWindow.h"
#import "TMImgurUploader.h"
#import "MentionsViewController.h"

#define kFontSizeToolbarItemID      @"FontSize"
#define kFontStyleToolbarItemID     @"FontStyle"
#define kBlueLetterToolbarItemID    @"BlueLetter"

@interface AppDelegate()
@property (nonatomic,strong) IBOutlet FeedViewController *feedViewController;
@property (strong, nonatomic) NSArray *tempFeed;
@property (strong, nonatomic) LoginWindow *loginWindow;
@property (strong, nonatomic) PreferencesWindow *preferencesWindow;
@property (strong, nonatomic) NSViewController *currentViewController;
@property (strong, nonatomic) MentionsViewController *mentionsViewController;

@end
@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];

    INAppStoreWindow *aWindow = (INAppStoreWindow *)[self window];
    
    [aWindow setTitleBarHeight:40];
    
    [[aWindow titleBarView] addSubview:[self titleView]];
    
    [[TMImgurUploader sharedInstance] setAPIKey:kImgurAPIKey];

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"post_to_twitter" : [NSNumber numberWithBool:NO], @"post_to_facebook" : [NSNumber numberWithBool:NO], @"confirm_posting" : [NSNumber numberWithBool:NO]}];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postToJukaela:) name:@"post_to_jukaela" object:nil];

    [self setFeedViewController:[[FeedViewController alloc] initWithNibName:@"FeedViewController" bundle:nil]];
    
    [self setCurrentViewController:[self feedViewController]];
    
    [[[self window] contentView] addSubview:[[self feedViewController] view]];
    
    if (![self loginWindow]) {
        _loginWindow = [[LoginWindow alloc] initWithWindowNibName:@"LoginWindow"];
        
        [_loginWindow setFeedViewController:_feedViewController];
    }
    
    [NSApp showWindow:[_loginWindow window]];
    
    [[_loginWindow window] makeKeyAndOrderFront:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSArray *tempArray = [[NSUserNotificationCenter defaultUserNotificationCenter] scheduledNotifications];
    
    for (NSUserNotification *notification in tempArray) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotification:notification];
    }
}

-(IBAction)postToJukaela:(id)sender
{    
    [[self feedViewController] showPopover:[[self postButton] frame] ofView:[self titleView]];
}

-(IBAction)logout:(id)sender
{    
    if (![self loginWindow]) {
        _loginWindow = [[LoginWindow alloc] initWithWindowNibName:@"LoginWindow"];
        
        [_loginWindow setFeedViewController:_feedViewController];
    }
        
    [[_loginWindow window] makeKeyAndOrderFront:self];
    
    [[_loginWindow usernameTextField] setStringValue:@""];
    [[_loginWindow passwordTextField] setStringValue:@""];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setUserID:nil];
}

-(IBAction)showPreferences:(id)sender
{
    if (![self preferencesWindow]) {
        _preferencesWindow = [[PreferencesWindow alloc] initWithWindowNibName:@"PreferencesWindow"];
        
        [[_preferencesWindow window] makeKeyAndOrderFront:self];
    }
    else {
        [[_preferencesWindow window] orderFront:nil];
    }
}

-(IBAction)refreshFeed:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_tables" object:nil];
}

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    [panel setDelegate:self];
    [panel setDataSource:self];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    return;
}

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [_selectedDownloads count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [_selectedDownloads objectAtIndex:index];
}

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    return NO;
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    return [self currentRowRect];
}

- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    return nil;
}

-(IBAction)changeViews:(ANSegmentedControl *)sender
{
    if ([sender selectedSegment] == 0) {
        if (![self feedViewController]) {
            [self setFeedViewController:[[FeedViewController alloc] initWithNibName:@"FeedViewController" bundle:nil]];
        }
        
        if (![NSStringFromClass([[self currentViewController] class]) isEqualToString:NSStringFromClass([[self feedViewController] class])]) {
            [[[self currentViewController] view] removeFromSuperview];
            
            [[[self window] contentView] addSubview:[[self feedViewController] view]];
            
            [self setCurrentViewController:[self feedViewController]];
        }
        NSLog(@"FeedViewController!");
    }
    else if ([sender selectedSegment] == 1) {
        if (![self mentionsViewController]) {
            [self setMentionsViewController:[[MentionsViewController alloc] initWithNibName:@"MentionsViewController" bundle:nil]];
        }
        
        if (![NSStringFromClass([[self currentViewController] class]) isEqualToString:NSStringFromClass([[self mentionsViewController] class])]) {
            [[[self currentViewController] view] removeFromSuperview];
            
            [[[self window] contentView] addSubview:[[self mentionsViewController] view]];
            
            [self setCurrentViewController:[self mentionsViewController]];
        }
        NSLog(@"MentionsViewController!");
    }
    else if ([sender selectedSegment] == 2) {
        NSLog(@"Three!");
    }
}

-(IBAction)showWindow:(id)sender
{
    [[self window] makeKeyAndOrderFront:nil];
}

-(IBAction)postOnlyToFacebook:(id)sender
{
    [self setOnlyToFacebook:YES];
    
    [[self feedViewController] showPopover:[[self postButton] frame] ofView:[self titleView]];
}

-(IBAction)postOnlyToTwitter:(id)sender
{
    [self setOnlyToTwitter:YES];
    
    [[self feedViewController] showPopover:[[self postButton] frame] ofView:[self titleView]];
}

-(IBAction)postOnlyToJukaela:(id)sender
{
    [self setOnlyToJukaela:YES];
    
    [[self feedViewController] showPopover:[[self postButton] frame] ofView:[self titleView]];
}

@end
