//
//  Batch.m
//  Beholder
//
//  Created by Danny Espinoza on 7/29/08.
//  Copyright 2008 Mesa Dynamics, LLC. All rights reserved.
//

#import "Batch.h"


@implementation Batch

- (id)initWithTargets:(NSArray*)theTargets action:(SEL)theAction object:(id)theObject poll:(SEL)thePoll interval:(NSTimeInterval)theInterval limit:(unsigned int)theLimit;
{
	if(self = [super init]) {
		targets = [[NSMutableArray alloc] init];
		[targets addObjectsFromArray:theTargets];
		count = [targets count];
		
		batch = nil;
		progress = nil;
		
		action = theAction;
		object = [theObject retain];
		poll = thePoll;
		interval = theInterval;
		limit = theLimit;
		
		timer = nil;
		stopBatch = NO;
	}
	
	return self;
}

- (void)dealloc
{
	[timer invalidate];
	
	[batch release];
	[targets release];
	
	[object release];
	
	[progress setDoubleValue:0.0];
	[progress stopAnimation:self];
	[progress release];
	
	[super dealloc];
}

- (void)start
{
	[self start:nil];
}

- (void)start:(NSProgressIndicator*)theProgress
{
	if(timer == nil && targets) {
		if(theProgress) {
			progress = [theProgress retain];
			[progress startAnimation:self];
		}
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(idle:) userInfo:nil repeats:YES] retain];
	}
}

- (void)stop
{
	if(stopBatch == NO) {
		stopBatch = YES;
		
		if(timer == nil)
			[self release];
	}
}

- (BOOL)isRunning
{
	return (batch && [batch count] ? YES : NO);
}

- (void)idle:(NSTimer*)sender
{
	if(stopBatch) {
		[timer invalidate];
		timer = nil;
		
		[self release];
		return;
	}
	
	if(targets) {
		if(limit == 0) {
			if(batch == nil) {
				batch = targets;
				targets = nil;
			}
		}
		else {
			if(batch == nil)
				batch = [[NSMutableArray alloc] init];
			
			while(targets && [batch count] < limit) {
				id t = [targets objectAtIndex:0];
				[t retain];
				[targets removeObjectAtIndex:0];
				if([t respondsToSelector:poll] && [t respondsToSelector:action]) {
					[batch addObject:t];
					[t performSelector:action withObject:object];
				}	
				[t release];
				
				if([targets count] == 0) {
					[targets release];
					targets = nil;
					break;
				}
			}
		}
	}
	
	if([batch count] == 0) {
		[progress setDoubleValue:0.0];
		[progress stopAnimation:self];
		[progress release];
		progress = nil;
		
		[batch release];
		batch = nil;
	}
	
	if(batch == nil)
		return;

	SInt32 macVersion = 0;
	Gestalt(gestaltSystemVersion, &macVersion);
	
	NSEnumerator* enumerator = [batch objectEnumerator];
	id target;
	
	if(macVersion < 0x1040) {
		NSMutableArray* remove = nil;
		while(target = [enumerator nextObject]) {
			id result = [target performSelector:poll];
			if(result == nil) {
				if(remove == nil)
					remove = [[NSMutableArray alloc] initWithCapacity:1];
				
				[remove addObject:target];
			}
		}
		
		if(remove) {
			enumerator = [remove objectEnumerator];
			while(target = [enumerator nextObject]) {
				[batch removeObject:target];
			}
		}
	}
	else {
		int index = 0;
		NSMutableIndexSet* indexes = nil;
		
		while(target = [enumerator nextObject]) {
			id result = [target performSelector:poll];
			if(result == nil) {
				if(indexes == nil)
					indexes = [NSMutableIndexSet indexSetWithIndex:index];
				else
					[indexes addIndex:index];
			}
			
			index++;
		}
		
		if(indexes)
			[batch removeObjectsAtIndexes:indexes];
	}
	
	if(progress) {
		double v = 1.0 - ((double) ([targets count] + [batch count]) / (double) count);
		[progress setDoubleValue:v*100.0];
	}
}

@end
