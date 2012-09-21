//
//  ItemCellView.h
//  Jukaela Social
//
//  Created by Josh on 9/5/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@interface ItemCellView : NSTableCellView

-(void)layoutViewsForLargeSize:(BOOL)largeSize animated:(BOOL)animated;

@property (strong, nonatomic) IBOutlet NSTextField *detailTextField;
@property (strong, nonatomic) IBOutlet NSTextField *usernameTextField;
@property (strong, nonatomic) IBOutlet NSTextField *dateTextField;
@property (strong, nonatomic) IBOutlet NSTextField *repostedByTextField;

@end
