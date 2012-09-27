//
//  UsersCellView.h
//  Jukaela
//
//  Created by Josh on 9/27/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@interface UsersCellView : NSTableCellView

-(void)layoutViewsForLargeSize:(BOOL)largeSize animated:(BOOL)animated;

@property (strong, nonatomic) IBOutlet NSTextField *detailTextField;

@end
