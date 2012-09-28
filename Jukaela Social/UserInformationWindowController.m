//
//  UserInformationWindowController.m
//  Jukaela Social
//
//  Created by Josh on 9/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "GravatarHelper.h"
#import "UserInformationWindowController.h"
#import "Helpers.h"

@interface UserInformationWindowController ()
@property (strong, nonatomic) NSArray *followers;
@property (strong, nonatomic) NSDictionary *following;
@property (strong, nonatomic) NSArray *posts;
@property (strong, nonatomic) NSArray *imFollowing;
@property (strong, nonatomic) NSArray *relationships;
@property (strong, nonatomic) NSNumber *unfollowID;
@end

@implementation UserInformationWindowController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareView) name:@"reload_labels" object:nil];
    
    [self prepareView];
}

-(void)prepareView
{
    if ([self userDict][@"name"] && [self userDict][@"name"] != [NSNull null]) {
        [[self nameLabel] setStringValue:[self userDict][@"name"]];
    }
    else {
        [[self nameLabel] setStringValue:@"No Name Specified"];
    }
    
    if ([self userDict][@"username"] && [self userDict][@"username"] != [NSNull null]) {
        [[self usernameLabel] setStringValue:[self userDict][@"username"]];
    }
    else {
        [[self usernameLabel] setStringValue:@"No Username Specified"];
    }
    
    if ([self userDict][@"name"] && [self userDict][@"profile"] != [NSNull null]) {
        [[self profileLabel] setStringValue:[self userDict][@"profile"]];
    }
    else {
        [[self profileLabel] setStringValue:@"No Profile Specified"];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self userDict][@"email"]]]]];
    
    if (image) {
        [[self userImageView] setImage:image];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self userDict][@"email"]]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self userImageView] setImage:image];
            });
            
            [Helpers saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self userDict][@"email"]]];
        });
    }
    [self performSelector:@selector(setupArraysDispatch) withObject:nil afterDelay:0];
}

-(void)setupArraysDispatch
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if ([[kAppDelegate userID] isEqualToString:[NSString stringWithFormat:@"%@", [self userDict][@"id"]]]) {
            [[self followOrUnfollow] setHidden:YES];
        }
        else {
            [[self followOrUnfollow] setHidden:NO];
        }
        
        [self getFollowers];
        [self getFollowing];
        [self getPosts];
        [self getimFollowing];
    });
}

-(void)setLabelsOfSegmentedControl
{
    [[self segmentedControl] setLabel:[NSString stringWithFormat:@"%ld Followers", [[self followers] count]] forSegment:0];
    [[self segmentedControl] setLabel:[NSString stringWithFormat:@"%ld Following", [[self following] count]] forSegment:1];
    [[self segmentedControl] setLabel:[NSString stringWithFormat:@"%ld Posts", [[self posts] count]] forSegment:2];
}

-(NSString *)applicationSupportPath
{
    NSArray *tempArray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = tempArray[0];
    
    return documentsDirectory;
}

-(void)saveImage:(NSImage *)image withFileName:(NSString *)emailAddress
{
    if (image != nil) {
        NSString *path = [[Helpers applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithString:[NSString stringWithFormat:@"%@.png", emailAddress]]];
        
        NSBitmapImageRep *imgRep = [[image representations] objectAtIndex:0];
        
        NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
        
        [data writeToFile:path atomically: NO];
    }
}

-(void)getPosts
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/show_microposts_for_user.json", kSocialURL, [self userDict][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setPosts:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
        }
        else {
            NSLog(@"Error retrieving posts count");
        }
        [self setLabelsOfSegmentedControl];
    }];
}

-(void)getFollowing
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [self userDict][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setFollowing:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
        }
        else {
            NSLog(@"Error retrieving following count");
        }
        [self setLabelsOfSegmentedControl];
    }];
}

-(void)getimFollowing
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/following.json", kSocialURL, [kAppDelegate userID]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setImFollowing:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil][@"user"]];
            [self setRelationships:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil][@"relationships"]];
            
            [self setupButton];
        }
        else {
            NSLog(@"Error retrieving who I'm following count");
        }
        [self setLabelsOfSegmentedControl];
    }];
}

-(void)getFollowers
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/followers.json", kSocialURL, [self userDict][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setFollowers:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
        }
        else {
            NSLog(@"Error retrieving followers count");
        }
        [self setLabelsOfSegmentedControl];
    }];
}

-(void)setupButton
{
    BOOL following = NO;
                
    for (NSDictionary *dict in [self imFollowing]) {
        if ([dict[@"id"] isEqualToNumber:[self userDict][@"id"]]) {
            following = YES;
        }
    }
    
    for (NSDictionary *dict in [self relationships]) {
        if ([dict[@"followed_id"] isEqualToNumber:[self userDict][@"id"]]) {
            _unfollowID = dict[@"id"];
        }
    }
    
    if (following == YES) {
        NSLog(@"You're already following!");
        
        [[self followOrUnfollow] setTitle:@"Unfollow"];
    }
    else {
        NSLog(@"You're not following yet!");
        
        [[self followOrUnfollow] setTitle:@"Follow"];
    }
}

-(IBAction)followOrUnfollow:(id)sender
{
    NSButton *tempButton = sender;
    
    if ([[tempButton title] isEqualToString:@"Checking follow status..."]) {
        return;
    }
    else if ([[tempButton title] isEqualToString:@"Unfollow"]) {
        [self setImFollowing:nil];
        [self setRelationships:nil];
                
        [self performSelector:@selector(followingAndRelationshipsDispatch) withObject:nil afterDelay:0];
                
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/relationships/%@.json", kSocialURL, _unfollowID]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"DELETE"];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
        
        NSString *requestString = [NSString stringWithFormat:@"{\"commit\" : \"Unfollow\", \"id\" : \"%@\"}", [self userDict][@"id"]];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        [request setHTTPBody:requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Boo!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:@"Unfollowed %@", [[self nameLabel] stringValue]], nil];
            
            [alert runModal];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
        }];
    }
    else if ([[tempButton title] isEqualToString:@"Follow"]) {
        [self setImFollowing:nil];
        [self setRelationships:nil];
                
        [self performSelector:@selector(followingAndRelationshipsDispatch) withObject:nil afterDelay:0];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/relationships.json", kSocialURL]];
        
        NSString *requestString = [NSString stringWithFormat:@"{\"relationship\" : {\"followed_id\" : \"%@\"}, \"commit\" : \"Follow\"}", [self userDict][@"id"]];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {                
                NSAlert *alert = [NSAlert alertWithMessageText:@"Yay!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:@"Followed %@", [[self nameLabel] stringValue]], nil];
                
                [alert runModal];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh_your_tables" object:nil];
            }
            else {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There has been an error! Oh no!", nil];
                
                [alert runModal];
            }
        }];

    }
}

-(void)followingAndRelationshipsDispatch
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self getimFollowing];
    });
}
@end
