//
//  TMNetworkActivityIndicatorManager.m
//  ZummZumm
//
//  Created by Tony Million on 26/05/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import "TMNetworkActivityIndicatorManager.h"

@interface TMNetworkActivityIndicatorManager ()

@property(assign) dispatch_queue_t      activityQueue;

@end

@implementation TMNetworkActivityIndicatorManager
{
    NSInteger    count_;
}

@synthesize enabled;
@synthesize activityQueue;


+(TMNetworkActivityIndicatorManager*)sharedManager
{
    static TMNetworkActivityIndicatorManager * shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[TMNetworkActivityIndicatorManager alloc] init];
    });
    
    return shared;
}

-(id)init
{
    self = [super init];
    if(self)
    {
        count_ = 0;
        self.activityQueue = dispatch_queue_create("com.zummzumm.activityqueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.activityQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    
    return self;
}

-(void)updateActivityDisplay
{
    return;
}

-(void)incrementActivityCount
{
    dispatch_async(self.activityQueue, ^{
        count_++;
        [self updateActivityDisplay];
    });
}

-(void)decrementActivityCount
{
    dispatch_async(self.activityQueue, ^{
        if(count_ > 0)
            count_--;
        [self updateActivityDisplay];
    });
}


@end
