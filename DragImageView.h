//
//  DragImageView.h
//  Beholder
//
//  Created by Danny Espinoza on 10/23/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DragImageView : NSImageView {
	NSData* imageData;
	NSString* imagePath;
}

- (NSData*)data;
- (void)setData:(NSData*)data;

- (NSString*)path;
- (void)setPath:(NSString*)path;

- (BOOL)saveAtPath:(NSString*)path;

@end
