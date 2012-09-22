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

#define kFontSizeToolbarItemID      @"FontSize"
#define kFontStyleToolbarItemID     @"FontStyle"
#define kBlueLetterToolbarItemID    @"BlueLetter"

@interface AppDelegate()
@property (nonatomic,strong) IBOutlet FeedViewController *feedViewController;
@property (strong, nonatomic) NSArray *tempFeed;
@property (strong, nonatomic) LoginWindow *loginWindow;
@property (strong, nonatomic) PreferencesWindow *preferencesWindow;

@end
@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[TMImgurUploader sharedInstance] setAPIKey:kImgurAPIKey];

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"post_to_twitter" : [NSNumber numberWithBool:NO], @"post_to_facebook" : [NSNumber numberWithBool:NO], @"confirm_posting" : [NSNumber numberWithBool:NO]}];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postToJukaela:) name:@"post_to_jukaela" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startProgressAnimation:) name:@"start_animation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopProgressAnimation:) name:@"stop_animation" object:nil];

    [self setFeedViewController:[[FeedViewController alloc] initWithNibName:@"FeedViewController" bundle:nil]];
        
    [[[self window] contentView] addSubview:[[self feedViewController] view]];
    
    if (![self loginWindow]) {
        _loginWindow = [[LoginWindow alloc] initWithWindowNibName:@"LoginWindow"];
        
        [_loginWindow setFeedViewController:_feedViewController];
    }
    
    [NSApp showWindow:[_loginWindow window]];
    
    [[_loginWindow window] makeKeyAndOrderFront:self];
}

-(void)awakeFromNib
{
    [_toolbar setAllowsUserCustomization:YES];
    [_toolbar setAutosavesConfiguration:YES];
    [_toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
}

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier
                                       label:(NSString *)label
                                 paleteLabel:(NSString *)paletteLabel
                                     toolTip:(NSString *)toolTip
                                      target:(id)target
                                 itemContent:(id)imageOrView
                                      action:(SEL)action
                                        menu:(NSMenu *)menu
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    [item setAction:action];
    
    if([imageOrView isKindOfClass:[NSImage class]]) {
        [item setImage:imageOrView];
    }
    else if ([imageOrView isKindOfClass:[NSView class]]) {
        [item setView:imageOrView];
    }
    else {
        assert(!"Invalid itemContent: object");
    }

    if (menu) {
        NSMenuItem *mItem = [[NSMenuItem alloc] init];
        
        [mItem setSubmenu:menu];
        [mItem setTitle:label];
        [item setMenuFormRepresentation:mItem];
    }
    
    return item;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return YES;
}

- (void)toolbarWillAddItem:(NSNotification *)notif
{
    NSLog(@"Adding toolbar items");
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = nil;
    
    if ([itemIdentifier isEqualToString:@"PostToJukaela"]) {
        
        toolbarItem = [self toolbarItemWithIdentifier:kBlueLetterToolbarItemID
                                                label:@"Post"
                                          paleteLabel:@"Post"
                                              toolTip:@"Post to Jukaela Social"
                                               target:self
                                          itemContent:[NSImage imageNamed:@"blueLetter.tif"]
                                               action:@selector(postToJukaela:)
                                                 menu:nil];
    }
    else if ([itemIdentifier isEqualToString:NSToolbarFlexibleSpaceItemIdentifier]) {
        toolbarItem = [self toolbarItemWithIdentifier:NSToolbarFlexibleSpaceItemIdentifier
                                                label:nil
                                          paleteLabel:@"Flexible Space"
                                              toolTip:nil 
                                               target:nil
                                          itemContent:nil
                                               action:nil
                                                 menu:nil];
        
    }
    else if ([itemIdentifier isEqualToString:@"ActivityIndicator"]) {
        _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
        
        [_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
        [_progressIndicator setIndeterminate:YES];
        [_progressIndicator setHidden:YES];
        
        toolbarItem = [self toolbarItemWithIdentifier:@"AcitivtyIndicator"
                                                label:@"Activity"
                                          paleteLabel:@"Activity"
                                              toolTip:@"Doing stuff!"
                                               target:nil
                                          itemContent:_progressIndicator
                                               action:nil menu:nil];
    }
    
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"PostToJukaela", NSToolbarFlexibleSpaceItemIdentifier, @"ActivityIndicator"];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[kFontStyleToolbarItemID, kFontSizeToolbarItemID, @"PostToJukaela", NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarPrintItemIdentifier, @"ActivityIndicator"];
}

-(void)postToJukaela:(id)sender
{    
    [[self feedViewController] showPopover:[[[self buttonWithView] view] frame] ofView:[[self buttonWithView] view]];
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
    }
    
    [[_preferencesWindow window] makeKeyAndOrderFront:self];
}

-(void)startProgressAnimation:(NSNotification *)aNotification
{
    [[self progressIndicator] setHidden:NO];
    [[self progressIndicator] startAnimation:self];
}

-(void)stopProgressAnimation:(NSNotification *)aNotification
{
    [[self progressIndicator] setHidden:YES];
    [[self progressIndicator] stopAnimation:self];
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
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [_selectedDownloads count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [_selectedDownloads objectAtIndex:index];
}

// Quick Look panel delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    return [self currentRowRect];
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    return nil;
}
@end
