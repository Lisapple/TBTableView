//
//  NSIndexPath+addtions.h
//  TableView
//
//  Created by Max on 11/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@interface NSIndexPath (additions)

@property (nonatomic, assign) NSUInteger section, row;

+ (NSIndexPath *)indexPathWithSection:(NSUInteger)section row:(NSUInteger)row;

- (instancetype)initWithSection:(NSUInteger)section row:(NSUInteger)row;

@end
