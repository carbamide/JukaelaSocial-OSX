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
#import "PicCellView.h"
#import "Helpers.h"
#import "SelfPicCellView.h"
#import "SelfItemCellView.h"
#import "NS(Attributed)String+Geometrics.h"
@interface NSAttributedString (HyperLink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
 	
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
 	
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
 	
    // next make the text appear with an underline
    [attrString addAttribute:
 	 NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
 	
    [attrString endEditing];
 	
    return attrString;
}
@end

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
@property (strong, nonatomic) NSData *tempImageData;
@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) NSTimer *refreshTimer;

@end

@implementation FeedViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [[self progressIndicator] startAnimation:self];
    
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
    
    [self setDateFormatter:[[NSDateFormatter alloc] init]];
    [self setDateTransformer:[[SORelativeDateTransformer alloc] init]];
    
    CGRect rect = [[[kAppDelegate window] contentView] frame];
    
    [[self view] setFrame:rect];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPopover:) name:@"postToJukaela" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getFeed:) name:@"refresh_tables" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showImage:) name:@"show_image" object:nil];
    
    NSLog(@"inside loadView of FeedViewController");
    
    [self setRefreshTimer:[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(getFeed:) userInfo:nil repeats:YES]];
    
    [[self refreshTimer] fire];
}

-(void)getFeed:(NSInteger)row
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSInteger last = 20;
    
    if ([[self theFeed] count] > 20) {
        last = [[self theFeed] count];
    }
    
    NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%i\", \"last\" : \"%li\"}", 0, last];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            NSArray *oldArray = [self theFeed];
            
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            NSMutableSet *firstSet = [NSMutableSet setWithArray:[self theFeed]];
            NSMutableSet *secondSet = [NSMutableSet setWithArray:[self theFeed]];
            
            [firstSet unionSet:[NSSet setWithArray:oldArray]];
            [secondSet intersectSet:[NSSet setWithArray:oldArray]];
            
            [firstSet minusSet:secondSet];
            
            NSInteger difference = [firstSet count];
            
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
                
                //the sets are adding one for some reason.  I don't really care, because this works.
                difference -= 1;
                
                if (difference < 0) {
                    difference = 0;
                }
                
                if (difference > 0 && [oldArray count] > 0) {
                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    [notification setTitle:@"New Posts"];
                    
                    if (difference == 1) {
                        [notification setInformativeText:@"There is 1 new post in your feed"];
                    }
                    else if (difference > 1) {
                        [notification setInformativeText:[NSString stringWithFormat:@"There are %li new posts in your feed", difference]];
                    }
                    
                    [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
                    [notification setSoundName:NSUserNotificationDefaultSoundName];
                    
                    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
                    [center scheduleNotification:notification];
                }
            }
            
            [[self progressIndicator] stopAnimation:self];

            [self setCurrentChangeType:-1];
        }
        else {
            [[self progressIndicator] stopAnimation:self];

            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There has been an error loading your feed.  Perhaps the network is down?", nil];
            
            [alert runModal];
        }
    }];
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
        if ([[NSString stringWithFormat:@"%@", [self theFeed][row][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
            cellView = (SelfPicCellView *)[tableView makeViewWithIdentifier:@"SelfPicCellView" owner:self];
        }
        else {
            cellView = (PicCellView *)[tableView makeViewWithIdentifier:@"PicCellView" owner:self];
        }
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            if ([[kAppDelegate externalImageCache] objectForKey:[self theFeed][row][@"image_url"]]) {
                [[cellView externalImage] setImage:[[kAppDelegate externalImageCache] objectForKey:[self theFeed][row][@"image_url"]]];
            }
            else {
                [[cellView externalImage] setImage:nil];
            }
            NSMutableString *tempString = [NSMutableString stringWithString:[self theFeed][row][@"image_url"]];
            
            [tempString insertString:@"s" atIndex:24];
            
            NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:tempString]]];
            
            if (image) {
                [[kAppDelegate externalImageCache] setObject:image forKey:[self theFeed][row][@"image_url"]];
            }
            
            if (![[cellView externalImage] image]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[cellView externalImage] setImage:image];
                });
            }
        });
    }
    else {
        if ([[NSString stringWithFormat:@"%@", [self theFeed][row][@"user_id"]] isEqualToString:[kAppDelegate userID]]) {
            cellView = (SelfItemCellView *)[tableView makeViewWithIdentifier:@"SelfItemCellView" owner:self];
        }
        else {
            cellView = (ItemCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        }
    }
    
    [[cellView textField] setStringValue:[self theFeed][row][@"name"]];
    
    [[cellView detailTextField] setStringValue:[self theFeed][row][@"content"]];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
    [NSAnimationContext endGrouping];
    
    [[cellView usernameTextField] setStringValue:[self theFeed][row][@"username"]];
    
    if ([self theFeed][row][@"repost_user_id"] && [self theFeed][row][@"repost_user_id"] != [NSNull null]) {
        [[cellView repostedByTextField] setStringValue:[NSString stringWithFormat:@"Reposted by %@", [self theFeed][row][@"repost_name"]]];
    }
    else {
        [[cellView repostedByTextField] setStringValue:@""];
    }
    
    NSDate *tempDate = [NSDate dateWithISO8601String:[self theFeed][row][@"created_at"] withFormatter:[self dateFormatter]];
    
    [[cellView dateTextField] setStringValue:[[self dateTransformer] transformedValue:tempDate]];
    
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
        NSLog(@"%f", height + 10);
        
        return height + 10;
    }
}

-(void)showPopover:(NSRect)rect ofView:(NSView *)aView
{
    [[self popover] showRelativeToRect:rect ofView:aView preferredEdge:NSMaxYEdge];
}

- (NSArray *)splitString:(NSString*)str maxCharacters:(NSInteger)maxLength
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *wordArray = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger numberOfWords = [wordArray count];
    NSInteger index = 0;
    NSInteger lengthOfNextWord = 0;
    
	while (index < numberOfWords) {
		NSMutableString *line = [NSMutableString stringWithCapacity:1];
		while ((([line length] + lengthOfNextWord + 1) <= maxLength) && (index < numberOfWords)) {
	        lengthOfNextWord = [[wordArray objectAtIndex:index] length];
	        [line appendString:[wordArray objectAtIndex:index]];
	        index++;
            if (index < numberOfWords) {
                [line appendString:@" "];
            }
	    }
		[tempArray addObject:line];
	}
    return tempArray;
}

-(IBAction)sendPost:(id)sender
{
    [[self sendButton] setHidden:YES];
    
    [[self postProgressIndicator] setHidden:NO];
    [[self postProgressIndicator] startAnimation:self];
    
    if ([kAppDelegate onlyToTwitter]) {
        [self setFacebookSuccess:YES];
        [self setJukaelaSuccess:YES];
        
        if ([[[self aTextView] string] length] > 139) {
            NSArray *tempArray = [self splitString:[[self aTextView] string] maxCharacters:139];
            
            for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                [self postToTwitter:tempString];
            }
        }
        else {
            [self postToTwitter:[[self aTextView] string]];
        }
        return;
    }
    else if ([kAppDelegate onlyToFacebook]) {
        [self setTwitterSuccess:YES];
        [self setJukaelaSuccess:YES];
        
        [self sendFacebookPost:[[self aTextView] string]];
        
        return;
    }
    
    _stringToSend = [[self aTextView] string];
    
    NSLog(@"%@", _stringToSend);
    
    if ([self tempImageData]) {
        [[TMImgurUploader sharedInstance] uploadImage:[[NSImage alloc] initWithData:[self tempImageData]] finishedBlock:^(NSDictionary *result, NSError *error){
            if (error) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There has been an error uploading the image to Jukaela Social", nil];
                
                [alert runModal];
            }
            else {
                [self setUrlString:result[@"upload"][@"links"][@"original"]];
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"confirm_posting"] == YES && ![kAppDelegate onlyToTwitter] && ![kAppDelegate onlyToFacebook] && ![kAppDelegate onlyToJukaela]) {
                    
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Confirm" defaultButton:@"Do it!" alternateButton:@"Just to Jukaela!" otherButton:@"Cancel" informativeTextWithFormat:@"Confirm sending to other services?"];
                    
                    NSInteger result = [alert runModal];
                    
                    if (result == NSAlertDefaultReturn) {
                        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES) {
                            if ([[[self aTextView] string] length] > 139) {
                                NSArray *tempArray = [self splitString:[[self aTextView] string] maxCharacters:139];
                                
                                for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                                    [self postToTwitter:tempString];
                                }
                            }
                            else {
                                [self postToTwitter:[[self aTextView] string]];
                            }
                        }
                        
                        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == YES) {
                            [self sendFacebookPost:[[self aTextView] string]];
                        }
                        
                        [self jukaelaNetworkAction:_stringToSend];
                    }
                    else if (result == NSAlertAlternateReturn) {
                        [self setTwitterSuccess:YES];
                        [self setFacebookSuccess:YES];
                        
                        [self jukaelaNetworkAction:_stringToSend];
                    }
                    else if (result == NSAlertOtherReturn) {
                        [self setTwitterSuccess:YES];
                        [self setFacebookSuccess:YES];
                        [self setJukaelaSuccess:YES];
                        
                        [self finishUp];
                        
                        return;
                    }
                }
                else {
                    if ([kAppDelegate onlyToJukaela]) {
                        [self setTwitterSuccess:YES];
                        [self setFacebookSuccess:YES];
                        
                        [self jukaelaNetworkAction:_stringToSend];
                        
                        return;
                    }
                    
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES) {
                        if ([[[self aTextView] string] length] > 139) {
                            NSArray *tempArray = [self splitString:[[self aTextView] string] maxCharacters:139];
                            
                            for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                                [self postToTwitter:tempString];
                            }
                        }
                        else {
                            [self postToTwitter:[[self aTextView] string]];
                        }
                    }
                    
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == YES) {
                        [self sendFacebookPost:[[self aTextView] string]];
                    }
                    
                    [self jukaelaNetworkAction:_stringToSend];
                }
            }
        }];
    }
    else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"confirm_posting"] == YES && ![kAppDelegate onlyToTwitter] && ![kAppDelegate onlyToFacebook] && ![kAppDelegate onlyToJukaela]) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Confirm" defaultButton:@"Do it!" alternateButton:@"Just to Jukaela!" otherButton:@"Cancel" informativeTextWithFormat:@"Confirm sending to other services?"];
            
            NSInteger result = [alert runModal];
            
            if (result == NSAlertDefaultReturn) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES) {
                    if ([[[self aTextView] string] length] > 139) {
                        NSArray *tempArray = [self splitString:[[self aTextView] string] maxCharacters:139];
                        
                        for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                            [self postToTwitter:tempString];
                        }
                    }
                    else {
                        [self postToTwitter:[[self aTextView] string]];
                    }
                }
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == YES) {
                    [self sendFacebookPost:[[self aTextView] string]];
                }
                
                [self jukaelaNetworkAction:_stringToSend];
            }
            else if (result == NSAlertAlternateReturn) {
                [self setTwitterSuccess:YES];
                [self setFacebookSuccess:YES];
                
                [self jukaelaNetworkAction:_stringToSend];
            }
            else if (result == NSAlertOtherReturn) {
                [self setTwitterSuccess:YES];
                [self setFacebookSuccess:YES];
                [self setJukaelaSuccess:YES];
                
                [self finishUp];
                
                return;
            }
        }
        else {
            if ([kAppDelegate onlyToJukaela]) {
                [self setTwitterSuccess:YES];
                [self setFacebookSuccess:YES];
                
                [self jukaelaNetworkAction:_stringToSend];
                
                return;
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES && ![kAppDelegate onlyToJukaela]) {
                if ([[[self aTextView] string] length] > 139) {
                    NSArray *tempArray = [self splitString:[[self aTextView] string] maxCharacters:139];
                    
                    for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
                        [self postToTwitter:tempString];
                    }
                }
                else {
                    [self postToTwitter:[[self aTextView] string]];
                }
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == YES && ![kAppDelegate onlyToJukaela]) {
                [self sendFacebookPost:[[self aTextView] string]];
            }
            
            [self jukaelaNetworkAction:_stringToSend];
        }
    }
    
}

-(void)jukaelaNetworkAction:(NSString *)stringToSend
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/microposts.json", kSocialURL]];
    
    NSData *tempData = [[stringToSend stringWithSlashEscapes] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *stringToSendAsContent = [[NSString alloc] initWithData:tempData encoding:NSASCIIStringEncoding];
    
    NSString *requestString = nil;
    
    if ([self urlString]) {
        requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@, \"image_url\": \"%@\"}", stringToSendAsContent, [kAppDelegate userID], [self urlString]];
    }
    else {
        requestString = [NSString stringWithFormat:@"{\"content\":\"%@\",\"user_id\":%@}", stringToSendAsContent, [kAppDelegate userID]];
    }
    
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
            [self finishUpAction];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == NO) {
        if ([self jukaelaSuccess] && [self twitterSuccess]) {
            [self finishUpAction];
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_twitter"] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"post_to_facebook"] == NO) {
        if ([self jukaelaSuccess]) {
            [self finishUpAction];
        }
    }
}

-(void)finishUpAction
{
    [[self postProgressIndicator] stopAnimation:self];
    [[self postProgressIndicator] setHidden:YES];
    
    [[self sendButton] setHidden:NO];
    
    [self setUrlString:nil];
    [self setTempImageData:nil];
    
    if ([self popover]) {
        [self performSelectorOnMainThread:@selector(closePopover:) withObject:nil waitUntilDone:YES];
    }
    else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Some sort of craziness is going on with the popover.", nil];
        
        [alert runModal];
    }
    [self setJukaelaSuccess:NO];
    [self setTwitterSuccess:NO];
    [self setFacebookSuccess:NO];
    
    [kAppDelegate setOnlyToJukaela:NO];
    [kAppDelegate setOnlyToTwitter:NO];
    [kAppDelegate setOnlyToFacebook:NO];
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
    [[self aTextView] setString:[@"@" stringByAppendingString:[[self theFeed][[[self aTableView] clickedRow]][@"username"] stringByAppendingString:@" "]]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"post_to_jukaela" object:nil];
}

-(IBAction)closePopover:(id)sender
{
    [[self aTextView] setString:@""];
    [[self characterCountLabel] setStringValue:@"256"];
    
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
            
            if ([self tempImageData]) {
                NSURL *tweetURL = [NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"];
                
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:tweetURL parameters:parameters];
                
                [request setAccount:[self twitterAccount]];
                
                [request addMultipartData:[self tempImageData] withName:@"media[]" type:@"multipart/form-data" filename:@"image.jpg"];
                
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
                }];
            }
            else {
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
                }];
            }
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
    
    NSArray *urlArray = [Helpers arrayOfURLsFromString:stringToSend error:nil];
    
    BOOL urls = NO;
    
    if ([urlArray count] > 0) {
        urls = YES;
    }
    
    [_accountStore requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accounts = [self.accountStore accountsWithAccountType:accountTypeFacebook];
            
            [self setFacebookAccount:[accounts lastObject]];
            
            if ([self tempImageData]) {
                NSAssert([[[self facebookAccount] credential] oauthToken], @"The OAuth token is invalid", nil);
                
                NSDictionary *parameters = @{@"access_token":[[[self facebookAccount] credential] oauthToken], @"message" : stringToSend};
                
                NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/photos"];
                
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                
                [request addMultipartData:[self tempImageData] withName:stringToSend type:@"multipart/form-data" filename:@"image.jpg"];
                
                [request setAccount:[self facebookAccount]];
                
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
                }];
            }
            else {
                NSAssert([[[self facebookAccount] credential] oauthToken], @"The OAuth token is invalid", nil);
                
                NSDictionary *parameters = @{@"access_token":[[[self facebookAccount] credential] oauthToken], @"message" : stringToSend};
                
                NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
                
                if (urls) {
                    feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/links"];
                    
                    parameters = @{@"access_token" : [[[self facebookAccount] credential] oauthToken], @"message" : stringToSend, @"link" : urlArray[0]};
                }
                
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:feedURL parameters:parameters];
                
                [request setAccount:[self facebookAccount]];
                
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
                }];
            }
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

-(void)showImage:(NSNotification *)aNotification
{
    NSInteger indexPathOfTappedRow = [(NSNumber *)[aNotification userInfo][@"indexPath"] intValue];
    
    if ([self theFeed][indexPathOfTappedRow][@"image_url"] && [self theFeed][indexPathOfTappedRow][@"image_url"] != [NSNull null]) {
        NSURL *url = [NSURL URLWithString:[self theFeed][indexPathOfTappedRow][@"image_url"]];
        
        [kAppDelegate setSelectedDownloads:@[url]];
        
        [kAppDelegate setCurrentRowRect:[[self aTableView] rectOfRow:[[self aTableView] clickedRow]]];
        
        if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
            [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
        } else {
            [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
        }
    }
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    NSString *text = [[self aTextView] string];
    
    int length = [text length] + 1;
    
    [[self characterCountLabel] setStringValue:[NSString stringWithFormat:@"%d", (256 - length)]];
    
    if([replacementString length] == 0) {
        return YES;
    }
    
    return length < 256;
}

- (NSRect)sharingService:(NSSharingService *)sharingService sourceFrameOnScreenForShareItem:(id <NSPasteboardWriting>)item
{
    return [[kAppDelegate window] frame];
}

- (void)ptrScrollViewDidTriggerRefresh:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/home.json", kSocialURL]];
    
    NSString *requestString = [NSString stringWithFormat:@"{\"first\" : \"%i\", \"last\" : \"%li\"}", 0, [[self theFeed] count] - 1];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            [self setTheFeed:[NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil]];
            
            [[self aTableView] reloadData];
        }
        else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error refresh your Jukaela Social Posts", nil];
            
            [alert runModal];
        }
    }];
}

-(IBAction)openImage:(id)sender
{
    if (![self tempImageData]) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        
        [openPanel setDelegate:self];
        
        [openPanel beginWithCompletionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSURL *tempURL = [[openPanel URLs] objectAtIndex:0];
                
                [self setTempImageData:[NSData dataWithContentsOfURL:tempURL]];
            }
        }];
    }
    else {
        [self setTempImageData:nil];
        [self setUrlString:nil];
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"Yo!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Removed attached image!", nil];
        
        [alert runModal];
    }
}

-(BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
    NSString *extension = [filename pathExtension];
    
    if (extension == @"" || extension == @"/" || extension == nil || extension == NULL || [extension length] < 1) {
        return TRUE;
    }
    
    NSEnumerator *tagEnumerator = [@[@"png", @"tiff", @"jpg", @"gif", @"jpeg"] objectEnumerator];
    
    NSString *allowedExt = nil;
    
    while ((allowedExt = [tagEnumerator nextObject])) {
        if ([extension caseInsensitiveCompare:allowedExt] == NSOrderedSame) {
            return TRUE;
        }
    }
    
    return FALSE;
}

-(IBAction)deselectRow:(id)sender
{
    [[self aTableView] deselectRow:[[self aTableView] clickedRow]];
}

-(IBAction)shareToFacebook:(id)sender
{
    [self sendFacebookPost:[self theFeed][[[self aTableView] clickedRow]][@"content"]];
}

-(IBAction)shareToTwitter:(id)sender
{    
    if ([[self theFeed][[[self aTableView] clickedRow]][@"content"] length] > 139) {
        NSArray *tempArray = [self splitString:[self theFeed][[[self aTableView] clickedRow]][@"content"] maxCharacters:139];
        
        for (NSString *tempString in [tempArray reverseObjectEnumerator]) {
            [self postToTwitter:tempString];
        }
    }
    else {
        [self postToTwitter:[self theFeed][[[self aTableView] clickedRow]][@"content"]];
    }
}

@end
