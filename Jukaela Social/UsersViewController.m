//
//  UsersViewController.m
//  Jukaela
//
//  Created by Josh on 9/27/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "UsersViewController.h"
#import "UsersCellView.h"
#import "Helpers.h"
#import "GravatarHelper.h"
#import "AppDelegate.h"

@interface UsersViewController ()

@end

@implementation UsersViewController

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
    
    [self getUsers];
}

-(void)getUsers
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users.json", kSocialURL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {            
            [self setUsersArray:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            NSLog(@"%@", [self usersArray]);
            
            [[self aTableView] reloadData];
        }
        else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There has been an error loading the list of users.", nil];
            
            [alert runModal];
        }
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self usersArray] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    UsersCellView *cellView = (UsersCellView *)[tableView makeViewWithIdentifier:@"UsersCellView" owner:self];

    [[cellView textField] setStringValue:[self usersArray][row][@"name"]];
    
    if ([self usersArray][row][@"username"] && [self usersArray][row][@"username"] != [NSNull null]) {
        [[cellView detailTextField] setStringValue:[self usersArray][row][@"username"]];
    }
    else {
        [[cellView detailTextField] setStringValue:@"No username specified"];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self usersArray][row][@"email"]]]]];
    
    if (image) {
        [[cellView imageView] setImage:image];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self usersArray][row][@"email"]]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[cellView imageView] setImage:image];
            });
            
            [Helpers saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self usersArray][row][@"email"]]];
        });
    }
    
    return cellView;
}

- (void)ptrScrollViewDidTriggerRefresh:(id)sender
{
    [self getUsers];
}

@end
