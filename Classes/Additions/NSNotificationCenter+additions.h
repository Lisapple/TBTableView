//
//  NSNotificationCenter+additions.h
//  Tea Box
//
//  Created by Max on 03/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@interface NSNotificationCenter (additions)

- (void)addObserverForName:(NSString *)name usingBlock:(void (^)(NSNotification * notification))block;

@end
