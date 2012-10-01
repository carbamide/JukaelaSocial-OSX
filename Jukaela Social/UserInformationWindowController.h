//
//  UserInformationWindowController.h
//  Jukaela Social
//
//  Created by Josh on 9/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UserInformationWindowController : NSWindowController

@property (strong, nonatomic) IBOutlet NSTextField *nameLabel;
@property (strong, nonatomic) IBOutlet NSTextField *usernameLabel;
@property (strong, nonatomic) IBOutlet NSTextField *profileLabel;
@property (strong, nonatomic) IBOutlet NSImageView *userImageView;
@property (strong, nonatomic) NSDictionary *userDict;
@property (strong, nonatomic) IBOutlet NSSegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet NSButton *followOrUnfollow;

-(IBAction)followOrUnfollow:(id)sender;

-(IBAction)segmentedControlAction:(id)sender;

@end
