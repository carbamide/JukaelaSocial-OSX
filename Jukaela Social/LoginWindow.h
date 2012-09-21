//
//  LoginWindow.h
//  Jukaela Social
//
//  Created by Josh on 9/5/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FeedViewController.h"

@interface LoginWindow : NSWindowController

@property (strong, nonatomic) IBOutlet NSTextField *usernameTextField;
@property (strong, nonatomic) IBOutlet NSTextField *passwordTextField;
@property (strong, nonatomic) FeedViewController *feedViewController;
@property (strong, nonatomic) IBOutlet NSButton *autoLoginCheck;

-(IBAction)loginAction:(id)sender;
-(IBAction)saveUsernameAndPasswordMaybeMaybeNot:(id)sender;

@end
