//
//  EditProfileWindowController.h
//  Jukaela
//
//  Created by Josh on 10/5/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EditProfileWindowController : NSWindowController

@property (strong, nonatomic) IBOutlet NSTextField *name;
@property (strong, nonatomic) IBOutlet NSTextField *username;
@property (strong, nonatomic) IBOutlet NSTextField *email;
@property (strong, nonatomic) IBOutlet NSTextField *password;
@property (strong, nonatomic) IBOutlet NSTextField *passwordConfirmation;
@property (strong, nonatomic) IBOutlet NSTextField *profile;
@property (strong, nonatomic) IBOutlet NSButton *saveButton;
@property (strong, nonatomic) IBOutlet NSButton *cancelButton;

-(IBAction)saveAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
