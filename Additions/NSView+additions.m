//
//  NSView+additions.m
//  Tea Box
//
//  Created by Max on 13/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSView+additions.h"

@implementation NSView (additions)

- (void)insertView:(NSView *)subview atIndex:(NSInteger)index
{
	NSArray * subviews = self.subviews;
	NSInteger newIndex = MIN(index, subviews.count);
	[self addSubview:subview positioned:NSWindowBelow relativeTo:subviews[newIndex]];
}

@end
