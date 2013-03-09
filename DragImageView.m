//
//  DragImageView.m
//  Beholder
//
//  Created by Danny Espinoza on 10/23/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "DragImageView.h"
#import "Global.h"


@implementation DragImageView

- (void)dealloc
{
	[imageData release];
	[imagePath release];

	[super dealloc];
}

- (void)awakeFromNib
{
	imageData = nil;
	imagePath = nil;
}

- (void)mouseDown:(NSEvent*)theEvent
{
	//if([theEvent clickCount] == 2)
	//	NSBeep();
	
	NSTimeInterval delay = [NSDate timeIntervalSinceReferenceDate] + .1; 

	while([NSDate timeIntervalSinceReferenceDate] < delay) {
		if(!GetCurrentButtonState())
			return;
	}
	
			
	if(imagePath && imageData) {
		NSPoint dragPosition;
		NSRect imageLocation;
	 
		dragPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		dragPosition.x -= 16;
		dragPosition.y -= 16;
		imageLocation.origin = dragPosition;
		imageLocation.size = NSMakeSize(32,32);

		NSString* ext = [imagePath pathExtension];
		if([ext length] == 0)
			ext = @"jpg";

		 [self dragPromisedFilesOfTypes:[NSArray arrayWithObject:ext]
            fromRect:imageLocation
            source:self
            slideBack:YES
            event:theEvent]; 
	}
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	NSString* title = [imagePath lastPathComponent];
	NSString* path = [NSString stringWithFormat:@"%@/%@", [dropDestination path], title];
	
	if([self saveAtPath:path] == YES)
		return [NSArray arrayWithObject:title];
		
	return nil;
}

- (BOOL)saveAtPath:(NSString*)path
{
	Global* global = (Global*) [NSApp delegate];
	if(global)
		return [global saveImageAtPath:path contents:imageData];
		
	return NO;
}

- (NSData*)data
{
	return imageData;
}

- (void)setData:(NSData*)data
{
	[imageData release];
	imageData = [data retain];
}

- (NSString*)path
{
	return imagePath;
}

- (void)setPath:(NSString*)path
{
	[imagePath release];
	imagePath = [path retain];
}

- (BOOL)isFlipped
{
	return YES;
}

@end
