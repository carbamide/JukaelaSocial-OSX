//
//  FeedViewController.m
//  Jukaela Social
//
//  Created by Josh on 9/4/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Accounts/Accounts.h>
#import <objc/runtime.h>
#import <Social/Social.h>
#import "AppDelegate.h"
#import "FeedViewController.h"
#import "GravatarHelper.h"
#import "ItemCellView.h"
#import "LoginWindow.h"
#import "NSDate+RailsDateParser.h"
#import "NSString+BackslashEscape.h"
#import "SORelativeDateTransformer.h"

@interface FeedViewController ()
@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccount *twitterAccount;
@property (strong, nonatomic) NSString *stringToSend;
@property (strong, nonatomic) ACAccount *facebookAccount;
@property (nonatomic) BOOL jukaelaSuccess;
@property (nonatomic) BOOL facebookSuccess;
@property (nonatomic) BOOL twitterSuccess;

@end

@implementation FeedViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
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
    
    [[self aTableView] becomeFirstResponder];
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPopover:) name:@"postToJukaela" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getFeed:) name:@"refresh_tables" object:nil];
    
    NSLog(@"inside loadView of FeedViewController");
}

-(void)getFeed:(NSInteger)row
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"start_animation" object:nil];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%i\", \"last\" : \"%i\"}", 0, 20];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            if ([self currentChangeType] == INSERT_POST) {
                [[self aTableView] beginUpdates];
                [[self aTableView] insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0] withAnimation:NSTableViewAnimationEffectFade];
                [[self aTableView] endUpdates];
            }
            else if ([self currentChangeType] == DELETE_POST) {
                [[self aTableView] beginUpdates];
                [[self aTableView] removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationEffectFade];
                [[self aTableView] endUpdates];
            }
            else {
                [[self aTableView] reloadData];
            }
            
            [self setCurrentChangeType:-1];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animation" object:nil];
        }
        else {
            NSLog(@"Error loading feed");
        }
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self theFeed] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    ItemCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
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
    
    [[cellView dateTextField] setStringValue:[[self dateTransformer] transformedValue:tempDate]];
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", [[self applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [self theFeed][row][@"email"]]]]];
    
    if (image) {
        [[cellView imageView] setImage:image];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[GravatarHelper getGravatarURL:[self theFeed][row][@"email"]]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[cellView imageView] setImage:image];
            });
            
            [self saveImage:image withFileName:[NSString stringWithFormat:@"%@", [self theFeed][row][@"email"]]];
        });
    }
    if (row == ([[self theFeed] count] - 1)) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
        
        NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%li\", \"last\" : \"%li\"}", [[self theFeed] count], [[self theFeed] count] + 20];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSMutableArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
                
                NSInteger oldTableViewCount = [[self theFeed] count];
                
                [[self theFeed] addObjectsFromArray:tempArray];
                
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
    
    return cellView;
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
        NSString *path = [[self applicationSupportPath] stringByAppendingPathComponent:[NSString stringWithString:[NSString stringWithFormat:@"%@.png", emailAddress]]];
        
        NSBitmapImageRep *imgRep = [[image representations] objectAtIndex:0];
        
        NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
        
        [data writeToFile:path atomically: NO];
    }
}

-(void)showPopover:(NSRect)rect ofView:(NSView *)aView
{
    [[self popover] showRelativeToRect:rect ofView:aView preferredEdge:NSMaxYEdge];
}

-(IBAction)sendPost:(id)sender
{
    [[self sendButton] setHidden:YES];
    
    [[self postProgressIndicator] setHidden:NO];
    [[self postProgressIndicator] startAnimation:self];
    
    _stringToSend = [[self aTextView] string];
    
    NSLog(@"%@", _stringToSend);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts.json", kSocialURL]];
    
    NSData *tempData = [[[[self aTextView] string] stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setCurrentChangeType:INSERT_POST];
            
            [self getFeed:0];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES) {
                [self postToTwitter:[[self aTextView] string]];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == YES) {
                [self sendFacebookPost:[[self aTextView] string]];
            }
            
            [self setJukaelaSuccess:YES];
            
            [self finishUp];
        }
        else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error posting to Jukaela Social!", nil];
            
            [self setJukaelaSuccess:YES];
            
            [self finishUp];
            
            [alert runModal];
        }
    }];
}

-(void)finishUp
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == YES) {
        if ([self jukaelaSuccess] && [self facebookSuccess] && [self twitterSuccess]) {
            [[self postProgressIndicator] stopAnimation:self];
            [[self postProgressIndicator] setHidden:YES];
            
            [[self sendButton] setHidden:NO];
            
            [[self aTextView] setString:@""];
            
            [[self characterCountLabel] setStringValue:@"140"];
            
            [[self popover] close];
            
            [self resetBOOLs];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == NO) {
        if ([self jukaelaSuccess] && [self twitterSuccess]) {
            [[self postProgressIndicator] stopAnimation:self];
            [[self postProgressIndicator] setHidden:YES];
            
            [[self sendButton] setHidden:NO];
            
            [[self aTextView] setString:@""];
            
            [[self characterCountLabel] setStringValue:@"140"];
            
            [[self popover] close];
            
            [self resetBOOLs];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == NO) {
        if ([self jukaelaSuccess]) {
            [[self postProgressIndicator] stopAnimation:self];
            [[self postProgressIndicator] setHidden:YES];
            
            [[self sendButton] setHidden:NO];
            
            [[self aTextView] setString:@""];
            
            [[self characterCountLabel] setStringValue:@"140"];
            
            [[self popover] close];
            
            [self resetBOOLs];
        }
    }
}

-(void)resetBOOLs
{
    [self setJukaelaSuccess:NO];
    [self setTwitterSuccess:NO];
    [self setFacebookSuccess:NO];
}

-(IBAction)deletePost:(id)sender
{
    NSInteger row = [[self aTableView] clickedRow];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@.json", kSocialURL, [self theFeed][row][@"id"]]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"DELETE"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self setCurrentChangeType:DELETE_POST];
        
        [self getFeed:row];
    }];
}

-(IBAction)repostPost:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"start_animation" object:nil];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts/%@/repost.json", kSocialURL, [self theFeed][[[self aTableView] clickedRow]][@"id"]]];
    
    NSData *tempData = [[[self theFeed][[[self aTableView] clickedRow]][@"content"] stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animation" object:nil];
            
            [self setCurrentChangeType:INSERT_POST];
            
            [self getFeed:0];
        }
        else {
            NSLog(@"Error");
        }
    }];
}

-(IBAction)replyToPost:(id)sender
{
    ItemCellView *tempCell = [[self aTableView] viewAtColumn:0 row:[[self aTableView] clickedRow] makeIfNecessary:NO];
    
    [[self aTextView] setString:[@"@" stringByAppendingString:[[[tempCell usernameTextField] stringValue] stringByAppendingString:@" "]]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"post_to_jukaela" object:nil];
}

-(IBAction)closePopover:(id)sender
{
    [[self aTextView] setString:@""];
    [[self characterCountLabel] setStringValue:@"140"];
    
    [[self popover] close];
}

-(void)postToTwitter:(NSString *)stringToSend
{
    if (![self accountStore]) {
        [self setAccountStore:[[ACAccountStore alloc] init]];
    }
    
    ACAccountType *accountTypeTwitter = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [_accountStore requestAccessToAccountsWithType:accountTypeTwitter options:nil completion:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accounts = [self.accountStore accountsWithAccountType:accountTypeTwitter];
            
            [self setTwitterAccount:accounts[0]];
            
            NSDictionary *parameters = @{@"status" : stringToSend};
            
            NSLog(@"The string to send is %@", parameters);
            
            NSURL *tweetURL = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
            
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:tweetURL parameters:parameters];
            
            [request setAccount:[self twitterAccount]];
            
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                if (responseData) {
                    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                    
                    NSLog(@"The Twitter response was \n%@", jsonData);
                    
                    if (!jsonData[@"error"]) {
                        NSLog(@"Successfully posted to Twitter");
                        
                        [self setTwitterSuccess:YES];
                        
                        [self finishUp];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"twitter_successful" object:nil];
                    }
                    else {
                        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error posting to Twitter!", nil];
                        
                        [self setTwitterSuccess:YES];
                        
                        [self finishUp];
                        
                        [alert runModal];
                    }
                }
                else {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error posting to Twitter!", nil];
                    
                    [self setTwitterSuccess:YES];
                    
                    [self finishUp];
                    
                    [alert runModal];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animating" object:nil];
            }];
        }
        else {
            NSLog(@"Twitter access not granted.");
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

- (void)sendFacebookPost:(NSString *)stringToSend
{
    if (![self accountStore]) {
        [self setAccountStore:[[ACAccountStore alloc] init]];
    }
    
    ACAccountType *accountTypeFacebook = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSDictionary *options = @{ACFacebookAppIdKey:@"493749340639998", ACFacebookAudienceKey: ACFacebookAudienceEveryone, ACFacebookPermissionsKey: @[@"publish_stream", @"publish_actions"]};
    
    [_accountStore requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accounts = [self.accountStore accountsWithAccountType:accountTypeFacebook];
            
            [self setFacebookAccount:[accounts lastObject]];
            
            NSAssert([[[self facebookAccount] credential] oauthToken], @"The OAuth token is invalid", nil);
            
            NSDictionary *parameters = @{@"access_token":[[[self facebookAccount] credential] oauthToken], @"message" : stringToSend};
            
            NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
            
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
            
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *errorDOIS) {
                if (responseData) {
                    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONWritingPrettyPrinted error:nil];
                    
                    NSLog(@"The Facebook response was \n%@", jsonData);
                    
                    if (!jsonData[@"error"]) {
                        NSLog(@"Successfully posted to Facebook");
                        
                        [self setFacebookSuccess:YES];
                        
                        [self finishUp];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_successful" object:nil];
                    }
                    else {
                        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error posting to Facebook!", nil];
                        
                        [self setFacebookSuccess:YES];
                        
                        [self finishUp];
                        
                        [alert runModal];
                    }
                }
                else {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error posting to Facebook!", nil];
                    
                    [self setFacebookSuccess:YES];
                    
                    [self finishUp];
                    
                    [alert runModal];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"stop_animating" object:nil];
            }];
        }
        else {
            NSLog(@"Facebook access not granted.");
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}


-(IBAction)showUser:(id)sender
{
    NSURL *url = nil;
    
    if ([self theFeed][[[self aTableView] clickedRow]][@"original_poster_id"] && [self theFeed][[[self aTableView] clickedRow]][@"original_poster_id"] != [NSNull null]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[[self aTableView] clickedRow]][@"original_poster_id"]]];
    }
    else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, [self theFeed][[[self aTableView] clickedRow]][@"user_id"]]];
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

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    NSString *text = [[self aTextView] string];
    
    int length = [text length] + 1;
    
    [[self characterCountLabel] setStringValue:[NSString stringWithFormat:@"%d",(140 - length)]];
    
    if([replacementString length] == 0) {
        return YES;
    }
    
    return length < 140;
}

- (NSRect)sharingService:(NSSharingService *)sharingService sourceFrameOnScreenForShareItem:(id <NSPasteboardWriting>)item
{
    return [[kAppDelegate window] frame];
}
@end
