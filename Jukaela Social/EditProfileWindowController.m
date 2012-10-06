//
//  EditProfileWindowController.m
//  Jukaela
//
//  Created by Josh on 10/5/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "EditProfileWindowController.h"
#import "AppDelegate.h"

@interface EditProfileWindowController ()

@end

@implementation EditProfileWindowController

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
    
    [self getUserInfo:[kAppDelegate userID]];
}

-(IBAction)saveAction:(id)sender
{
    if (![[[self password] stringValue] isEqualToString:[[self passwordConfirmation] stringValue]]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The passwords don't match, yo!", nil];
        
        [alert runModal];
        
        return;
    }
    else if ([[[self password] stringValue] length] == 0 || [[[self passwordConfirmation] stringValue] length]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Why would you want a zero length password?  Really?", nil];
        
        [alert runModal];
        
        return;
    }
    else {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@", kSocialURL, [kAppDelegate userID]]];
        
        NSString *requestString = [NSString stringWithFormat:@"{\"user\": { \"name\":\"%@\",\"username\":\"%@\", \"email\":\"%@\", \"password\":\"%@\", \"password_confirmation\":\"%@\", \"profile\":\"%@\"}}", [[self name] stringValue], [[self username] stringValue], [[self email] stringValue], [[self password] stringValue], [[self passwordConfirmation] stringValue], [[self profile] stringValue]];
        
        NSData *requestData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        [request setHTTPMethod:@"PUT"];
        [request setHTTPBody:requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (data) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Yay!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Saved!", nil];
                
                NSInteger result = [alert runModal];
                
                if (result == NSAlertDefaultReturn) {
                    [[self window] close];
                }
            }
            else {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There has been an error editing your profile!", nil];
                
                [alert runModal];
                
                return;
            }
        }];
    }
}

-(IBAction)cancelAction:(id)sender
{
    [[self window] close];
}

-(void)getUserInfo:(NSString *)userID
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json", kSocialURL, userID]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"aceept"];
    [request setTimeoutInterval:30];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
            
            if (tempDict[@"name"] && tempDict[@"name"] != [NSNull null]) {
                [[self name] setStringValue:tempDict[@"name"]];
            }
            
            if (tempDict[@"username"] && tempDict[@"username"] != [NSNull null]) {
                [[self username] setStringValue:tempDict[@"username"]];
            }
            
            if (tempDict[@"email"] && tempDict[@"email"] != [NSNull null]) {
                [[self email] setStringValue:tempDict[@"email"]];
            }
            
            if (tempDict[@"profile"] && tempDict[@"profile"] != [NSNull null]) {
                [[self profile] setStringValue:tempDict[@"profile"]];
            }
        }
        else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There has been an error downloading your profile information.", nil];
            
            [alert runModal];
        }
    }];
}

@end
