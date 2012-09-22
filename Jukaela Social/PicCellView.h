//
//  PicCellView.h
//  Jukaela
//
//  Created by Josh on 9/22/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@interface PicCellView : NSTableCellView

-(void)layoutViewsForLargeSize:(BOOL)largeSize animated:(BOOL)animated;

@property (strong, nonatomic) IBOutlet NSTextField *detailTextField;
@property (strong, nonatomic) IBOutlet NSTextField *usernameTextField;
@property (strong, nonatomic) IBOutlet NSTextField *dateTextField;
@property (strong, nonatomic) IBOutlet NSTextField *repostedByTextField;
@property (strong, nonatomic) IBOutlet NSImageView *externalImage;

@end
