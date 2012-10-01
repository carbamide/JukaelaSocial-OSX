//
//  UsersListWindowController.m
//  Jukaela
//
//  Created by Josh on 10/1/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "UsersCellView.h"
#import "Helpers.h"
#import "GravatarHelper.h"
#import "AppDelegate.h"

#import "UsersListWindowController.h"
#import "UserInformationWindowController.h"

@interface UsersListWindowController ()

@end

@implementation UsersListWindowController

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
}

-(void)awakeFromNib
{
    [super awakeFromNib];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{    
    return [[self usersArray] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    UsersCellView *cellView = (UsersCellView *)[tableView makeViewWithIdentifier:@"UsersListCellView" owner:self];

    if ([self usersArray][row][@"name"] && [self usersArray][row][@"name"] != [NSNull null]) {
        [[cellView textField] setStringValue:[self usersArray][row][@"name"]];
    }
    
    if ([self usersArray][row][@"username"] && [self usersArray][row][@"username"] != [NSNull null]) {
        [[cellView detailTextField] setStringValue:[self usersArray][row][@"username"]];
    }
    else {
        [[cellView detailTextField] setStringValue:@"No username specified"];
    }
    
    if ([self usersArray][row][@"email"] && [self usersArray][row][@"email"] != [NSNull null]) {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self usersArray][row][@"email"]]]]];
        
        if (image) {
            [[cellView imageButton] setImage:image];
        }
        else {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            
            dispatch_async(queue, ^{
                NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self usersArray][row][@"email"]]]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cellView imageButton] setImage:image];
                });
                
                [Helpers saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self usersArray][row][@"email"]]];
            });
        }
    }
    if (!cellView) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There has been an error loading the list of users.", nil];
        
        [alert runModal];
    }
    return cellView;
}

-(IBAction)showUser:(id)sender
{
    [[self aTableView] deselectRow:[[self aTableView] clickedRow]];
    
    NSURL *url = nil;
    
    if ([[sender class] isSubclassOfClass:[NSButton class]]) {
        NSInteger indexPath = [(NSTableView *)[[[sender superview] superview] superview] rowForView:[sender superview]];
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self usersArray][indexPath][@"id"]]];
    }
    else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self usersArray][[[self aTableView] clickedRow]][@"id"]]];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
            
            if (![self userInfoWindowController]) {
                [self setUserInfoWindowController:[[UserInformationWindowController alloc] initWithWindowNibName:@"UserInformationWindow"]];
            }
            
            [[self userInfoWindowController] setUserDict:tempDict];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reload_labels" object:nil];
            
            [[self userInfoWindowController] showWindow:self];
        }
        else {
            NSLog(@"There was an error retrieving the user information");
        }
    }];
}

@end
