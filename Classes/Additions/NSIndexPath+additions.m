//
//  NSIndexPath+addtions.m
//  TableView
//
//  Created by Max on 11/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSIndexPath+additions.h"

@implementation NSIndexPath (additions)

@dynamic section, row;

+ (NSIndexPath *)indexPathWithSection:(NSUInteger)section row:(NSUInteger)row
{
	NSUInteger indexes[2] = { section, row };
	return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

- (instancetype)initWithSection:(NSUInteger)section row:(NSUInteger)row
{
	NSUInteger indexes[2] = { section, row };
	if ((self = [self initWithIndexes:indexes length:2])) { }
	return self;
}

- (NSUInteger)section
{
	return [self indexAtPosition:0];
}

- (NSUInteger)row
{
	return [self indexAtPosition:1];
}

- (NSString *)description
{
	if (self.length == 2) {/* Return the format as "section:1 row:2" etc. */
		return [NSString stringWithFormat:@"section:%lu row:%lu", self.section, self.row];
	} else {/* Return the format as "1.2.3.4" etc. */
		NSMutableString * description = [NSMutableString stringWithCapacity:(2 * self.length)];
		[description appendFormat:@"%lu", [self indexAtPosition:0]];
		for (int i = 1; i < self.length; i++) {
			[description appendFormat:@".%lu", [self indexAtPosition:i]];
		}
		return (NSString *)description;
	}
}

@end
