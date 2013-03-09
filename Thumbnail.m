//
//  Thumbnail.m
//  Beholder
//
//  Created by Danny Espinoza on 10/19/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "Thumbnail.h"


@implementation Thumbnail

- (id)init
{
    self = [super init];
	
    if(self) {
		macVersion = 0;
		Gestalt(gestaltSystemVersion, &macVersion);

		if(macVersion >= 0x1040) {
			NSColor* c1 = [NSColor colorWithCalibratedRed:0.0f green:0.4f blue:1.0f alpha:1.0];
			NSColor* c2 = [NSColor colorWithCalibratedRed:0.0f green:0.2f blue:.50f alpha:1.0];
			gradient = [[CTGradient gradientWithBeginningColor:c1 endingColor:c2] retain];
		}
				
		grid = nil;
	}
	
    return self;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)dealloc
{
	if(macVersion >= 0x1040) {
		[gradient release];
	}
	
	[super dealloc];
}

- (void)setGrid:(Grid*)owner
{
	grid = owner;
}

- (void)setTag:(int)anInt
{
	tag = anInt;
}

- (int)tag
{
	return tag;
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	ImageResult* result = (ImageResult*)[self objectValue];
	
	if(result == nil)
		return;
						
	if([self state] == NSOnState) {	
		/*if(grid && [grid isEqualTo:[[grid window] firstResponder]] == NO) {
			[[NSColor colorWithCalibratedWhite:.80 alpha:1.0] set];
			NSRectFill(frame);
		}
		else*/ {
			if(macVersion >= 0x1040)
				[gradient fillRect:frame angle:90];
			else {
				NSColor* c1 = [NSColor colorWithCalibratedRed:0.0f green:0.4f blue:1.0f alpha:1.0];
				[c1 set];
				NSRectFill(frame);
			}	
		}
	}

	//[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	//[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

	NSRect insetFrame = NSInsetRect(frame, 4.0, 4.0);
	insetFrame.origin.x--;
	insetFrame.origin.y--;
	insetFrame.size.width++;
	insetFrame.size.height++;
	[super drawWithFrame:insetFrame inView:controlView];

	if([result requiresPreview] && [result badgesAreVisible]) {
		NSImage* badge = nil;
		
		if([result preview]) 
			badge = [NSImage imageNamed:@"iconok"];	
		else if([result checkingPreview]) {
			if([result loadingPreview] || [result testedPreview])
				badge = [NSImage imageNamed:@"icongrab"];		
			else
				badge = [NSImage imageNamed:@"iconcheck"];	
		}
		else if([result missingPreview])
			badge = [NSImage imageNamed:@"iconx"];	
			
		if(badge) {
			[badge setFlipped:YES];
			NSRect badgeFrame = NSMakeRect(frame.origin.x + frame.size.width - 32.0, frame.origin.y + frame.size.height - 32.0, 32.0, 32.0);
			[badge drawInRect:badgeFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:([result hasWindow] ? 1.0 : 0.5)];
		}
	}
	
	NSRectEdge mySides[] = { NSMaxYEdge, NSMaxXEdge, };
	float myGrays[] = { .125, .125, };
	NSDrawTiledRects(frame, frame, mySides, myGrays, 2);
}

- (BOOL)isSelectable
{
	return YES;
}

- (BOOL)ignoresMultiClick
{
	return YES;
}

- (void)setState:(int)value
{
	if(value == NSOnState)
		[grid clickThumbnail:self];
	
	[super setState:value];
}

- (NSComparisonResult)sortDefault:(id)otherCell
{
	int t1 = [(ImageResult*)[self image] timestamp];
	int t2 = [(ImageResult*)[otherCell image] timestamp];
	if(t1 == t2)
		return NSOrderedSame;
		
	return (t1 < t2 ? NSOrderedAscending : NSOrderedDescending);
}

- (NSComparisonResult)sortURL:(id)otherCell
{
	NSString* s1 = [(ImageResult*)[self image] imageURL];
	NSString* s2 = [(ImageResult*)[otherCell image] imageURL];
	
	if(s2 == nil)
		return NSOrderedAscending;
		
	if(s1 == nil)
		return NSOrderedDescending;
	
	return [s1 caseInsensitiveCompare:s2]; 
}

- (NSComparisonResult)sortArea:(id)otherCell
{
	int w1 = [(ImageResult*)[self image] imageWidth];
	int w2 = [(ImageResult*)[otherCell image] imageWidth];
	int h1 = [(ImageResult*)[self image] imageHeight];
	int h2 = [(ImageResult*)[otherCell image] imageHeight];
	
	int a1 = w1 * h1;
	int a2 = w2 * h2;
	
	if(a1 == a2)
		return NSOrderedSame;
		
	return (a1 > a2 ? NSOrderedAscending : NSOrderedDescending);
}
 
- (NSComparisonResult)sortWidth:(id)otherCell
{
	int w1 = [(ImageResult*)[self image] imageWidth];
	int w2 = [(ImageResult*)[otherCell image] imageWidth];
	if(w1 == w2)
		return NSOrderedSame;
		
	return (w1 > w2 ? NSOrderedAscending : NSOrderedDescending);
}
 
- (NSComparisonResult)sortHeight:(id)otherCell
{
	int h1 = [(ImageResult*)[self image] imageHeight];
	int h2 = [(ImageResult*)[otherCell image] imageHeight];
	if(h1 == h2)
		return NSOrderedSame;
		
	return (h1 > h2 ? NSOrderedAscending : NSOrderedDescending);
}
 
- (NSComparisonResult)sortFileSize:(id)otherCell
{
	int s1 = [(ImageResult*)[self image] imageSize];
	int s2 = [(ImageResult*)[otherCell image] imageSize];
	if(s1 == s2)
		return NSOrderedSame;
	
	return (s1 > s2 ? NSOrderedAscending : NSOrderedDescending);
}

- (NSComparisonResult)sortHue:(id)otherCell
{
	if([self image] == nil)
		return NSOrderedDescending;
	
	if([otherCell image] == nil)
		return NSOrderedAscending;
	
	NSColor* c1 = [(ImageResult*)[self image] averageColor];
	NSColor* c2 = [(ImageResult*)[otherCell image] averageColor];
	
	return ([c1 hueComponent] > [c2 hueComponent] ? NSOrderedDescending : NSOrderedAscending);
}

- (NSComparisonResult)sortSaturation:(id)otherCell
{
	if([self image] == nil)
		return NSOrderedDescending;
	
	if([otherCell image] == nil)
		return NSOrderedAscending;
	
	NSColor* c1 = [(ImageResult*)[self image] averageColor];
	NSColor* c2 = [(ImageResult*)[otherCell image] averageColor];
	
	return ([c1 saturationComponent] > [c2 saturationComponent] ? NSOrderedAscending : NSOrderedDescending);
}

- (NSComparisonResult)sortLightness:(id)otherCell
{
	if([self image] == nil)
		return NSOrderedDescending;
	
	if([otherCell image] == nil)
		return NSOrderedAscending;
	
	NSColor* c1 = [(ImageResult*)[self image] averageColor];
	NSColor* c2 = [(ImageResult*)[otherCell image] averageColor];
	
	return ([c1 brightnessComponent] > [c2 brightnessComponent] ? NSOrderedAscending : NSOrderedDescending);
}

@end
