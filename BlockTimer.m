//
//  Timer.m
//  FileManagerPlus
//
//  Created by Max on 04/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "BlockTimer.h"

@implementation BlockTimer

@synthesize stopped = _stopped;

+ (void)performBlock:(void (^)(void))block numberOfTimes:(NSInteger)times interval:(NSTimeInterval)interval
{
	[BlockTimer performBlock:block numberOfTimes:times interval:interval completionHandler:NULL];
}

+ (void)performBlock:(void (^)(void))block numberOfTimes:(NSInteger)times interval:(NSTimeInterval)interval completionHandler:(void (^)(void))completionBlock
{
	__block BlockTimer * timer = [[BlockTimer alloc] init];
	[timer performBlock:block afterDelay:(interval / (float)times) repeat:YES];
	
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_current_queue(), ^{
		[timer stop];
		completionBlock();
	});
}

- (void)performBlock:(void (^)(void))block afterDelay:(float)delay repeat:(BOOL)repeat
{
	if (repeat) _stopped = NO;
	
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_current_queue(), ^{
		if (!_stopped) {
			[self performBlock:block afterDelay:delay repeat:NO];
			block();
		}
	});
}

- (void)stop
{
	_stopped = YES;
}

@end
