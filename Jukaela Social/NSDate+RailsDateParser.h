//
//  NSDate+RailsDateParser.h
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (RailsDateParser)

+ (NSDate *)dateWithISO8601String:(NSString *)dateString withFormatter:(NSDateFormatter *)formatter;
+ (NSDate *)dateFromString:(NSString *)dateString withFormat:(NSString *)dateFormat withFormatter:(NSDateFormatter *)formatter;
@end
