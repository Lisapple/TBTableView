//
//  NSIndexPath+addtions.h
//  TableView
//
//  Created by Max on 11/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexPath (additions)

@property (nonatomic, assign) NSUInteger section, row;

+ (NSIndexPath *)indexPathWithSection:(NSUInteger)section row:(NSUInteger)row;

- (id)initWithSection:(NSUInteger)section row:(NSUInteger)row;

@end
