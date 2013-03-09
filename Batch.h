//
//  Batch.h
//  Beholder
//
//  Created by Danny Espinoza on 7/29/08.
//  Copyright 2008 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Batch : NSObject {
	NSMutableArray* targets;
	NSMutableArray* batch;
	
	NSProgressIndicator* progress;
	
	SEL action;
	id object;
	SEL poll;
	NSTimeInterval interval;
	unsigned int limit;
	unsigned int count;

	NSTimer* timer;
	BOOL stopBatch;
}

- (id)initWithTargets:(NSArray*)theTargets action:(SEL)theAction object:(id)theObject poll:(SEL)thePoll interval:(NSTimeInterval)theInterval limit:(unsigned int)theLimit;

- (void)start;
- (void)start:(NSProgressIndicator*)theProgress;
- (void)stop;
- (BOOL)isRunning;

- (void)idle:(NSTimer*)sender;

@end
