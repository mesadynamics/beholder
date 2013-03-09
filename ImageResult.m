//
//  ImageResult.m
//  Beholder
//
//  Created by Danny Espinoza on 10/19/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "ImageResult.h"
#import "MyDocument.h"
#import "Global.h"


@implementation ImageResult

- (id)initWithData:(NSData*)data
{
	self = [super initWithData:data];
	
	if(self)
		[self commonInit];
		
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
		
	if(self) {
		[self commonInit];
		
		[self initWithData:[decoder decodeDataObject]];

		origURL = [[decoder decodeObject] retain];
		imageURL = [[decoder decodeObject] retain];
		pageURL = [[decoder decodeObject] retain];
		linkURL = [[decoder decodeObject] retain];
		
		infoString = [[decoder decodeObject] retain];
				
		imageWidth = [[decoder decodeObject] intValue];
		imageHeight = [[decoder decodeObject] intValue];
		imageSize = [[decoder decodeObject] intValue];
		timestamp = [[decoder decodeObject] longValue];
	}
	
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	id copy = [super copyWithZone:zone];

	if(copy)
		[copy commonInit];
	
	return copy;
}

- (void)commonInit
{
	static unsigned long gTimestamp = 1;
	timestamp = gTimestamp++;
	
	origURL = nil;
	imageURL = nil;
	pageURL = nil;
	linkURL = nil;
	
	imageWidth = 0;
	imageHeight = 0;
	imageSize = 0;
	infoString = nil;
	averageColor = nil;
	
	infoIsApproximate = NO;
	infoIsActual = NO;
	requiresPreview = YES;	
	testedPreview = NO;
	missingPreview = NO;
	
	imagePreview = nil;
	imageData = nil;
		
	ic = nil;

	session = nil;
	sessionData = nil;
	sessionTest = NO;
	sessionDownload = NO;
	sessionPath = nil;
}

- (void)dealloc
{
	if(ic) {
		[[ic window] setDelegate:nil];
		ic = nil;
	}

	if(session) {
		[sessionPath release];
		sessionPath = nil;
		
		[session cancel];
			
		[sessionData release];
		[session release];
	}
			
	//NSLog(@"%d, %d, %d, %d", [origURL retainCount],  [imageURL retainCount], [pageURL retainCount], [linkURL retainCount]);

	[origURL release];
	[imageURL release];
	[pageURL release];
	[linkURL release];	
	
	//NSLog(@"%d, %d, %d", [imagePreview retainCount],  [imageData retainCount], [infoString retainCount]);

	[imagePreview release];
	[imageData release];
	
	[infoString release];
	[averageColor release];
	
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{	
	[encoder encodeDataObject:[self TIFFRepresentation]];

	[encoder encodeObject:origURL];
	[encoder encodeObject:imageURL];
	[encoder encodeObject:pageURL];
	[encoder encodeObject:linkURL];
	
	[encoder encodeObject:infoString];

	[encoder encodeObject:[NSNumber numberWithInt:imageWidth]];
	[encoder encodeObject:[NSNumber numberWithInt:imageHeight]];
	[encoder encodeObject:[NSNumber numberWithInt:imageSize]];
	[encoder encodeObject:[NSNumber numberWithLong:timestamp]];
}

- (unsigned long)timestamp
{
	return timestamp;
}

- (int)imageWidth
{
	return imageWidth;
}

- (int)imageHeight
{
	return imageHeight;
}

- (int)imageSize
{
	return imageSize;
}

- (NSString*)origURL
{
	return origURL;
}

- (NSString*)imageURL
{
	return imageURL;
}

- (NSString*)pageURL
{
	return pageURL;
}

- (NSString*)linkURL
{
	return linkURL;
}

- (NSString*)infoString
{
	return infoString;
}

- (NSColor*)averageColor
{
	if(averageColor == nil)
		averageColor = [[self calculateAverageColor] retain];
	
	return averageColor;
}

- (NSImage*)preview
{
	return imagePreview;
}

- (NSData*)data
{
	return imageData;
}

- (void)setOrigURL:(NSString*)url
{
	[origURL release];
	origURL = [url retain];
}

- (void)setImageURL:(NSString*)url
{
	[imageURL release];
	imageURL = [url retain];
}

- (void)setPageURL:(NSString*)url
{
	[pageURL release];
	pageURL = [url retain];
}

- (void)setLinkURL:(NSString*)url
{
	[linkURL release];
	linkURL = [url retain];
}

- (void)setImageWidth:(int)width andHeight:(int)height
{
	imageWidth = width;
	imageHeight = height;
}

- (void)setImageSize:(int)size
{
	imageSize = size;
}

- (void)setTimestamp:(unsigned long)time
{
	timestamp = time;
}

- (BOOL)requiresPreview
{
	return requiresPreview;
}

- (void)setRequiresPreview:(BOOL)value
{
	requiresPreview = value;
}

- (void)setInfoIsApproximate:(BOOL)value
{
	infoIsApproximate = value;
}

- (void)setInfoIsActual:(BOOL)value
{
	infoIsActual = value;
}

- (BOOL)testedPreview
{
	return testedPreview;
}

- (BOOL)missingPreview
{
	return missingPreview;
}

- (BOOL)checkingPreview
{
	return (session == nil ? NO : YES);
}

- (BOOL)loadingPreview
{
	return (session && sessionData ? YES : NO);
}

- (BOOL)badgesAreVisible
{
	return [(MyDocument*)[self delegate] badgesAreVisible];
}

- (id)poll
{
	return (session == nil ? nil : self);
}

- (BOOL)hasWindow
{
	return (ic ? YES : NO);
}

- (void)setImagePreview:(NSImage*)preview
{
	[imagePreview release];
	imagePreview = [preview retain];
}

- (void)setImageData:(NSData*)data
{
	[imageData release];
	imageData = [data retain];
}

- (void)calcInfoFromImage
{
	NSSize size = [self size];
	NSImageRep* rep = [self bestRepresentationForDevice:nil];
	
	imageWidth = (int)(rep ? [rep pixelsWide] : size.width);
	imageHeight = (int)(rep ? [rep pixelsHigh] : size.height);
}

- (void)buildInfoString
{	
	[infoString release];

	if(imageWidth || imageHeight) {
		if(imageSize)
			infoString = [NSString stringWithFormat:@"%d x %d %@, %dk", imageWidth, imageHeight, NSLocalizedString(@"Pixels", @""), imageSize];
		else
			infoString = [NSString stringWithFormat:@"%d x %d %@", imageWidth, imageHeight, NSLocalizedString(@"Pixels", @"")];
	}
	else {
		if(imageSize)
			infoString = [NSString stringWithFormat:@"%dk", imageSize];
		else
			infoString = @"";
	}
	
	if(infoIsApproximate == NO && requiresPreview && imagePreview == nil)
		infoString = [NSString stringWithFormat:@"%@ [%@]", infoString, NSLocalizedString(@"Thumbnail", @"")];
	else if(infoIsActual == YES && requiresPreview && imagePreview)
		infoString = [NSString stringWithFormat:@"%@ [%@]", infoString, NSLocalizedString(@"Actual", @"")];
	
	[infoString retain];
}

- (void)verify:(id)sender
{
	if(session == nil) {
		@try {
			NSMutableURLRequest* request = [[[NSURLRequest
											 requestWithURL:[NSURL URLWithString:[NSString stringWithString:imageURL]]
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
											 timeoutInterval:10.0] mutableCopy] autorelease];
			
			[request setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18" forHTTPHeaderField:@"User-Agent"];
			[request setValue:@"close" forHTTPHeaderField:@"Connection"];
			[request setHTTPMethod:@"HEAD"];
			
			sessionTest = YES;
			sessionDownload = NO;
			session = [[NSURLConnection alloc] initWithRequest:request delegate:self];

			[(MyDocument*)[self delegate] didUpdateThumbnail:self];
		}
		
		@catch (NSException* exception) {
		}
	}
}

- (void)downloadToFolder:(NSString*)path
{
	if(sessionPath == nil) {
		sessionPath = [path retain];
		[self download];
	}
}

- (void)download
{
	if(imagePreview == nil && session == nil) {
		@try {
			NSMutableURLRequest* request = [[[NSURLRequest
											 requestWithURL:[NSURL URLWithString:[NSString stringWithString:imageURL]]
											 cachePolicy:NSURLRequestReturnCacheDataElseLoad
											 timeoutInterval:10.0] mutableCopy] autorelease];
			
			[request setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18" forHTTPHeaderField:@"User-Agent"];
			
			sessionTest = NO;
			sessionDownload = (ic ? NO : YES);
			session = [[NSURLConnection alloc] initWithRequest:request delegate:self];

			[(MyDocument*)[self delegate] didUpdateThumbnail:self];
		}
		
		@catch (NSException* exception) {
		}
		
		return;
	}
	
	if(imagePreview && ic == nil)
		[self save];
}

- (void)save
{
	if(imageData == nil)
		return;
	
	NSWindow* window = [(MyDocument*)[self delegate] window];
	if(window == nil)
		return;
	
	NSSavePanel* savePanel = [NSSavePanel savePanel];
	[savePanel setMessage:NSLocalizedString(@"Copyright", @"")];
	[savePanel setTitle:NSLocalizedString(@"SaveImage", @"")];
	
	Global* global = (Global*) [NSApp delegate];

	if(sessionPath) {
		NSString* filePath;
		if([sessionPath hasSuffix:@"/"])
				filePath = [NSString stringWithFormat:@"%@%@", sessionPath, [imageURL lastPathComponent]];
			else
				filePath = [NSString stringWithFormat:@"%@/%@", sessionPath, [imageURL lastPathComponent]];
		
		if(global)
			[global saveImageAtPath:filePath contents:imageData];
		
		return;
	}
	
	if([savePanel runModalForDirectory:nil file:[imageURL lastPathComponent]] == NSFileHandlingPanelOKButton) {
		if(global)
			[global saveImageAtPath:[savePanel filename] contents:imageData];
	}
}

- (void)view
{
	if(ic) {
		[[ic window] makeKeyAndOrderFront:self];
		return;
	}
	
	NSString* title = [imageURL lastPathComponent];
	NSString* escaped = [title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	escaped = [escaped stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString* windowTitle = [NSString stringWithFormat:@"%@ (%@)",  NSLocalizedString(@"ImageWindow", @""), escaped];

	ic = [[ImageController alloc] init];

	if(imagePreview == nil) {
		if(requiresPreview) {
			[self download];
		}
		else {
			if(imageData) {
				imagePreview = [[NSImage alloc] initWithData:imageData];

				NSSize trueSize;
				trueSize.width = imageWidth;
				trueSize.height = imageHeight;
				
				if(NSEqualSizes([imagePreview size], trueSize) == NO) {
					[imagePreview setScalesWhenResized:YES];
					[imagePreview setSize:trueSize];
				}
			}
			else
				imagePreview = [self copy];
		}
	}

	[[ic window] setDelegate:self];
	[[ic window] setTitle:windowTitle];
		
	if(imagePreview)	
		[ic loadImageInMemory:imagePreview withData:imageData fromURL:imageURL];

	MyDocument* doc = (MyDocument*)[self delegate];
	NSWindow* win = [doc window];
	NSRect winFrame = [win frame];
	NSRect icFrame = [[ic window] frame];
	icFrame.origin.x = winFrame.origin.x + 8;
	icFrame.origin.y = winFrame.origin.y + (winFrame.size.height - icFrame.size.height) - 30;
	[[ic window] setFrame:icFrame display:NO];

	id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];		
	NSNumber* bringToFront = [defaults valueForKey:@"ImageBringToFront"];
	if(bringToFront && [bringToFront boolValue] == NO)
		[[ic window] orderWindow:NSWindowBelow relativeTo:[[doc window] windowNumber]];
	else
		[[ic window] makeKeyAndOrderFront:self];
}

// NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if(sessionTest == YES && sessionDownload == NO) {
		if(response && [response respondsToSelector:@selector(statusCode)] && [(NSHTTPURLResponse*)response statusCode] == 404) {
			missingPreview = YES;
			
			MyDocument* doc = (MyDocument*)[self delegate];
			[doc resolveBroken];
			[doc didUpdateThumbnail:self];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if(ic) {
		[ic failImage];
		[ic prepareForClose];
		[ic release];
		ic = nil;
	}
	else {
		[sessionPath release];
		sessionPath = nil;

		[sessionData release];
		sessionData = nil;
			
		[session release];
		session = nil;
	}

	missingPreview = YES;
	
	MyDocument* doc = (MyDocument*)[self delegate];
	[doc resolveBroken];
	[doc didUpdateThumbnail:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(sessionData == nil) {
		sessionData = [[NSMutableData alloc] initWithCapacity:[data length]];
		
		if(sessionTest == NO)
			[(MyDocument*)[self delegate] didUpdateThumbnail:self];
	}
	
	if(sessionData)
		[sessionData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(sessionTest) {
		testedPreview = YES;
		[(MyDocument*)[self delegate] didUpdateThumbnail:self];
		
		[sessionPath release];
		sessionPath = nil;

		[sessionData release];
		sessionData = nil;
		
		[session release];
		session = nil;
		
		return;
	}

	if(sessionDownload == NO && ic == nil) {
		[sessionPath release];
		sessionPath = nil;

		[sessionData release];
		sessionData = nil;
				
		[session release];
		session = nil;

		return;
	}
	
	MyDocument* doc = (MyDocument*)[self delegate];
	
	if(sessionData) {
		imagePreview = [[NSImage alloc] initWithData:sessionData];
		if(imagePreview) {
			NSSize size = [imagePreview size];
			NSImageRep* rep = [imagePreview bestRepresentationForDevice:nil];
			
			imageWidth = (int)(rep ? [rep pixelsWide] : size.width);
			imageHeight = (int)(rep ? [rep pixelsHigh] : size.height);

			NSSize trueSize;
			trueSize.width = imageWidth;
			trueSize.height = imageHeight;

			int l = [sessionData length];
			int k = ((l + 1024) - (l % 1024))  / 1024;
			if(k == 0)
				k = 1;
			[self setImageSize:k];

			[self setInfoIsActual:YES];
			[self buildInfoString];
			
			if(NSEqualSizes([imagePreview size], trueSize) == NO) {
				[imagePreview setScalesWhenResized:YES];
				[imagePreview setSize:trueSize];
			}

			imageData = [sessionData retain];
			
			if(ic)
				[ic loadImageInMemory:imagePreview withData:imageData fromURL:imageURL];
			
			missingPreview = NO;
			[doc didUpdatePreview:self];
		}
		else {
			[sessionData release];
			
			[ic failImage];
			[ic prepareForClose];
			[ic release];
			ic = nil;
			
			missingPreview = YES;
			[doc resolveBroken];
		}
		
		sessionData = nil;
		
		[doc didUpdateThumbnail:self];
		
		if(imagePreview && ic == nil)
			[self save];		
	}
	else {
		if(ic) {
			[ic failImage];
			[ic prepareForClose];
			[ic release];
			ic = nil;
		}
		
		missingPreview = YES;

		[doc resolveBroken];
		[doc didUpdateThumbnail:self];
	}

	[sessionPath release];
	sessionPath = nil;

	[session release];
	session = nil;
}

// NSWindow delegate
- (void)windowWillClose:(NSNotification *)aNotification
{
	[ic prepareForClose];
	[ic release];
	ic = nil;

	if(session) {
		[sessionPath release];
		sessionPath = nil;
		
		[session cancel];
		
		[sessionData release];
		sessionData = nil;
				
		[session release];
		session = nil;
	}
	
	[(MyDocument*)[self delegate] didUpdateThumbnail:self];
}

- (NSColor*)calculateAverageColor
{
	NSImageRep* rep = [self bestRepresentationForDevice:nil];
	unsigned long h = [rep pixelsHigh];
	unsigned long w = [rep pixelsWide];
	
	NSBitmapImageRep* bitmap = [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
	long bpp = [bitmap bitsPerPixel];
	
	if(bpp == 24 || bpp == 32) {
		unsigned long r = 0;
		unsigned long g = 0;
		unsigned long b = 0;
		unsigned long a = 0;
		unsigned long c = 0;
		
		unsigned long bytesPerScanLine = [bitmap bytesPerRow];
		unsigned char* p = [bitmap bitmapData];
		
		unsigned long i = 0;
		while(i < h) {
			unsigned long j = 0;
			unsigned char* p2 = p;
			
			while(j < w) {
				r += *p2; p2++;
				g += *p2; p2++;
				b += *p2; p2++;
				
				if(bpp == 32) {
					a += *p2; p2++;
				}
				
				c++;
				j++;
			}
			
			p += bytesPerScanLine;
			i++;
			p += bytesPerScanLine;
			i++;
		}
		
		r = r / c;
		g = g / c;
		b = b / c;
		
		NSColor* rgb = [NSColor colorWithCalibratedRed:(float)r/255.0 green:(float)g/255.0 blue:(float)b/255.0 alpha:1.0];
		NSColor* hsl = [rgb colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		return hsl;
	}
	
	return [NSColor blackColor];
}

@end
