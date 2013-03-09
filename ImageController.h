//
//  ImageController.h
//  Beholder
//
//  Created by Danny Espinoza on 10/20/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageController : NSWindowController {
	IBOutlet NSScrollView* scroller;
	IBOutlet NSImageView* image;
	IBOutlet NSProgressIndicator* wait;
	
	IBOutlet NSImageView* icon;
	IBOutlet NSTextField* info;
	IBOutlet NSButton* save;
	IBOutlet NSButton* fit;
	
	NSRect imageFrame;
	
	BOOL fitInWindow;
}

- (void)loadImageInMemory:(NSImage*)preview withData:(NSData*)data fromURL:(NSString*)url;
- (void)failImage;

- (void)prepareForClose;

- (void)actionSave:(id)sender;
- (void)actionFit:(id)sender;

- (void)handleResize:(id)sender;

@end
