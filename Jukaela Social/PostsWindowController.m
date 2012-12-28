//
//  PostsWindowController.m
//  Jukaela
//
//  Created by Josh on 10/1/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "PostsWindowController.h"
#import "PicCellView.h"
#import "ItemCellView.h"
#import "NSDate+RailsDateParser.h"
#import "SORelativeDateTransformer.h"
#import "Helpers.h"
#import "GravatarHelper.h"
#import "AppDelegate.h"
#import "UserInformationWindowController.h"
#import "NS(Attributed)String+Geometrics.h"

@interface PostsWindowController ()
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation PostsWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        [self setDateFormatter:[[NSDateFormatter alloc] init]];
        [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{    
    return [[self theFeed] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id cellView = nil;
    
    if (![self theFeed]) {
        return nil;
    }
    
    if ([self theFeed][row][@"image_url"] && [self theFeed][row][@"image_url"] != [NSNull null]) {
        cellView = (PicCellView *)[tableView makeViewWithIdentifier:@"PicCellView" owner:self];
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            if ([[kAppDelegate externalImageCache] objectForKey:[NSNumber numberWithInt:row]]) {
                [[cellView externalImage] setImage:[[kAppDelegate externalImageCache] objectForKey:[NSNumber numberWithInt:row]]];
            }
            else {
                [[cellView externalImage] setImage:nil];
            }
            NSMutableString *tempString = [NSMutableString stringWithString:[self theFeed][row][@"image_url"]];
            
            [tempString insertString:@"s" atIndex:24];
            
            NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
            
            [[kAppDelegate externalImageCache] setObject:image forKey:[NSNumber numberWithInt:row]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[cellView externalImage] setImage:image];
            });
        });
    }
    else {
        cellView = (PicCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    }
    
    [[cellView textField] setStringValue:[self theFeed][row][@"name"]];
    [[cellView detailTextField] setStringValue:[self theFeed][row][@"content"]];
    [[cellView usernameTextField] setStringValue:[self theFeed][row][@"username"]];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
    [NSAnimationContext endGrouping];
    
    if ([self theFeed][row][@"repost_user_id"] && [self theFeed][row][@"repost_user_id"] != [NSNull null]) {
        [[cellView repostedByTextField] setStringValue:[NSString stringWithFormat:@"Reposted by %@", [self theFeed][row][@"repost_name"]]];
    }
    else {
        [[cellView repostedByTextField] setStringValue:@""];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self theFeed][row][@"created_at"] withFormatter:[self dateFormatter]];
    
    if (tempDate) {
        [[cellView dateTextField] setStringValue:[[self dateTransformer] transformedValue:tempDate]];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self theFeed][row][@"email"]]]]];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);

    if (image) {
        [[cellView imageButton] setImage:image];
        
        dispatch_async(queue, ^{
            NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self theFeed][row][@"email"]]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[cellView imageButton] setImage:image];
            });
            
            [Helpers saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self theFeed][row][@"email"]]];
        });
    }
    else {        
        dispatch_async(queue, ^{
            NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self theFeed][row][@"email"]]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[cellView imageButton] setImage:image];
            });
            
            [Helpers saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self theFeed][row][@"email"]]];
        });
    }
    
    return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSString *contentText = [self theFeed][row][@"content"];
    NSString *nameText = [self theFeed][row][@"name"];
    
    CGSize constraint;
    
    if ([self theFeed][row][@"image_url"] && [self theFeed][row][@"image_url"] != [NSNull null]) {
        if ([self theFeed][row][@"repost_user_id"] && [self theFeed][row][@"repost_user_id"] != [NSNull null]) {
            constraint = CGSizeMake(165 - (7.5 * 2), 20000);
        }
        else {
            constraint = CGSizeMake(185 - (7.5 * 2), 20000);
        }
    }
    else {
        constraint = CGSizeMake(215 - (7.5 * 2), 20000);
    }
    
    NSSize contentSize = [contentText sizeForWidth:constraint.width height:constraint.height font:[NSFont fontWithName:@"Lucida Grande" size:11]];
    NSSize nameSize = [nameText sizeForWidth:constraint.width height:constraint.height font:[NSFont systemFontOfSize:13]];
    
    CGFloat height;
    
    if ([self theFeed][row][@"repost_user_id"] && [self theFeed][row][@"repost_user_id"] != [NSNull null]) {
        height = MAX(contentSize.height + nameSize.height + 10, 94);
    }
    else {
        height = MAX(contentSize.height + nameSize.height + 10, 94);
    }
    
    if (height == 0) {
        return 100;
    }
    else {        
        return height + 10;
    }
}
-(IBAction)showUser:(id)sender
{
    [[self aTableView] deselectRow:[[self aTableView] clickedRow]];
    
    NSURL *url = nil;

    if ([[sender class] isSubclassOfClass:[NSButton class]]) {
        NSInteger indexPath = [(NSTableView *)[[[sender superview] superview] superview] rowForView:[sender superview]];
        
        if ([self theFeed][indexPath][@"original_poster_id"] && [self theFeed][indexPath][@"original_poster_id"] != [NSNull null]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][indexPath][@"original_poster_id"]]];
        }
        else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][indexPath][@"user_id"]]];
        }
    }
    else {
        if ([self theFeed][[[self aTableView] clickedRow]][@"original_poster_id"] && [self theFeed][[[self aTableView] clickedRow]][@"original_poster_id"] != [NSNull null]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[[self aTableView] clickedRow]][@"original_poster_id"]]];
        }
        else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[[self aTableView] clickedRow]][@"user_id"]]];
        }
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
