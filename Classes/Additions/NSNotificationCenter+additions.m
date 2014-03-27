//
//  NSNotificationCenter+additions.m
//  Tea Box
//
//  Created by Max on 03/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSNotificationCenter+additions.h"

@implementation NSNotificationCenter (additions)

- (void)addObserverForName:(NSString *)name usingBlock:(void (^)(NSNotification * notification))block
{
	[self addObserverForName:name
					  object:nil
					   queue:[NSOperationQueue currentQueue]
				  usingBlock:block];
}

@end
