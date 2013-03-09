//
//  BrowserController.h
//  Beholder
//
//  Created by Danny Espinoza on 9/29/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "Grid.h"
#import "MyDocument.h"


@interface BrowserController : NSWindowController {
	IBOutlet WebView* browser;
	IBOutlet Grid* grid;
	MyDocument* document;
	
	NSString* filterString;
	NSString* ignoreString;
	NSArray* imageSubs;
	
	NSMutableString* scrapeString;
	NSMutableString* xmlString;
	
	NSMutableArray* links;
	NSMutableSet* imageLinks;
	NSMutableSet* images;
	NSMutableSet* loadedImages;
	NSMutableDictionary* linkedImages;

	NSMutableArray* files;
	int fileCount;
	NSMutableArray* resources;
	int resourceCount;

	NSURLConnection* session;
	NSString* sessionURL;
	NSMutableData* sessionData;
	
	BOOL queryBrowsing;
	BOOL queryScraping;
	BOOL queryFailed;
	BOOL queryStop;
	NSString* queryError;
	
	NSString* status;
	
	int DOMDepth;
	int readyDepth;
	
	NSMutableArray* frames;
}

- (void)setDocument:(MyDocument*)doc;

+ (BOOL)URLHasImageExtension:(NSString*)url;
+ (void)unloadCachedExtensions;

- (BOOL)submitFolder:(NSString*)title;
- (BOOL)submitImage:(NSString*)title;
- (BOOL)submitQuery:(NSString*)query withFilter:(NSString*)filter ignoring:(NSString*)ignore imageSubs:(NSArray*)subs scrape:(BOOL)scrape;
- (void)stop;

- (void)parseFile:(NSString*)path;
- (void)parseResource:(NSMutableDictionary*)dictionary;

- (void)webReady:(NSNotification*)aNotification;
- (void)iterateFrame:(WebFrame*)frame;
- (void)parseFrame:(WebFrame*)frame;

- (void)applySubstitutions:(NSDictionary*)sub toString:(NSMutableString*)s;

- (void)iterateDOM:(DOMNode*)node;

- (NSString*)findStringInside:(NSString*)script from:(NSString*)pre to:(NSString*)post;
- (void)scrapeFrame:(WebFrame *)frame;
- (void)scrapeImages;

@end


@interface WebPreferences (Private)
- (void)setUsesPageCache:(BOOL)usesPageCache;
@end
