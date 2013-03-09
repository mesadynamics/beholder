//
//  ImageController.m
//  Beholder
//
//  Created by Danny Espinoza on 10/20/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "ImageController.h"
#import "DragImageView.h"


@implementation ImageController

- (NSString *)windowNibName
{
    return @"Image";
}

- (id)init
{
	if(self = [super init]) {
		fitInWindow = NO;

		[[self window] setShowsResizeIndicator:NO];
		[wait startAnimation:self];
	}
	
	return self;
}

//- (void)mouseEntered:(NSEvent *)theEvent
//{
//	[[NSCursor openHandCursor] set];
//}

//- (void)mouseExited:(NSEvent *)theEvent
//{
//	[[NSCursor arrowCursor] set];
//}

- (void)loadImageInMemory:(NSImage*)preview withData:(NSData*)data fromURL:(NSString*)url
{
	NSWindow* window = [self window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleResize:) name:NSWindowDidResizeNotification object:window];
	
	[wait stopAnimation:self];
	[icon setHidden:NO];
	[info setStringValue:url];
	[save setHidden:NO];
	
	[(DragImageView*)image setData:data];
	[(DragImageView*)image setPath:url];

	BOOL wasKeyWindow = [window isKeyWindow];
	NSWindow* key = [NSApp keyWindow];
		
	imageFrame.size = [preview size];
	imageFrame.origin.x = 0;
	imageFrame.origin.y = 0;	
		
	NSRect contentFrame = imageFrame;
	contentFrame.origin.x = 0.0;
	contentFrame.origin.y = 0.0;
	
	float w = [NSScroller scrollerWidth];	
	contentFrame.size.width += w;
	contentFrame.size.height += (w + 24);
		
	BOOL smallX = NO;
	BOOL smallY = NO;	
		
	if(contentFrame.size.width < 128.0) {
		contentFrame.size.width = 128.0;
		imageFrame.size.width = 128.0 - w;
		smallX = YES;
	}
	
	if(contentFrame.size.height < 152.0) {
		contentFrame.size.height = 152.0;
		imageFrame.size.height = 152.0 - (w + 24);
		smallY = YES;
	}
	
	if(smallX == NO || smallY == NO)
		[window setShowsResizeIndicator:YES];
	else
		[window setShowsResizeIndicator:NO];
	
	if(smallX == YES || smallY == YES)
		[image setImageScaling:NSScaleProportionally];
		
	[image setFrame:imageFrame];
	[image setImage:preview];
		
	NSRect windowFrame = [window frameRectForContentRect:contentFrame];
	
	if([window respondsToSelector:@selector(setPreservesContentDuringLiveResize:)])
		[window setPreservesContentDuringLiveResize:YES];
	
	id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];		
	NSNumber* maximize = [defaults valueForKey:@"ImageMaximize"];
	NSNumber* bringToFront = [defaults valueForKey:@"ImageBringToFront"];

	if(smallX == NO || smallY == NO) {
		[fit setHidden:NO];
		
		[window setMaxSize:windowFrame.size];

		
		if(maximize && [maximize boolValue] == NO) 
			;
		else {
			[window zoom:self];
		
			NSScreen* screen = [window screen];
			NSRect screenFrame = [screen visibleFrame];
			
			windowFrame = [window frame];
			
			BOOL adjustOrigin = NO;
			
			if(windowFrame.origin.x + windowFrame.size.width > screenFrame.origin.x + screenFrame.size.width) {
				windowFrame.origin.x = screenFrame.origin.x;
				adjustOrigin = YES;
			}
			
			if(windowFrame.origin.y + windowFrame.size.height > screenFrame.origin.y + screenFrame.size.height) {
				windowFrame.origin.y = screenFrame.origin.y;
				adjustOrigin = YES;
			}
			
			if(adjustOrigin)
				[window setFrameOrigin:windowFrame.origin];
		}
	}
	else {
		[window setMaxSize:[window minSize]];
	}
	
	if(wasKeyWindow || key == nil) {
		if(bringToFront && [bringToFront boolValue] == NO) 
			;
		else
			[window makeKeyAndOrderFront:self];
	}
	else
		[window orderWindow:NSWindowBelow relativeTo:[key windowNumber]];

	//NSRect trackingFrame = imageFrame;
	//trackingFrame.origin.y += w;
	//[[window contentView] addTrackingRect:trackingFrame owner:self userData:nil assumeInside:NO];
}

- (void)failImage
{
	[[self window] orderOut:self];
	[[self window] setDelegate:nil];
}

- (void)prepareForClose
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[image setImage:nil];
	[(DragImageView*)image setData:nil];
	[(DragImageView*)image setPath:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if([item action] == @selector(actionSave:)) {
		[item setTitle:NSLocalizedString(@"SaveImage", @"")];
		
		if([(DragImageView*)image data])
			return YES;
	}
		
	return NO;
}

- (void)actionSave:(id)sender
{
	NSSavePanel* savePanel = [NSSavePanel savePanel];
	[savePanel setMessage:NSLocalizedString(@"Copyright", @"")];
	
	NSString* title = [[self window] title];
	NSRange openParen = [title rangeOfString:@"("];
	NSRange closeParen = [title rangeOfString:@")" options:NSBackwardsSearch];
	openParen.location++;
	openParen.length = closeParen.location - openParen.location;

	[savePanel beginSheetForDirectory:nil file:[title substringWithRange:openParen] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)actionFit:(id)sender
{
	fitInWindow = !fitInWindow;
	
	if(fitInWindow) {
		[self handleResize:self];
	}
	else {
		[image setFrame:imageFrame];
		[image setNeedsDisplay:YES];
	}
}

- (void)handleResize:(id)sender
{
	if(fitInWindow) {
		NSRect windowFrame = [[self window] contentRectForFrameRect:[[self window] frame]];
		
		float w = [NSScroller scrollerWidth];	
		windowFrame.size.width -= w;
		windowFrame.size.height -= (w + 24);
		
		NSRect newImageFrame = windowFrame;
		
		if(imageFrame.size.height > imageFrame.size.width) {
			float newWidth = (imageFrame.size.width * newImageFrame.size.height) / imageFrame.size.height;
			if(newWidth > newImageFrame.size.width)
				newImageFrame.size.height = (imageFrame.size.height * newImageFrame.size.width) / imageFrame.size.width;
			else
				newImageFrame.size.width = newWidth;
		}
		else {
			float newHeight =  (imageFrame.size.height * newImageFrame.size.width) / imageFrame.size.width;
			if(newHeight > newImageFrame.size.height)
				newImageFrame.size.width = (imageFrame.size.width * newImageFrame.size.height) / imageFrame.size.height;
			else
				newImageFrame.size.height = newHeight;
		}
				
		[image setFrame:newImageFrame];
		[image setNeedsDisplay:YES];
		
		fitInWindow = false;
		windowFrame = [[self window] frameRectForContentRect:newImageFrame];
		NSRect newWindowFrame = [[self window] frame];
		newWindowFrame.size.width = windowFrame.size.width + w;
		newWindowFrame.size.height = windowFrame.size.height + 24 + w;
		[[self window] setFrame:newWindowFrame display:YES animate:NO];
		fitInWindow = true;
	}
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if(returnCode == NSOKButton) {
		[(DragImageView*)image saveAtPath:[sheet filename]];

		id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];		
		NSNumber* closeOnSave = [defaults valueForKey:@"ImageCloseOnSave"];
		if(closeOnSave && [closeOnSave boolValue])
			[self close];
	}
}

@end
