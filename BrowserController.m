//
//  BrowserController.m
//  Beholder
//
//  Created by Danny Espinoza on 9/29/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "BrowserController.h"
#import "ImageResult.h"

NSMutableArray* gExtensionToMIMEMap = nil;

extern Boolean CheckEventQueueForUserCancel(void);


@implementation BrowserController

- (id)init
{
    self = [super init];
	
    if(self) {
		filterString = nil;
		ignoreString = nil;
		imageSubs = nil;
		
		scrapeString = nil;
		xmlString = nil;
		
		links = nil;
		imageLinks = nil;
		
		images = nil;
		loadedImages = nil;
		linkedImages = nil;
		
		files = nil;
		fileCount = 0;
		resources = nil;
		resourceCount = 0;
		
		session = nil;
		sessionURL = nil;
		sessionData = nil;
		
		queryError = nil;
		
		status = nil;
		
		frames = nil;
	}
	
    return self;
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)awakeFromNib
{
	[browser setHostWindow:nil];
	[browser retain];
	[browser removeFromSuperview];
	
	//[browser retain]; // kludge for cnn.com (multiframe load?)

	// kludge for popups
	//NSPoint farOut = { 8192.0, 8192.0, };
	//[[browser window] setFrameOrigin:farOut];
	
	//if([browser respondsToSelector:@selector(setDrawsBackground:)])
	//	[browser setDrawsBackground:NO];
		
	[[self window] setLevel:NSFloatingWindowLevel];
	
	filterString = nil;
	ignoreString = nil;
	imageSubs = nil;
	
	WebPreferences* prefs = [browser preferences];
	[prefs setPlugInsEnabled: NO];
	[prefs setJavaScriptCanOpenWindowsAutomatically:NO];
	[prefs setJavaEnabled:YES];
	[prefs setLoadsImagesAutomatically:YES];
	[prefs setAllowsAnimatedImageLooping:YES];
	[prefs setPrivateBrowsingEnabled:YES];

	if([prefs respondsToSelector:@selector(setUsesPageCache:)])
		[prefs setUsesPageCache:NO];

	//[[self window] makeKeyAndOrderFront:self];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webReady:) name:WebViewProgressFinishedNotification object:nil];
}

- (void)windowWillClose:(NSNotification*)aNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self setDocument:nil];	
	
	[browser setDownloadDelegate:nil];
	[browser setFrameLoadDelegate:nil];
	[browser setPolicyDelegate:nil];
	[browser setResourceLoadDelegate:nil];
	[browser setUIDelegate:nil];
	
	[self stop];
}

- (void)dealloc
{
	[browser release];
	
	[links release];
	[imageLinks release];
	
	[images release];
	[loadedImages release];
	[linkedImages release];
	
	[filterString release];
	[ignoreString release];
	[imageSubs release];
	
	[scrapeString release];
	[xmlString release];
	
	[queryError release];
	
	[status release];
	
	if(session) {
		[session cancel];
			
		[sessionData release];
		[sessionURL release];
		[session release];
	}
	
	[super dealloc];
}

- (void)setDocument:(MyDocument*)doc
{
	[document release];
	document = [doc retain];
}

- (BOOL)submitFolder:(NSString*)title
{
	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* path = [[title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] substringFromIndex:7];
	if([path hasPrefix:@"localhost"])
		path = [path substringFromIndex:9];
	
	BOOL directory = NO;
	
	if([fm fileExistsAtPath:path isDirectory:&directory] && directory) {
		NSArray* contents = [fm directoryContentsAtPath:path];
		NSEnumerator* enumerator = [contents objectEnumerator];
		NSString* file;
		
		fileCount = 0;
		
		while((file = [enumerator nextObject]) && queryStop == NO) {
			NSString* filePath;
			if([path hasSuffix:@"/"])
				filePath = [NSString stringWithFormat:@"%@%@", path, file];
			else
				filePath = [NSString stringWithFormat:@"%@/%@", path, file];
			
			if([BrowserController URLHasImageExtension:filePath])
				fileCount++;
		}
		
		if(fileCount == 0)
			queryError = [[NSString alloc] initWithString:NSLocalizedString(@"FolderEmpty", @"")];
		else {
			[document lock];

			enumerator = [contents objectEnumerator];
			
			while((file = [enumerator nextObject]) && queryStop == NO) {
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
				
				if(CheckEventQueueForUserCancel()) {
					[self stop];
					return NO;
				}
				
				NSString* filePath;
				if([path hasSuffix:@"/"])
					filePath = [NSString stringWithFormat:@"%@%@", path, file];
				else
					filePath = [NSString stringWithFormat:@"%@/%@", path, file];
				
				if([BrowserController URLHasImageExtension:filePath]) {
					[self performSelectorOnMainThread:@selector(parseFile:) withObject:filePath waitUntilDone:YES];
				}
			}
			
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)submitImage:(NSString*)title
{
	BOOL success = NO;

	@try {
		NSMutableURLRequest* request = [[[NSURLRequest
			requestWithURL:[NSURL URLWithString:[NSString stringWithString:title]]
			cachePolicy:NSURLRequestReturnCacheDataElseLoad
			timeoutInterval:10.0] mutableCopy] autorelease];
			
		[request setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18" forHTTPHeaderField:@"User-Agent"];
				
		session = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		if(session) {
			sessionURL = [[NSString alloc] initWithString:title];
			sessionData = nil;
		
			success = YES;
		}
	}
	
	@catch (NSException* exception) {
	}
	
	return success;
}

+ (BOOL)URLHasImageExtension:(NSString*)url
{
	BOOL loadImage = NO;
	NSString* ext = [url pathExtension];
	
	if(gExtensionToMIMEMap && [gExtensionToMIMEMap containsObject:ext])
		return YES;
	
	if([ext length]) {
		CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)ext, NULL);
		if(uti) {
			CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
			if(mime) {
				if([(NSString*)mime hasPrefix:@"image/"] == YES) {
					if(gExtensionToMIMEMap == nil)
						gExtensionToMIMEMap = [[NSMutableArray alloc] init];
					
					[gExtensionToMIMEMap addObject:[NSString stringWithString:ext]];
						
					loadImage = YES;
				}
				
				CFRelease(mime);
			}
			
			CFRelease(uti);
		}
	}
	
	return loadImage;
}

+ (void)unloadCachedExtensions
{
	[gExtensionToMIMEMap release];
}

- (BOOL)submitQuery:(NSString*)query withFilter:(NSString*)filter ignoring:(NSString*)ignore imageSubs:(NSArray*)subs scrape:(BOOL)scrape
{
	BOOL success = NO;

	queryScraping = scrape;
	queryBrowsing = NO;
	queryStop = NO;
	queryFailed = NO;

	[status release];
	status = [[document statusText] copy];
		
	if(filter == nil && ignore == nil && [query hasPrefix:@"file://"]) {
		if([self submitFolder:query])
			return YES;
		
		if(queryError) {
			[document ready:queryError];
			
			return NO;
		}
		
		if(queryStop)
			return NO;
	}
	
	if(filter == nil && ignore == nil && [BrowserController URLHasImageExtension:query])
		return [self submitImage:query];

	@try {
		[queryError release];
		queryError = nil;

		[scrapeString release];
		scrapeString = nil;

		[xmlString release];
		xmlString = nil;
		
		NSURL* url = nil;
		
		if([query hasPrefix:@"feed://"] || [query hasSuffix:@".xml"]) {
			xmlString = [[NSMutableString alloc] init];
			[xmlString appendString:@"<html><body>"];
			
			if([query hasPrefix:@"feed://"]) {
				NSString* newQuery = [NSString stringWithFormat:@"http%@", [query substringFromIndex:4]];
				url = [NSURL URLWithString:newQuery];
			}
		}
		
		if(url == nil)
			url = [NSURL URLWithString:query];

		readyDepth = 0;
		
		NSMutableURLRequest* request = [[[NSURLRequest
			requestWithURL:url
			cachePolicy:NSURLRequestReloadIgnoringCacheData
			timeoutInterval:10.0] mutableCopy] autorelease];

		[request setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18" forHTTPHeaderField:@"User-Agent"];

		[links release];
		links = [[NSMutableSet alloc] init];
		
		[imageLinks release];
		imageLinks = [[NSMutableSet alloc] init];
		
		[images release];
		images = [[NSMutableSet alloc] init];
		
		[loadedImages release];
		loadedImages = [[NSMutableSet alloc] init];
		
		[linkedImages release];
		linkedImages = [[NSMutableDictionary alloc] init];
		
		[filterString release];
		filterString = [filter copy];

		[ignoreString release];
		ignoreString = [ignore copy];
		
		[imageSubs release];
		imageSubs = [subs copy];

		WebFrame* mainFrame = [browser mainFrame];
		[mainFrame loadRequest:request];
				
		queryBrowsing = YES;
		success = YES;
	}
	
	@catch (NSException* exception) {
	}
	
	if(success == NO)
		[document ready:NSLocalizedString(@"QueryError", @"")];
	
	return success;
}

- (void)stop
{
	if(queryStop)
		return;
	
	queryStop = YES;
	
	if(session) {
		[session cancel];

		[sessionData release];
		sessionData = nil;
		
		[sessionURL release];
		sessionURL = nil;
		
		[session release];
		session = nil;
	}
	else if(queryBrowsing) {
		//[browser stopLoading:self];
		queryBrowsing = NO;
	}
	
	if(files) {
		if(document) {
			int resultCount = [files count];
			
			[document trackResults:files];
			
			[grid retileGrid];
			[grid syncGrid:files];
			[grid refreshGrid];
			
			[document syncResults:resultCount];
		}
		
		[files release];
		files = nil;
	}
	
	if(resources) {
		if(document) {
			int resultCount = [resources count];
			
			[document trackResults:resources];
			
			[grid retileGrid];
			[grid syncGrid:resources];
			[grid refreshGrid];
			
			[document syncResults:resultCount];
		}
		
		[resources release];
		resources = nil;
		
	}
	
	if(document) {
		NSString* searching = NSLocalizedString(@"Searching", @"");

		if([[document statusText] hasPrefix:searching])
			[document ready:NSLocalizedString(@"SearchCancel", @"")];
		else
			[document ready:NSLocalizedString(@"ScrapeCancel", @"")];
	}
}

- (void)webReady:(NSNotification*)aNotification
{
	if(queryFailed)
		goto skip;
	
	if(queryStop)
		return;
		
	frames = [NSMutableArray array];
	
	WebFrame* mainFrame = [browser mainFrame];
	[self iterateFrame:mainFrame];
	
	frames = nil;
	
	if(xmlString) {
		NSMutableString* cleanXML = [xmlString mutableCopy];
		[cleanXML replaceOccurrencesOfString:@"&lt;" withString:@"<" options:0 range:NSMakeRange(0, [cleanXML length])];
		[cleanXML replaceOccurrencesOfString:@"&gt;" withString:@">" options:0 range:NSMakeRange(0, [cleanXML length])];
		[cleanXML replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:0 range:NSMakeRange(0, [cleanXML length])];
		[cleanXML replaceOccurrencesOfString:@"&amp;" withString:@"&" options:0 range:NSMakeRange(0, [cleanXML length])];
		
		scrapeString = cleanXML;
		
		[xmlString release];
		xmlString = nil;
		
		[status release];
		status = [[NSString alloc] initWithFormat:@"%@ %@...", NSLocalizedString(@"Parsing", @""), NSLocalizedString(@"RSS", @"")];
		[document setStatusText:status];
	}
	else if(scrapeString) {
		[status release];
		status = [[NSString alloc] initWithFormat:@"%@ %@...", NSLocalizedString(@"Parsing", @""), NSLocalizedString(@"Directory", @"")];
		[document setStatusText:status];
	}
	else if(queryScraping && [images count]) {
		[images minusSet:loadedImages];
		
		if([images count]) {
			[self scrapeImages];
		}
		
		[images removeAllObjects];
		
		[status release];
		status = [[NSString alloc] initWithFormat:@"%@ %@...", NSLocalizedString(@"Parsing", @""), NSLocalizedString(@"ImageLinks", @"")];
		[document setStatusText:status];
	}
	
	if(scrapeString) {
		[scrapeString appendString:@"</body></html>"];
		
		queryScraping = NO;
		[document unlock];
		
		@try {
			WebFrame* mainFrame = [browser mainFrame];
			WebDataSource* dataSource = [mainFrame dataSource];
			NSMutableURLRequest* request = [dataSource request];
			NSURL* url = [[[request URL] copy] autorelease];

			[mainFrame loadHTMLString:scrapeString baseURL:url];
		}
		
		@catch (NSException* exception) {
		}
		
		[scrapeString release];
		scrapeString = nil;
		
		return;
	}

skip:
	if(readyDepth) {
		--readyDepth;
		return;
	}
	
	queryBrowsing = NO;
	
	if([document isReady] == NO)
		[document ready:queryError];
}

- (void)iterateFrame:(WebFrame*)frame
{
	if(queryStop || [frames containsObject:frame])
		return;
	
	[self parseFrame:frame];
	
	[frames addObject:frame];
	
	NSArray* children = [frame childFrames];
	NSEnumerator* enumerator = [children objectEnumerator];
	WebFrame* child;
	
	while((child = [enumerator nextObject]))
		[self iterateFrame:frame];
}

- (void)parseFile:(NSString*)path
{
	if(queryStop)
		return;
	
	@try {
		NSData* data = [NSData dataWithContentsOfFile:path];
		
		//if([NSImageRep canInitWithData:data] == NO)
		//	return;
		
		ImageResult* result = [[ImageResult alloc] initWithData:data];
		
		if(result) {
			[result calcInfoFromImage];
			
			float aw = [result imageWidth];
			float ah = [result imageHeight];

			if(aw > 192.0 || ah > 192.0) {
				[result setScalesWhenResized:YES];
				
				float w, h;
				if(aw > ah) {
					w = 192.0;
					h = (192.0 * ah) / aw;
				}
				else {
					w = (192.0 * aw) / ah;
					h = 192.0;
				}
				
				NSImage* icon = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
				[icon lockFocus];
				[result drawInRect:NSMakeRect(0, 0, w, h) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
				[icon unlockFocus];			
				
				NSData* thumbnailData = [icon TIFFRepresentation];
				ImageResult* thumbnailResult = [[ImageResult alloc] initWithData:thumbnailData];
				[result release];
				[icon release];
				
				result = thumbnailResult;
				
				[result setImageWidth:aw andHeight:ah];
				
				[result setRequiresPreview:YES];
			}
			else {
				[result setRequiresPreview:NO];
				[result setImageData:data];
			}
			
			NSURL* fileURL = [NSURL fileURLWithPath:path];
			NSString* imageString = [[NSString alloc] initWithString:[fileURL absoluteString]];
			[result setImageURL:imageString];
			[imageString release];
			
			int l = [sessionData length];
			int k = ((l + 1024) - (l % 1024))  / 1024;
			if(k == 0)
				k = 1;
			[result setImageSize:k];
			
			if([grid addResult:result]) {
				[result buildInfoString];
				
				if(files == nil)
					files = [[NSMutableArray alloc] initWithCapacity:0];
				
				[files addObject:result];
				
				NSString* statusString = [NSString stringWithFormat:@"%@%@ %@", status, NSLocalizedString(@"Found", @""), [fileURL absoluteString]];
				[document setStatusText:statusString];
			}
			
			[result release];
		}
	}
	
	@catch (NSException* exception) {
	}
	
	if(fileCount && --fileCount == 0) {
		if(files) {
			int resultCount = [files count];
			
			[document trackResults:files];
			
			[grid retileGrid];
			[grid syncGrid:files];
			[grid refreshGrid];
			
			[files release];
			files = nil;
			
			[document syncResults:resultCount];
		}
		
		[document ready];
	}
}

- (void)parseResource:(NSMutableDictionary*)dictionary
{
	if(queryStop)
		return;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	WebResource* resource = [dictionary objectForKey:@"WebResource"];
	WebDataSource* dataSource = [dictionary objectForKey:@"WebDataSource"];
	
	NSString* url = [[resource URL] absoluteString];
		
	NSData* data = [[[resource data] copy] autorelease];
	ImageResult* result = [[ImageResult alloc] initWithData:data];		
	
	if(result) {
		/*NSURLRequest* request = [NSURLRequest requestWithURL:[resource URL]];
		 if([[NSURLCache sharedURLCache] cachedResponseForRequest:request] == nil) {
		 NSURLResponse* responseToCache = [[NSURLResponse alloc]
		 initWithURL:[resource URL]
		 MIMEType:mime
		 expectedContentLength:[data length]
		 textEncodingName:nil];
		 
		 NSCachedURLResponse* cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:responseToCache data:data];
		 [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];
		 
		 [responseToCache release];
		 [cachedResponse release];
		 }*/
				
		NSString* imageLink = [linkedImages objectForKey:url];
		
		if(queryScraping && [imageLinks count] > 0) {
			if(imageLink) {
				if([imageLinks containsObject:imageLink])
					[loadedImages addObject:[NSString stringWithString:imageLink]];
			}
			else {
				NSString* urlFile = [[url lastPathComponent] stringByDeletingPathExtension];

				// see if an image linked to text is associated with this image (thumbnail strategy)
				NSEnumerator* enumerator = [imageLinks objectEnumerator];
				NSString* link;
				
				while(link = [enumerator nextObject]) {
					NSString* linkFile = [[link lastPathComponent] stringByDeletingPathExtension];
					if([urlFile hasPrefix:linkFile] && [urlFile isNotEqualTo:linkFile]) {
						imageLink = link;					
						[loadedImages addObject:[NSString stringWithString:imageLink]];
						
						break;
					}
				}
			}
		}
		
		if(imageLink)
			[result setLinkURL:imageLink];
		
		NSString* origString = [[NSString alloc] initWithString:url];
		[result setOrigURL:origString];
		[origString release];
		
		BOOL parseSearch = NO;
		if(imageLink && (filterString || ignoreString)) {
			NSString* link = [result linkURL];
			NSRange r = [link rangeOfString:@"images.google.com"];
			if(r.location != NSNotFound) {
				NSString* imageString = [self findStringInside:link from:@"imgurl=" to:@"&"];
				if(imageString && [imageString length])
					[result setImageURL:imageString];
				
				NSString* pageString = [self findStringInside:link from:@"imgrefurl=" to:@"&"];
				if(pageString && [pageString length])
					[result setPageURL:pageString];
				
				int width = 0;
				int height = 0;
				int size = 0;
				
				@try {
					NSString* widthString = [self findStringInside:link from:@"&w=" to:@"&"];
					if(widthString)
						width = [widthString intValue];
					
					NSString* heightString = [self findStringInside:link from:@"&h=" to:@"&"];
					if(heightString)
						height = [heightString intValue];
					
					NSString* sizeString = [self findStringInside:link from:@"&sz=" to:@"&"];
					if(sizeString)
						size = [sizeString intValue];
				}
				
				@catch (NSException* exception) {
				}
				
				[result setImageWidth:width andHeight:height];
				[result setImageSize:size];
				[result setInfoIsApproximate:YES];
				
				parseSearch = YES;
			}
		}
		
		if(parseSearch == NO) {
			[result setRequiresPreview:NO];
			
			[result setImageURL:url];
			
			if(imageSubs) {
				NSMutableString* imageStringCopy = [url mutableCopy];
				NSEnumerator* enumerator = [imageSubs objectEnumerator];
				NSDictionary* sub;
				
				while(sub = [enumerator nextObject]) {
					[self applySubstitutions:sub toString:imageStringCopy];
				}
				
				[result setImageURL:imageStringCopy];
				[result setRequiresPreview:YES];
			}
			
			NSMutableURLRequest* page = [dataSource request];
			[result setPageURL:[[page URL] absoluteString]];
			
			[result calcInfoFromImage];
			
			int l = [data length];
			int k = ((l + 1024) - (l % 1024))  / 1024;
			if(k == 0)
				k = 1;
			[result setImageSize:k];
			
			[result setImageData:data];
		}
		
		if(document && [grid addResult:result]) {
			[result buildInfoString];
			
			if(resources == nil)
				resources = [[NSMutableArray alloc] init];
			
			[resources addObject:result];
			
			if(queryScraping)
				[loadedImages addObject:[NSString stringWithString:[result imageURL]]];
			
			NSString* statusString = [NSString stringWithFormat:@"%@%@ %@", status, NSLocalizedString(@"Found", @""), [result imageURL]];
			[document setStatusText:statusString];
		}
		
		[result release];
	}
	
	if(resourceCount && --resourceCount == 0) {
		if(resources) {
			int resultCount = [resources count];
			
			[document trackResults:resources];
			
			[grid retileGrid];
			[grid syncGrid:resources];
			[grid refreshGrid];
			
			[resources release];
			resources = nil;
			
			[document syncResults:resultCount];
		}
	}
	
	[dictionary release];
	[pool release];
}

- (void)parseFrame:(WebFrame*)frame
{
	if(document == nil)
		return;
	
	WebDataSource* dataSource = [frame dataSource];
	if([[dataSource pageTitle] hasPrefix:@"Index of /"]) {
		[self scrapeFrame:frame];
		return;
	}
	
	NSString* dataString = [[NSString alloc] initWithData:[dataSource data]	encoding:NSUTF8StringEncoding];
	if(xmlString == nil && [dataString hasPrefix:@"<?xml"]) {
		xmlString = [[NSMutableString alloc] init];
		[xmlString appendString:@"<html><body>"];
	}

	if(xmlString) {
		BOOL didFindXML = NO;
		
		NSArray* atomBlocks = [dataString componentsSeparatedByString:@"</atom:content>"];
		if(atomBlocks) {
			NSEnumerator* enumerator = [atomBlocks objectEnumerator];
			NSString* block;
			while(block = [enumerator nextObject]) {
				NSRange r = [block rangeOfString:@"<atom:content"];
				if(r.location != NSNotFound) {
					r.length = [block length] - r.location;
					r = [block rangeOfString:@">" options:0 range:r];
					
					if(r.location != NSNotFound) {
						NSString* html = [block substringFromIndex:r.location];
						[xmlString appendString:html];
						
						didFindXML = YES;
					}
				}
			}
		}
				
		if(didFindXML) {
			[dataString release];
			return;
		}

		atomBlocks = [dataString componentsSeparatedByString:@"</content>"];
		if(atomBlocks) {
			NSEnumerator* enumerator = [atomBlocks objectEnumerator];
			NSString* block;
			while(block = [enumerator nextObject]) {
				NSRange r = [block rangeOfString:@"<content"];
				if(r.location != NSNotFound) {
					r.length = [block length] - r.location;
					r = [block rangeOfString:@">" options:0 range:r];
					
					if(r.location != NSNotFound) {
						NSString* html = [block substringFromIndex:r.location];
						[xmlString appendString:html];
						
						didFindXML = YES;
					}
				}
			}
		}

		if(didFindXML) {
			[dataString release];
			return;
		}

		NSArray* rssBlocks = [dataString componentsSeparatedByString:@"</description>"];
		if(rssBlocks) {
			NSEnumerator* enumerator = [rssBlocks objectEnumerator];
			NSString* block;
			while(block = [enumerator nextObject]) {
				NSRange r = [block rangeOfString:@"<description>"];
				if(r.location != NSNotFound) {
					NSString* html = [block substringFromIndex:r.location];
					[xmlString appendString:html];

					didFindXML = YES;
				}
			}
		}
				
		if(didFindXML == nil) {
			[xmlString release];
			xmlString = nil;
		}
	}

	[dataString release];

	DOMDepth = 0;
	[self iterateDOM:[frame DOMDocument]];

	NSEnumerator* enumerator = [[dataSource subresources] objectEnumerator];
	WebResource* resource;
	
	resourceCount = 0;
	
	while((resource = [enumerator nextObject]) && queryStop == NO) {		
		NSString* mime = [resource MIMEType];
		if([mime hasPrefix:@"image/"]) {
			NSString* url = [[resource URL] absoluteString];
			
			if(filterString) {
				NSRange r = [url rangeOfString:filterString];
				if(r.location == NSNotFound) {
					continue;
				}
			}
			
			if(ignoreString) {
				NSRange r = [url rangeOfString:ignoreString];
				if(r.location != NSNotFound)
					continue;
			}

			resourceCount++;
		}	
	}
	
	if(resourceCount) {
		[document lock];
		
		enumerator = [[dataSource subresources] objectEnumerator];

		while((resource = [enumerator nextObject]) && queryStop == NO) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
			
			if(CheckEventQueueForUserCancel()) {
				[self stop];
				return;
			}
			
			NSString* mime = [resource MIMEType];
			if([mime hasPrefix:@"image/"]) {
				NSString* url = [[resource URL] absoluteString];
				
				if(filterString) {
					NSRange r = [url rangeOfString:filterString];
					if(r.location == NSNotFound) {
						continue;
					}
				}
				
				if(ignoreString) {
					NSRange r = [url rangeOfString:ignoreString];
					if(r.location != NSNotFound)
						continue;
				}
				
				NSMutableDictionary* resourceDictionary = [[NSMutableDictionary alloc] init];
				[resourceDictionary setObject:resource forKey:@"WebResource"];
				[resourceDictionary setObject:dataSource forKey:@"WebDataSource"];
				[self performSelectorOnMainThread:@selector(parseResource:) withObject:resourceDictionary waitUntilDone:YES];
			}
		}
	}
}

- (void)applySubstitutions:(NSDictionary*)sub toString:(NSMutableString*)s
{
	@try {
		NSString* find = [sub objectForKey:@"Find"];
		NSString* replace = [sub objectForKey:@"Replace"];
		NSString* addPrefix = [sub objectForKey:@"AddPrefix"];
		NSString* prefix = [sub objectForKey:@"Prefix"];
		NSString* addSuffix = [sub objectForKey:@"AddSuffix"];
		NSString* suffix = [sub objectForKey:@"Suffix"];
		NSString* eraseTo = [sub objectForKey:@"EraseTo"];
		NSString* eraseFrom = [sub objectForKey:@"EraseFrom"];
		NSNumber* eraseToIndex = [sub objectForKey:@"EraseToIndex"];
		NSNumber* eraseFromIndex = [sub objectForKey:@"EraseFromIndex"];
		
		if(find && replace)
			[s replaceOccurrencesOfString:find withString:replace options:0 range:NSMakeRange(0, [s length])];
		else if(find && eraseTo) {
			NSRange r = [s rangeOfString:find];
			if(r.location != NSNotFound) {
				r.length = r.location;
				r.location = 0;
				[s replaceCharactersInRange:r withString:@""];
			}
		}
		else if(find && eraseFrom) {
			NSRange r = [s rangeOfString:find options:NSBackwardsSearch];
			if(r.location != NSNotFound) {
				r.location += [find length];
				r.length = [s length] - r.location;
				[s replaceCharactersInRange:r withString:@""];
			}
		}
		else if(addPrefix && prefix)
			[s insertString:prefix atIndex:0];
		else if(addSuffix && suffix)
			[s appendString:suffix];
		else if(eraseToIndex) {
			int location = [eraseToIndex intValue];
			if(location < [s length])
				[s replaceCharactersInRange:NSMakeRange(0, location) withString:@""];
		}
		else if(eraseFromIndex) {
			int location = [eraseFromIndex intValue];
			if(location < [s length])
				[s replaceCharactersInRange:NSMakeRange(location, [s length] - location) withString:@""];
		}
	}
	
	@catch (NSException* exception) {
	}							
}

- (void)iterateDOM:(DOMNode*)node
{
	if(queryStop)
		return;
	
	DOMDepth++;
	
	if(node) {
		NSString* nodeID = [node description];
		NSString* linkString = nil;
		NSString* imageString = nil;
				
		if([nodeID hasPrefix:@"<DOMHTMLAnchorElement"]) {
			linkString = [(DOMHTMLAnchorElement*)node href];
			
			if(linkString && [linkString length]) {
				[links addObject:[NSString stringWithString:linkString]];

				if([BrowserController URLHasImageExtension:linkString]) {
					if(queryScraping)
						[images addObject:[NSString stringWithString:linkString]];
					
					[imageLinks addObject:[NSString stringWithString:linkString]];
				}
			}
		}
		else if([nodeID hasPrefix:@"<DOMHTMLImageElement"]) {				
			imageString = [(DOMHTMLImageElement*)node src];
			if(imageString && [imageString length]) {
				// check to see if we're enclosed in an anchor
				DOMNode* parent = [node parentNode];
				NSString* parentID = [parent description];
				if([parentID hasPrefix:@"<DOMHTMLAnchorElement"])
					linkString = [(DOMHTMLAnchorElement*)parent href];
				
				if(queryScraping)
					[images addObject:[NSString stringWithString:imageString]];
								
				if(linkString && [linkString length])
					[linkedImages setObject:[NSString stringWithString:linkString] forKey:[NSString stringWithString:imageString]];
			}
		}
		
		DOMNodeList* list = [node childNodes];
		if(list && DOMDepth < 32) {
			unsigned long i;
			
			for(i = 0; i < [list length]; i++)
				[self iterateDOM:[list item:i]];
		}
	}
	
	DOMDepth--;
}

- (NSString*)findStringInside:(NSString*)script from:(NSString*)pre to:(NSString*)post
{
	NSRange start = [script rangeOfString:pre];

	if(start.location != NSNotFound) {
		start.location += [pre length];
		NSRange end = [[script substringFromIndex:start.location] rangeOfString:post];
		start.length = end.location;
		
		NSString* extracted = [script substringWithRange:start];
		if(extracted && [extracted length]) {
			return [[extracted copy] autorelease];
		}
	}
	
	return nil;
}

- (void)scrapeFrame:(WebFrame *)frame
{
	DOMDepth = 0;
	[self iterateDOM:[frame DOMDocument]];
	
	NSEnumerator* linkEnumerator = [links objectEnumerator];
	NSString* link;
	while(link = [linkEnumerator nextObject]) {
		if([link length]) {
			BOOL loadImage = [BrowserController URLHasImageExtension:link];

			if(loadImage) {
				if(scrapeString == nil) {
					scrapeString = [[NSMutableString alloc] init];
					[scrapeString appendString:@"<html><body>"];
				}
				
				[scrapeString appendString:[NSString stringWithFormat:@"<img src=\"%@\">", link]];
			}
		}
	}
}

- (void)scrapeImages
{
	NSEnumerator* linkEnumerator = [images objectEnumerator];
	NSString* link;
	while(link = [linkEnumerator nextObject]) {
		if([link length]) {			
			if(scrapeString == nil) {
				scrapeString = [[NSMutableString alloc] init];
				[scrapeString appendString:@"<html><body>"];
			}
			
			[scrapeString appendString:[NSString stringWithFormat:@"<img src=\"%@\">", link]];
		}
	}
}

// NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[sessionData release];
	sessionData = nil;
	
	[sessionURL release];
	sessionURL = nil;
	
	[session release];
	session = nil;

	[document ready];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(sessionData == nil)
		sessionData = [[NSMutableData alloc] initWithCapacity:[data length]];
		
	if(sessionData)
		[sessionData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSMutableArray* group = nil;
	
	if(sessionData) {
		ImageResult* result = [[ImageResult alloc] initWithData:sessionData];
		
		if(result) {
			[result setRequiresPreview:NO];
			
			[result setImageURL:sessionURL];
							
			[result calcInfoFromImage];
			
			int l = [sessionData length];
			int k = ((l + 1024) - (l % 1024))  / 1024;
			if(k == 0)
				k = 1;
			[result setImageSize:k];
			
			[result setImageData:sessionData];
	
			if([grid addResult:result]) {
				[result buildInfoString];
			
				if(group == nil)
					group = [[NSMutableArray alloc] init];
					
				[group addObject:result];
			}
			
			[result release];
		}
		
		[sessionData release];
		sessionData = nil;
	}
	
	if(group) {
		int resultCount = [group count];
		
		[document trackResults:group];
		
		[grid retileGrid];
		[grid syncGrid:group];
		[grid refreshGrid];
		
		[group release];
		
		[document syncResults:resultCount];
	}
	
	[sessionURL release];
	sessionURL = nil;
	
	[session release];
	session = nil;

	[document ready];
}

// WebPolicy delegate
- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener
{
	[listener ignore];
}

// WebFrameLoad delegate
- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame
{
	if(document && [frame isEqual:[browser mainFrame]])
		[document setStatusImage:image];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if([error code] == -999)
		return;
	
	//NSLog(@"didFailProvisionalLoadWithError: %@ %@ %@ %d", frame, [frame name], [error localizedDescription], [error code]);
	
	NSString* errorString = [error localizedDescription];
	
	if(document && [frame isEqual:[browser mainFrame]]) {
		if(errorString) {
			[queryError release];
			queryError = [[NSString alloc] initWithString:errorString];
		}
		
		//queryFailed = YES;
	}	
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if([error code] == -999)
		return;

	//NSLog(@"didFailLoadWithError: %@ %@ %@ %d", frame, [frame name], [error localizedDescription], [error code]);
	
	NSString* errorString = [error localizedDescription];

	if(document && [frame isEqual:[browser mainFrame]]) {
		if(errorString) {
			[queryError release];
			queryError = [[NSString alloc] initWithString:errorString];
		}
		
		queryFailed = YES;
	}		
}

- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame
{
	if(document && [frame isEqual:[browser mainFrame]]) {
		readyDepth++;
	}
}

// WebResourceLoad delegate
- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	//NSString* urlString = [[request URL] absoluteString];
	
	//if(queryScraping && [BrowserController URLHasImageExtension:urlString]) {
	//	[images addObject:[NSString stringWithString:urlString]];
	//}	
	
	return [request URL];
}
 
- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource
{
	[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	
	[queryError release];
	queryError = [[NSString alloc] initWithString:NSLocalizedString(@"Protected", @"")];
}
														
@end
