//
//  Global.h
//  Beholder
//
//  Created by Danny Espinoza on 11/3/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface Global : NSObject {
    IBOutlet NSWindow* theAbout;
	IBOutlet NSWindow* thePreferences;
	
	SInt32 macVersion;
}

- (IBAction)handleAbout:(id)sender;
- (IBAction)handleShowPlugins:(id)sender;

- (void)readPreferences;
- (void)writePreferences;

- (BOOL)saveImageAtPath:(NSString*)path contents:(NSData*)contents;

@end
