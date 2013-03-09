//
//  Global.m
//  Beholder
//
//  Created by Danny Espinoza on 11/3/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "Global.h"
#import "BrowserController.h"

@implementation Global

- (id)init
{
	if(self = [super init]) {
		NSMutableDictionary* defaultPrefs = [NSMutableDictionary dictionary];

		[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"AlwaysOn"];
		[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"ShowBadges"];
		[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"ShowBroken"];
		[defaultPrefs setObject:[NSNumber numberWithInt:NSOnState] forKey:@"DetailsState"];
		[defaultPrefs setObject:[NSNumber numberWithFloat:150.0] forKey:@"ThumbnailSize"];
		[defaultPrefs setObject:[NSNumber numberWithInt:0] forKey:@"GoogleSafe"];
		[defaultPrefs setObject:[NSNumber numberWithInt:0] forKey:@"GoogleSize"];
		[defaultPrefs setObject:@"Google" forKey:@"DefaultEngine"];
		[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"ImageBringToFront"];
		[defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"ImageMaximize"];
		[defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:@"ImageCloseOnSave"];
	
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
		[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultPrefs];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[NSApp setDelegate:self];
	
	[theAbout setLevel: NSStatusWindowLevel+1];
 	[theAbout center];
		
	[thePreferences setLevel: NSStatusWindowLevel+1];
 	[thePreferences center];

	[self readPreferences];
}

- (IBAction)handleAbout:(id)sender
{
	[theAbout display];
	[theAbout makeKeyAndOrderFront: sender];	

	[NSApp activateIgnoringOtherApps: YES];
}

- (IBAction)handleShowPlugins:(id)sender
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* libraryFolder = [NSString stringWithFormat:@"%@/Library/Application Support/Beholder", NSHomeDirectory()];
	if([fm fileExistsAtPath:libraryFolder] == NO)
		[fm createDirectoryAtPath:libraryFolder attributes:nil];

	NSString* pluginFolder = [NSString stringWithFormat:@"%@/Plugins", libraryFolder];
	if([fm fileExistsAtPath:pluginFolder] == NO)
		[fm createDirectoryAtPath:pluginFolder attributes:nil];

	[[NSWorkspace sharedWorkspace] openFile:pluginFolder];
}

- (void)readPreferences
{
}

- (void)writePreferences
{
}

// NSApplication delegate
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[NSURLCache sharedURLCache] removeAllCachedResponses];

	[BrowserController unloadCachedExtensions];
	
	[self writePreferences];
}

- (BOOL)saveImageAtPath:(NSString*)path contents:(NSData*)contents
{
    return [[NSFileManager defaultManager] createFileAtPath:path contents:contents attributes:nil];
}

@end
