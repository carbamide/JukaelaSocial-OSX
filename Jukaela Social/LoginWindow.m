//
//  LoginWindow.m
//  Jukaela Social
//
//  Created by Josh on 9/5/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginWindow.h"

@interface LoginWindow()
@property (strong, nonatomic) NSDictionary *loginDict;
@end

@implementation LoginWindow

- (id)initWithWindowNibName:(NSString *)windowNibName   
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"username"] && [[NSUserDefaults standardUserDefaults] valueForKey:@"password"]) {
        [[self usernameTextField] setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"]];
        [[self passwordTextField] setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"password"]];
        
        [[self autoLoginCheck] setState:1];
        
        [self loginAction:nil];
    }
}

-(void)awakeFromNib
{
    [super awakeFromNib];
}

-(IBAction)loginAction:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/sessions.json", kSocialURL]];
    
    NSString *requestString = [NSString stringWithFormat:@"{ \"session\": {\"email\" : \"%@\", \"password\" : \"%@\", \"apns\": \"%@\"}}", [[self usernameTextField] stringValue], [[self passwordTextField] stringValue], nil];
    
    NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!data) {
            NSLog(@"An error occured logging in");
            
            return;
        }
        _loginDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
        
        if (_loginDict) {
            NSSound *sound = [NSSound soundNamed:@"loggedIn"];

            [sound play];
                        
            [kAppDelegate setUserID:[NSString stringWithFormat:@"%@", _loginDict[@"id"]]];
            
            [[self feedViewController] setCurrentChangeType:-1];
            [[self feedViewController] getFeed:0];
            
            [[self window] close];
            
            [[kAppDelegate window] makeKeyAndOrderFront:self];
        }
        else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The server is not responding.", nil];
            
            [alert runModal];
        }
        
    }];
}

-(IBAction)saveUsernameAndPasswordMaybeMaybeNot:(id)sender
{
    if ([[self autoLoginCheck] state] == 1) {        
        [[NSUserDefaults standardUserDefaults] setValue:[[self usernameTextField] stringValue] forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setValue:[[self passwordTextField] stringValue] forKey:@"password"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

}
@end
