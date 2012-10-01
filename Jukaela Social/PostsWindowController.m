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
    
    if (image) {
        [[cellView imageButton] setImage:image];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
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

@end
