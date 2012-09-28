//
//  MentionsViewController.m
//  Jukaela
//
//  Created by Josh on 9/24/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "MentionsViewController.h"
#import "PicCellView.h"
#import "ItemCellView.h"
#import "AppDelegate.h"
#import "SORelativeDateTransformer.h"
#import "NSDate+RailsDateParser.h"
#import "GravatarHelper.h"
#import "Helpers.h"

@interface MentionsViewController ()
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation MentionsViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [[self ptrScrollView] setDelegate:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)loadView
{
    [super loadView];

    CGRect rect = [[[kAppDelegate window] contentView] frame];
    
    [[self view] setFrame:rect];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];

    [self getMentionsFeed];
}

-(void)getMentionsFeed
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/mentions.json", kSocialURL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setMentions:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            NSLog(@"%@", [self mentions]);
            
            [[self aTableView] reloadData];
        }
        else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error loading your mentions.", nil];
            
            [alert runModal];
        }
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self mentions] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id cellView = nil;
    
    if ([self mentions][row][@"image_url"] && [self mentions][row][@"image_url"] != [NSNull null]) {
        cellView = (PicCellView *)[tableView makeViewWithIdentifier:@"PicCellView" owner:self];
        
        [[cellView textField] setStringValue:[self mentions][row][@"sender_name"]];
        [[cellView detailTextField] setStringValue:[self mentions][row][@"content"]];
        [[cellView usernameTextField] setStringValue:[self mentions][row][@"sender_username"]];
        
        if ([self mentions][row][@"repost_user_id"] && [self mentions][row][@"repost_user_id"] != [NSNull null]) {
            [[cellView repostedByTextField] setStringValue:[NSString stringWithFormat:@"Reposted by %@", [self mentions][row][@"repost_name"]]];
        }
        else {
            [[cellView repostedByTextField] setStringValue:@""];
        }
        
        if ([self mentions][row][@"image_url"] && [self mentions][row][@"image_url"] != [NSNull null]) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            
            dispatch_async(queue, ^{
                if ([[kAppDelegate externalImageCache] objectForKey:[NSNumber numberWithInt:row]]) {
                    [[cellView externalImage] setImage:[[kAppDelegate externalImageCache] objectForKey:[NSNumber numberWithInt:row]]];
                }
                else {
                    [[cellView externalImage] setImage:nil];
                }
                NSMutableString *tempString = [NSMutableString stringWithString:[self mentions][row][@"image_url"]];
                
                [tempString insertString:@"s" atIndex:24];
                
                NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
                
                [[kAppDelegate externalImageCache] setObject:image forKey:[NSNumber numberWithInt:row]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cellView externalImage] setImage:image];
                });
            });
        }
        
        NSDate *tempDate = [NSDate dateWithISO8601String:[self mentions][row][@"created_at"] withFormatter:[self dateFormatter]];
        
        [[cellView dateTextField] setStringValue:[[self dateTransformer] transformedValue:tempDate]];
        
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self mentions][row][@"sender_email"]]]]];
        
        if (image) {
            [[cellView imageView] setImage:image];
        }
        else {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            
            dispatch_async(queue, ^{
                NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self mentions][row][@"sender_email"]]]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cellView imageView] setImage:image];
                });
                
                [Helpers saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self mentions][row][@"sender_email"]]];
            });
        }
        
        if (row == ([[self mentions] count] - 1)) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
            
            NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%li\", \"last\" : \"%li\"}", [[self mentions] count], [[self mentions] count] + 20];
            
            NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:requestData];
            [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
            [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (data) {
                    NSMutableArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
                    
                    NSInteger oldTableViewCount = [[self mentions] count];
                    
                    [[self mentions] addObjectsFromArray:tempArray];
                    
                    @try {
                        [[self aTableView] beginUpdates];
                        
                        int tempArrayCount = [tempArray count];
                        
                        for (int i = 0; i < tempArrayCount; i++) {
                            NSInteger rowInt = oldTableViewCount + i;
                            
                            [[self aTableView] insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowInt] withAnimation:NSTableViewAnimationEffectFade];
                        }
                        [[self aTableView] endUpdates];
                    }
                    @catch (NSException *exception) {
                        if (exception) {
                            NSLog(@"%@", exception);
                        }
                        
                        [[self aTableView] reloadData];
                    }
                    @finally {
                        NSLog(@"Inside finally");
                    }
                }
                else {
                    NSLog(@"Error");
                }
            }];
            
        }
    }
    else {
        cellView = (PicCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        
        [[cellView textField] setStringValue:[self mentions][row][@"sender_name"]];
        [[cellView detailTextField] setStringValue:[self mentions][row][@"content"]];
        [[cellView usernameTextField] setStringValue:[self mentions][row][@"sender_username"]];
        
        if ([self mentions][row][@"repost_user_id"] && [self mentions][row][@"repost_user_id"] != [NSNull null]) {
            [[cellView repostedByTextField] setStringValue:[NSString stringWithFormat:@"Reposted by %@", [self mentions][row][@"repost_name"]]];
        }
        else {
            [[cellView repostedByTextField] setStringValue:@""];
        }
        
        NSDate *tempDate = [NSDate dateWithISO8601String:[self mentions][row][@"created_at"] withFormatter:[self dateFormatter]];
        
        [[cellView dateTextField] setStringValue:[[self dateTransformer] transformedValue:tempDate]];
        
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self mentions][row][@"sender_email"]]]]];
        
        if (image) {
            [[cellView imageView] setImage:image];
        }
        else {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            
            dispatch_async(queue, ^{
                NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self mentions][row][@"sender_email"]]]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cellView imageView] setImage:image];
                });
                
                [Helpers saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self mentions][row][@"sender_email"]]];
            });
        }
    }
    return cellView;
}

- (void)ptrScrollViewDidTriggerRefresh:(id)sender
{
    [self getMentionsFeed];
}

-(IBAction)showUser:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self mentions][[[self aTableView] clickedRow]][@"sender_user_id"]]];
    
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

-(IBAction)deselectRow:(id)sender
{
    [[self aTableView] deselectRow:[[self aTableView] clickedRow]];
}
@end
