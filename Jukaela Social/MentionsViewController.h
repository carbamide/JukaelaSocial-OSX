//
//  MentionsViewController.h
//  Jukaela
//
//  Created by Josh on 9/24/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PullToRefreshScrollView.h"

@interface MentionsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, PullToRefreshDelegate>

@property (strong, nonatomic) NSMutableArray *mentions;

@property (weak) IBOutlet PullToRefreshScrollView *ptrScrollView;
@property (strong, nonatomic) IBOutlet NSTableView *aTableView;

@end
