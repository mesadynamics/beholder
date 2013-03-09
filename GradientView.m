//
//  GradientView.m
//  Beholder
//
//  Created by Danny Espinoza on 9/29/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "GradientView.h"


@implementation GradientView

- (void)awakeFromNib
{
	macVersion = 0;
	Gestalt(gestaltSystemVersion, &macVersion);

	if(macVersion >= 0x1040) {
		NSColor* c1 = [NSColor colorWithCalibratedWhite:.90 alpha:1.0];
		NSColor* c2 = [NSColor colorWithCalibratedWhite:.95 alpha:1.0];
		gradient = [[CTGradient gradientWithBeginningColor:c1 endingColor:c2] retain];
	}

	[self setNeedsDisplay:YES];
}

- (void)dealloc
{
	if(macVersion >= 0x1040) {
		[gradient release];
	}
		
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	if(macVersion >= 0x1040) {
		//CTGradient *aGradient = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:gradient]];
		[gradient fillRect:[self frame] angle:90];
	}
	else {
		[[NSColor colorWithCalibratedWhite:.90 alpha:1.0] set];
		NSRectFill(rect);
	}
}

- (bool)isOpaque
{
	return NO;
}

@end
