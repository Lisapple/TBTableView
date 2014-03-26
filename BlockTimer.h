//
//  Timer.h
//  FileManagerPlus
//
//  Created by Max on 04/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlockTimer : NSObject

@property (nonatomic, assign) BOOL stopped;

+ (void)performBlock:(void (^)(void))block numberOfTimes:(NSInteger)times interval:(NSTimeInterval)interval;
+ (void)performBlock:(void (^)(void))block numberOfTimes:(NSInteger)times interval:(NSTimeInterval)interval completionHandler:(void (^)(void))completionBlock;

- (void)performBlock:(void (^)(void))block afterDelay:(float)delay repeat:(BOOL)repeat;
- (void)stop;

@end
