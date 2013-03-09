//
//  MyDocument.m
//  Beholder
//
//  Created by Danny Espinoza on 9/29/06.
//  Copyright 2006, Mesa Dynamics, LLC. All rights reserved.
//

#import "MyDocument.h"
#import "SearchController.h"
#import "BrowserController.h"
#import "Grid.h"
#import "Thumbnail.h"
#import "Global.h"

enum {
	sortDefault = 0,
	sortURL = 100,
	sortArea = 200,
	sortWidth = 300,
	sortHeight = 400,
	sortFileSize = 500,
	sortHue = 600,
	sortSaturation = 700,
	sortLightness = 800
};

enum {
	engineNone = -1,
	engineWeb = 0,
	engineFolder = 1,
	engineGoogle = 3,
	enginePhotobucket = 4,
	engineFlickr = 5,
	engineSeparator = 6
};


@implementation MyDocument

- (id)init
{
    self = [super init];
	
    if(self) {
		window = nil;
		lastSearch = nil;
		saveSearch = nil;
		searchLocked = NO;
		
		loadFolder = nil;
		load = nil;
		loadQuery = nil;
		loadTitle = nil;
		loadMessage = nil;
		loadEngineName = nil;
		loadSafe = -1;
		loadSize = -1;
		loadLastSearch = nil;
		loadMoreEngineName = nil;
		loadHistory = nil;
		loadLocked = NO;
		
		moreValue = 0;
		moreEngine = engineNone;
		moreSafe = -1;
		moreSize = -1;
		
		selectedResult = nil;
		
		NSMutableDictionary* google = [NSMutableDictionary dictionaryWithCapacity:0];
		[google setObject:@"Google" forKey:@"Title"];
		[google setObject:@"images.google.com" forKey:@"Root"];
		[google setObject:@"images?q=" forKey:@"Filter"];
		[google setObject:[NSNumber numberWithInt:20] forKey:@"MoreOffset"];
			[google setObject:@"http://images.google.com/images?q=%@&hl=%@&btnG=Search+Images%@%@" forKey:@"GoogleQuery"];
			[google setObject:@"http://images.google.com/images?q=%@&svnum=10&hl=%@&lr=&start=%d&sa=N&ndsp=20%@%@" forKey:@"GoogleMoreQuery"];
		[google setObject:[NSNumber numberWithInt:200807300] forKey:@"Timestamp"];

		NSMutableDictionary* photobucket = [NSMutableDictionary dictionaryWithCapacity:0];
		[photobucket setObject:@"Photobucket" forKey:@"Title"];
		[photobucket setObject:@"photobucket.com" forKey:@"Root"];
		[photobucket setObject:@"/albums/" forKey:@"Filter"];
		[photobucket setObject:@" " forKey:@"Separator"];
		[photobucket setObject:@"http://photobucket.com/images/%@/" forKey:@"Query"];
		[photobucket setObject:@"?page=%d&userinit=true&source=homepage" forKey:@"More"];
		[photobucket setObject:[NSNumber numberWithInt:2] forKey:@"MoreStart"];
		NSMutableDictionary* photobucketSub1 = [NSMutableDictionary dictionaryWithCapacity:0];
			[photobucketSub1 setObject:@"//t" forKey:@"Find"];
			[photobucketSub1 setObject:@"//i" forKey:@"Replace"];
		NSMutableDictionary* photobucketSub2 = [NSMutableDictionary dictionaryWithCapacity:0];
			[photobucketSub2 setObject:@"/th_" forKey:@"Find"];
			[photobucketSub2 setObject:@"/" forKey:@"Replace"];
		[photobucket setObject:[NSMutableArray arrayWithObjects:photobucketSub1, photobucketSub2, nil] forKey:@"ImageSubs"];
		[photobucket setObject:[NSNumber numberWithInt:200807300] forKey:@"Timestamp"];
		
		NSMutableDictionary* flickr = [NSMutableDictionary dictionaryWithCapacity:0];
		[flickr setObject:@"Flickr" forKey:@"Title"];
		[flickr setObject:@"www.flickr.com" forKey:@"Root"];
		[flickr setObject:@"_t." forKey:@"Filter"];
		[flickr setObject:@"http://www.flickr.com/search/?q=%@" forKey:@"Query"];
		[flickr setObject:@"&page=%d" forKey:@"More"];
		[flickr setObject:[NSNumber numberWithInt:2] forKey:@"MoreStart"];
		NSMutableDictionary* flickrSub = [NSMutableDictionary dictionaryWithCapacity:0];
			[flickrSub setObject:@"_t." forKey:@"Find"];
			[flickrSub setObject:@"." forKey:@"Replace"];
		[flickr setObject:[NSMutableArray arrayWithObject:flickrSub] forKey:@"ImageSubs"];
		[flickr setObject:[NSNumber numberWithInt:200911010] forKey:@"Timestamp"];

		engineList = [[NSMutableArray arrayWithObjects:google, photobucket, flickr, nil] retain];

		NSFileManager* fm = [NSFileManager defaultManager];
		NSString* libraryFolder = [NSString stringWithFormat:@"%@/Library/Application Support/Beholder", NSHomeDirectory()];
		if([fm fileExistsAtPath:libraryFolder] == NO) {
			[fm createDirectoryAtPath:libraryFolder attributes:nil];

			NSString* pluginFolder = [NSString stringWithFormat:@"%@/Plugins", libraryFolder];

			NSString* frameworks = [NSString stringWithFormat:@"%@/Plugins", [[NSBundle mainBundle] resourcePath]];
			[fm copyPath:frameworks toPath:pluginFolder handler:nil];

			/*
			// Picasa (to export as plugin)
			NSMutableDictionary* picasa = [NSMutableDictionary dictionaryWithCapacity:0];
			[picasa setObject:@"Picasa" forKey:@"Title"];
			[picasa setObject:@"picasaweb.google.com" forKey:@"Root"];
			[picasa setObject:@"/s144/" forKey:@"Filter"];
			[picasa setObject:@"http://picasaweb.google.com/lh/searchbrowse?q=%@&uname=&psc=G&filter=1#0+1" forKey:@"Query"];
			[picasa setObject:@"http://picasaweb.google.com/lh/searchbrowse?q=%@&uname=&psc=G&filter=1#%d+1" forKey:@"MoreQuery"];
			[picasa setObject:[NSNumber numberWithInt:20] forKey:@"MoreOffset"];
			NSMutableDictionary* picasaSub = [NSMutableDictionary dictionaryWithCapacity:0];
				[picasaSub setObject:@"/s144/" forKey:@"Find"];
				[picasaSub setObject:@"/" forKey:@"Replace"];
			[picasa setObject:[NSMutableArray arrayWithObject:picasaSub] forKey:@"ImageSubs"];
			[picasa setObject:@"200807300" forKey:@"Timestamp"];
			[picasa setObject:[NSNumber numberWithInt:200807300] forKey:@"Timestamp"];

			NSString* error = nil;
			NSData* data = [NSPropertyListSerialization dataFromPropertyList:picasa	format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
			NSString* path = [NSString stringWithFormat:@"%@/Picasa.plist", pluginFolder];
			[data writeToFile:path atomically:YES];
			*/
		}
		
		batch = nil;
	}
	
    return self;
}

- (void)dealloc
{
	[batch stop];
	
	[lastSearch release];
	[saveSearch release];
	[engineList release];
	
	[super dealloc];
}

//- (NSString *)windowNibName
//{
//    return @"MyDocument";
//}

- (NSString *)fileType
{
	return @"srch";
}

- (void)makeWindowControllers
{
    SearchController* controller = [[SearchController alloc] initWithWindowNibName:@"MyDocument" owner:self];
    [self addWindowController:controller];
    [controller release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	[super windowControllerDidLoadNib:aController];

	window = [aController window];
	[window setDelegate:self];
	
	NSRect frame = [window frame];
	frame.size.width = 932.0;
	frame.size.height = 699.0;
	
	NSNumber* savedWidth = (NSNumber*) CFPreferencesCopyAppValue(CFSTR("SearchWidth"), kCFPreferencesCurrentApplication);
	if(savedWidth) {
		frame.size.width = [savedWidth floatValue];
		CFRelease(savedWidth);
	}

	NSNumber* savedHeight = (NSNumber*) CFPreferencesCopyAppValue(CFSTR("SearchHeight"), kCFPreferencesCurrentApplication);
	if(savedHeight) {
		frame.size.height = [savedHeight floatValue];
		CFRelease(savedHeight);
	}
	
	[window setFrame:frame display:NO];
	
	NSImage* footerImage = [NSImage imageNamed:@"border"];	
	[footer setImageScaling:NSScaleToFit];
	[footer setImage:footerImage];

	NSImage* headerImage = [NSImage imageNamed:@"header"];
	[header setImageScaling:NSScaleToFit];
	[header setImage:headerImage];
	
	[info setDataSource:self];
	
	NSTableColumn* titleColumn = [info tableColumnWithIdentifier:@"title"];
	[titleColumn setWidth:48];
	NSTableColumn* dataColumn = [info tableColumnWithIdentifier:@"data"];
	[[dataColumn dataCell] setWraps:YES];
	
	[searchField setDelegate:self];
	
	[(Grid*)grid setDocument:self];
	
	SInt32 macVersion = 0;
	Gestalt(gestaltSystemVersion, &macVersion);

	if(macVersion < 0x1040) {
		[openImage setBezelStyle:NSShadowlessSquareBezelStyle];
		[scanFolder setBezelStyle:NSShadowlessSquareBezelStyle];
		[scanPage setBezelStyle:NSShadowlessSquareBezelStyle];
		[scanLink setBezelStyle:NSShadowlessSquareBezelStyle];
	}
	
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* libraryFolder = [NSString stringWithFormat:@"%@/Library/Application Support/Beholder", NSHomeDirectory()];
	NSString* pluginFolder = [NSString stringWithFormat:@"%@/Plugins", libraryFolder];
	if([fm fileExistsAtPath:pluginFolder]) {
		NSArray* contents = [fm directoryContentsAtPath:pluginFolder];
		NSEnumerator* enumerator = [contents objectEnumerator];
		NSString* file;
		
		int tag = engineSeparator + 1;
		while(file = [enumerator nextObject]) {
			NSString* path = [NSString stringWithFormat:@"%@/%@", pluginFolder, file];
			if([path hasSuffix:@".plist"] == NO)
				continue;
			
			NSPropertyListFormat format;
			NSString* error = nil;
			
			NSData* data = [NSData dataWithContentsOfFile:path];
			id plist = [NSPropertyListSerialization propertyListFromData:data
														mutabilityOption:NSPropertyListMutableContainersAndLeaves
																  format:&format
														errorDescription:&error];
			
			if(error) {
				NSLog(@"Plugin error (%@): %@", file, error);
				[error release];
			}
			
			if(plist) {
				NSString* title = [plist objectForKey:@"Title"];
				NSString* query = [plist objectForKey:@"Query"];
				NSString* more = [plist objectForKey:@"More"];
				NSString* moreQuery = [plist objectForKey:@"MoreQuery"];
				
				if(title == nil ) {
					NSLog(@"Plugin error (%@): missing Title key", file);
					continue;
				}
				
				if(query == nil) {
					NSLog(@"Plugin error (%@): missing Query key", file);
					continue;
				}
				
				NSRange r;
				r = [query rangeOfString:@"%@"];
				if(r.location == NSNotFound) {
					NSLog(@"Plugin error (%@): %%@ required in Query key", file);
					continue;
				}
				
				if(more) {
					r = [more rangeOfString:@"%d"];
					if(r.location == NSNotFound) {
						NSLog(@"Plugin error (%@): %%d required in More key", file);
						continue;
					}
				}
				
				if(moreQuery) {
					r = [more rangeOfString:@"%@"];
					if(r.location == NSNotFound) {
						NSLog(@"Plugin error (%@): %%@ required in MoreQuery key", file);
						continue;
					}
					
					int atLocation = r.location;
					
					r = [more rangeOfString:@"%d"];
					if(r.location == NSNotFound) {
						NSLog(@"Plugin error (%@): %%d required in MoreQuery key", file);
						continue;
					}
					
					if(r.location < atLocation) {
						NSLog(@"Plugin error (%@): %%@ must precede %%d in MoreQuery key", file);
						continue;
					}
				}
				
				BOOL didOverride = NO;
				
				if([plist objectForKey:@"Override"]) {
					NSEnumerator* e = [engineList objectEnumerator];
					NSMutableDictionary* d;
					
					while(d = [e nextObject]) {
						NSString* t = [d objectForKey:@"Title"];
						if([title isEqualToString:t]) {
							int index = [engineList indexOfObject:d];
							[engineList replaceObjectAtIndex:index withObject:plist];
							
							didOverride = YES;
							break;
						}
					}
				}
				
				if(didOverride == NO) {
					[engineList addObject:plist];
					
					NSMenu* menu = [engines menu];
					if([engines numberOfItems] == engineFlickr + 1)
						[menu addItem:[NSMenuItem separatorItem]];
					
					NSMenuItem* item = [menu addItemWithTitle:title action:@selector(handleEngine:) keyEquivalent:@""];
					[item setTag:tag];
					tag++;
				}
			}
		}
	}
	
	id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];		
	NSString* defaultEngine = [defaults valueForKey:@"DefaultEngine"];
	if([engines indexOfItemWithTitle:defaultEngine] >= 0)
		[engines selectItemWithTitle:defaultEngine];
	else
		[engines selectItemAtIndex:engineGoogle];
	[self handleEngine:self];

	NSNumber* detailsState = [defaults valueForKey:@"DetailsState"];
	if([detailsState intValue] == NSOffState) {
		[self handleCollapse:self];
	}

	NSNumber* thumbnailSize = [defaults valueForKey:@"ThumbnailSize"];
	if(thumbnailSize)
		[thumbsize setFloatValue:[thumbnailSize floatValue]];
	
	[self handleThumbsize:self];
	
	NSNumber* googleSafe = [defaults valueForKey:@"GoogleSafe"];
	if(googleSafe)
		[safe setSelectedSegment:[googleSafe intValue]];
	
	NSNumber* googleSize = [defaults valueForKey:@"GoogleSize"];
	if(googleSize)
		[size setSelectedSegment:[googleSize intValue]];
	
	if(loadFolder) {
		[self startScan:loadFolder];
		[loadFolder release];
		loadFolder = nil;
		
		[self setFileName:@""];
		
		[self updateChangeCount:NSChangeCleared];
	}
	else if(load) {
		[(Grid*)grid setResults:load];
		
		int resultCount = [load count];
		
		[self trackResults:load];
		
		[(Grid*)grid retileGrid];
		[(Grid*)grid syncGrid:load];
		[(Grid*)grid refreshGrid];
		
		[self syncResults:resultCount];
		[self ready];	
		
		if(loadQuery)
			[searchField setStringValue:loadQuery];
		
		if(loadTitle)
			[searchPanel setTitle:loadTitle];
				
		if(loadMessage)
			[statusBar setStringValue:loadMessage];
		
		if(loadEngineName) {
			int index = [engines indexOfItemWithTitle:loadEngineName];
			if(index == -1) {
				NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"MissingTitle", @"")
												 defaultButton:NSLocalizedString(@"OK", @"")
											   alternateButton:nil
												   otherButton:nil
									 informativeTextWithFormat:NSLocalizedString(@"MissingMessage", @""), loadEngineName];
				
				[alert setAlertStyle:NSInformationalAlertStyle];
				[alert runModal];
			}
			
			if(index >= 0)
				[engines selectItemAtIndex:index];
		}
		
		if(loadSafe == -1) {
			[safe setHidden:YES];
			[safeTitle setHidden:YES];
		}
		else
			[safe setSelectedSegment:loadSafe];
		
		if(loadSize == -1) {
			[size setHidden:YES];
			[sizeTitle setHidden:YES];
		}
		else
			[size setSelectedSegment:loadSize];

		if(loadMoreEngineName)
			moreEngine = [engines indexOfItemWithTitle:loadMoreEngineName];
		
		if(loadHistory) {
			[searchField removeAllItems];
			
			NSEnumerator* enumerator = [loadHistory reverseObjectEnumerator];
			NSString* entry;
			
			while(entry = [enumerator nextObject]) {
				[searchField addItemWithObjectValue:[NSString stringWithString:entry]];
			}
		}
		
		[self controlTextDidChange:nil];
		
		if(loadLocked)
			[self actionLock:self];

		[loadQuery release];
		[loadTitle release];
		[loadMessage release];
		[loadEngineName release];
		[loadMoreEngineName release];
		[loadHistory release];

		[load release];
		load = nil;
}
}

- (void)startScan:(NSString*)url
{
	if([url hasPrefix:@"file://"])
		[engines selectItemAtIndex:engineFolder];
	else
		[engines selectItemAtIndex:engineWeb];
	
	[searchField setStringValue:url];
	[searchButton setEnabled:YES];

	[self handleEngine:self];

	[self handleSearch:self];
}

- (void)startSearch:(NSString*)query
{
	id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];		
	NSString* defaultEngine = [defaults valueForKey:@"DefaultEngine"];
	if([engines indexOfItemWithTitle:defaultEngine] >= 0)
		[engines selectItemWithTitle:defaultEngine];
	else
		[engines selectItemAtIndex:engineGoogle];
	
	[searchField setStringValue:query];
	[searchButton setEnabled:YES];
	
	[self handleSearch:self];
}

- (void)actionMore:(id)sender
{
	[searchButton performClick:self];
}

- (void)actionDetails:(id)sender
{
	[details performClick:self];
}

- (void)actionSort:(id)sender
{
	switch([sender tag]) {
		case sortURL:
			[grid sortUsingSelector:@selector(sortURL:)];
			break;
			
		case sortArea:
			[grid sortUsingSelector:@selector(sortArea:)];
			break;
			
		case sortWidth:
			[grid sortUsingSelector:@selector(sortWidth:)];
			break;
			
		case sortHeight:
			[grid sortUsingSelector:@selector(sortHeight:)];
			break;
			
		case sortFileSize:
			[grid sortUsingSelector:@selector(sortFileSize:)];
			break;
			
		case sortHue:
			[grid sortUsingSelector:@selector(sortHue:)];
			break;
			
		case sortSaturation:
			[grid sortUsingSelector:@selector(sortSaturation:)];
			break;
			
		case sortLightness:
			[grid sortUsingSelector:@selector(sortLightness:)];
			break;
			
		default:
			[grid sortUsingSelector:@selector(sortDefault:)];
			break;
	}
	
	[grid setNeedsDisplay:YES];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	[[self window] setDocumentEdited:NO]; // not 100% sure this is the right place for this

	NSMutableArray* results = [(Grid*)grid getResults];
  
	NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
	[dataDictionary setObject:results forKey:@"SearchResults"];
	[dataDictionary setObject:[searchField stringValue] forKey:@"Query"];
	[dataDictionary setObject:[searchPanel title] forKey:@"Title"];
	[dataDictionary setObject:[statusBar stringValue] forKey:@"StatusBar"];
	[dataDictionary setObject:[engines titleOfSelectedItem] forKey:@"Engine"];
	if([safe isHidden] == NO)
		[dataDictionary setObject:[NSNumber numberWithInt:[safe selectedSegment]] forKey:@"Safe"];
	if([size isHidden] == NO)
		[dataDictionary setObject:[NSNumber numberWithInt:[size selectedSegment]] forKey:@"Size"];
	if(lastSearch)
		[dataDictionary setObject:lastSearch forKey:@"LastSearch"];
	if(moreEngine != -1)
		[dataDictionary setObject:[engines itemTitleAtIndex:moreEngine] forKey:@"MoreEngine"];
	[dataDictionary setObject:[NSNumber numberWithInt:moreValue] forKey:@"MoreValue"];
	if(moreSafe != -1)
		[dataDictionary setObject:[NSNumber numberWithInt:moreSafe] forKey:@"MoreSafe"];
	if(moreSize != -1)
		[dataDictionary setObject:[NSNumber numberWithInt:moreSize] forKey:@"MoreSize"];
	[dataDictionary setObject:[NSNumber numberWithBool:searchLocked] forKey:@"Locked"];
	[dataDictionary setObject:[searchField objectValues] forKey:@"History"];
	
	NSMutableData* data = [NSMutableData dataWithData:[NSArchiver archivedDataWithRootObject:dataDictionary]];
	[data appendData:[NSData dataWithBytes:"srch" length:4]];
	
    return data;
}

- (BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)wrapper ofType:(NSString *)docType
{
	if([wrapper isDirectory]) {
		NSURL* fileURL = [NSURL fileURLWithPath:[self fileName]];
		if(fileURL)
			loadFolder = [[fileURL absoluteString] retain];
		
		return YES;
	}
	
	return [super loadFileWrapperRepresentation:wrapper ofType:docType];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	if([data length] < 4)
		return NO;
	
	@try {
		char marker[4];
		NSRange markerRange;
		markerRange.location = [data length] - 4;
		markerRange.length = 4;
		
		[data getBytes:marker range:markerRange];
		
		if(marker[0] == 's' && marker[1] == 'r' && marker[2] == 'c' && marker[3] == 'h') {
			markerRange.location = 0;
			markerRange.length = [data length] - 4;
			
			NSDictionary* dataDictionary = [NSUnarchiver unarchiveObjectWithData:[data subdataWithRange:markerRange]];
			load = [[dataDictionary objectForKey:@"SearchResults"] retain];
			
			loadQuery = [[dataDictionary objectForKey:@"Query"] retain];
			loadTitle = [[dataDictionary objectForKey:@"Title"] retain];
			loadMessage = [[dataDictionary objectForKey:@"StatusBar"] retain];
			loadEngineName = [[dataDictionary objectForKey:@"Engine"] retain];
			
			NSNumber* n = [dataDictionary objectForKey:@"Safe"];
			if(n)
				loadSafe = [n intValue];
			
			n = [dataDictionary objectForKey:@"Size"];
			if(n)
				loadSize = [n intValue];
			
			NSString* s = [dataDictionary objectForKey:@"LastSearch"];
			if(s)
				lastSearch = [s copy];

			loadMoreEngineName = [[dataDictionary objectForKey:@"MoreEngine"] retain];
			
			n = [dataDictionary objectForKey:@"MoreValue"];
			if(n)
				moreValue = [n intValue];
			
			n = [dataDictionary objectForKey:@"MoreSafe"];
			if(n)
				moreSafe = [n intValue];
			
			n = [dataDictionary objectForKey:@"MoreSize"];
			if(n)
				moreSize = [n intValue];

			n = [dataDictionary objectForKey:@"Locked"];
			if(n)
				loadLocked = [n boolValue];
			
			loadHistory = [[dataDictionary objectForKey:@"History"] retain];
		}
		else
			load = [NSUnarchiver unarchiveObjectWithData:data];
	}

	@catch (NSException* exception) {
		load = nil;
	}
	
	[load retain];
	
    return YES;
}

- (void)actionSave:(id)sender
{
	[self saveDocument:sender];
}

- (void)actionBadges:(id)sender
{
	[badges performClick:sender];
	
	[grid setNeedsDisplay:YES];
}

- (void)actionBroken:(id)sender
{
	[broken performClick:sender];
	
	[(Grid*)grid resyncGrid];
	[(Grid*)grid syncGrid:nil];
	[(Grid*)grid refreshGrid];
}

- (void)actionVerifyAll:(id)sender
{
	NSMutableArray* results = [(Grid*)grid getResultsNeedingVerification];
	if(results) {
		[batch stop];
		batch = [[Batch alloc] initWithTargets:results action:@selector(verify:) object:self poll:@selector(poll) interval:0.05 limit:4];
		[batch start:batchProgress];
	}
}

- (void)actionDownloadAll:(id)sender
{
	NSMutableArray* results = [(Grid*)grid getResultsDownloadable];
	if(results) {
		NSOpenPanel* panel = [NSOpenPanel openPanel];
		
		[panel setCanChooseDirectories:YES];
		[panel setCanCreateDirectories:YES];
		[panel setPrompt:NSLocalizedString(@"SaveIntoFolder", @"")];
		[panel setCanChooseFiles:NO];
		
		if([panel runModalForTypes:nil] == NSOKButton) {
			NSArray* filePaths = [panel filenames];
			NSString* path = [filePaths objectAtIndex:0];

			[batch stop];
			batch = [[Batch alloc] initWithTargets:results action:@selector(downloadToFolder:) object:path poll:@selector(poll) interval:0.05 limit:4];
			[batch start:batchProgress];
		}
	}
}

- (void)actionClearHistory:(id)sender
{
	[searchField removeAllItems];
	[saveSearch release];
	saveSearch = nil;
}

- (void)actionLock:(id)sender
{
	if(searchLocked) {
		[lock setImage:[NSImage imageNamed:@"unlock"]];
		[searchField setEnabled:YES];
		[searchButton setEnabled:YES];
		[engines setEnabled:YES];
		[safe setEnabled:YES];
		[size setEnabled:YES];	
		
		searchLocked = NO;
	}
	else {
		[lock setImage:[NSImage imageNamed:@"lock"]];
		[searchField setEnabled:NO];
		[searchButton setEnabled:NO];
		[engines setEnabled:NO];
		[safe setEnabled:NO];
		[size setEnabled:NO];
		
		searchLocked = YES;
	}
}

- (void)actionPlugin:(id)sender
{
	id defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[engines title] forKey:@"DefaultEngine"];
}

- (void)actionPreviousEngine:(id)sender
{
	int selectedEngine = [engines indexOfSelectedItem];
	if(selectedEngine) {
		selectedEngine--;
		
		if([[engines itemAtIndex:selectedEngine] isSeparatorItem])
			selectedEngine--;
		
		[engines selectItemAtIndex:selectedEngine];
		[self handleEngine:sender];
	}
	else
		NSBeep();
}

- (void)actionNextEngine:(id)sender
{
	int selectedEngine = [engines indexOfSelectedItem];
	if(selectedEngine < [engines numberOfItems] - 1) {
		selectedEngine++;
		
		if([[engines itemAtIndex:selectedEngine] isSeparatorItem])
			selectedEngine++;
		
		[engines selectItemAtIndex:selectedEngine];
		[self handleEngine:sender];
	}
	else
		NSBeep();
}

- (void)actionRotateSize:(id)sender
{
	int selectedSegment = [size selectedSegment];
	if(selectedSegment < [size segmentCount] - 1)
		selectedSegment++;
	else
		selectedSegment = 0;

	[size setSelectedSegment:selectedSegment];
	[self handleChange:self];
}

- (void)actionRotateSafe:(id)sender
{
	int selectedSegment = [safe selectedSegment];
	if(selectedSegment < [safe segmentCount] - 1)
		selectedSegment++;
	else
		selectedSegment = 0;

	[safe setSelectedSegment:selectedSegment];
	[self handleChange:self];
}

- (void)actionSearch:(id)sender
{
	[self handleSearch:sender];
}

- (NSWindow*)window
{
	return window;
}

- (IBAction)handleSmaller:(id)sender
{
	int value = ([thumbsize intValue] - 32) / 16;
	if(value) {
		value = ((value - 1) * 16) + 32;

		[thumbsize setIntValue:value];
		[self handleThumbsize:sender];
	}
}

- (IBAction)handleBigger:(id)sender
{
	int value = ([thumbsize intValue] - 32) / 16;
	if(value < 12) {
		value = ((value + 1) * 16) + 32;
	
		[thumbsize setIntValue:value];
		[self handleThumbsize:sender];
	}
}

- (IBAction)handleCollapse:(id)sender
	{
	int width = [window frame].size.width;
	NSRect frame = [searchPanel frame];

	if([collapse state] == NSOnState) {
		frame.size.width = (width - 402);
		[infoPanel setHidden:NO];

		//CFPreferencesSetAppValue(CFSTR("ShowDetails"), [NSNumber numberWithBool:YES], kCFPreferencesCurrentApplication);	
	}
	else {
		[infoPanel setHidden:YES];
		frame.size.width = (width - 16);

		//CFPreferencesSetAppValue(CFSTR("ShowDetails"), [NSNumber numberWithBool:NO], kCFPreferencesCurrentApplication);	
	}
	
	[searchPanel setFrame:frame];
	
	if([window isVisible])
		[window display];
}

- (IBAction)handleThumbsize:(id)sender
{
	int c = [thumbsize intValue];
	int r = (c % 2);
	if(r)
		c += (2 - r);
		
	NSSize gridSize = NSMakeSize((float)c, (float)c);
	[(Grid*)grid setGridSize:gridSize];

	id defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithFloat:[thumbsize floatValue]] forKey:@"ThumbnailSize"];
}

- (IBAction)handleEngine:(id)sender
{
	int selectedEngine = [engines indexOfSelectedItem];		
	
	if(selectedEngine == engineGoogle) {
		[safeTitle setHidden:NO];
		[safe setHidden:NO];
		[sizeTitle setHidden:NO];
		[size setHidden:NO];
	}
	else {
		[safeTitle setHidden:YES];
		[safe setHidden:YES];
		[sizeTitle setHidden:YES];
		[size setHidden:YES];
	}

	if(selectedEngine >= engineGoogle) {
		int engineIndex = (selectedEngine < engineSeparator ? (selectedEngine - engineGoogle) : (selectedEngine - engineGoogle) - 1);
		NSDictionary* currentEngine = [engineList objectAtIndex:engineIndex];
		NSString* notes = [currentEngine objectForKey:@"Notes"];
		if(notes)
			[engines setToolTip:[NSString stringWithString:notes]];
		else
			[engines setToolTip:@""];
	}
	
	NSString* query = [searchField stringValue];

	if(selectedEngine == engineFolder) {
		if([query hasPrefix:@"file://"] == NO) {
			[saveSearch release];
			saveSearch = [query copy];
			[searchField setStringValue:@""];
		}
	}
	else {
		if([query hasPrefix:@"file://"]) {
			[searchField setStringValue:@""];			
		}
		
		if(saveSearch) {
			[searchField setStringValue:saveSearch];
			[saveSearch release];
			saveSearch = nil;
		}
	}

	[[self window] makeFirstResponder:searchField];
	[searchField selectText:sender];

	[self controlTextDidChange:nil];
}

- (IBAction)handleSearch:(id)sender
{
	if([[searchButton title] isEqualToString:NSLocalizedString(@"Stop", @"")]) {
		[(BrowserController*)browserController stop];
		return;
	}
	
	if([self fileName])
		[self updateChangeCount:NSChangeDone];
	else
		[[self window] setDocumentEdited:YES];
	
	BOOL askForFolder = NO;
	
	int selectedEngine = [engines indexOfSelectedItem];
	
	NSString* entry = [searchField stringValue];
	NSString* query = [entry stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([query isEqualToString:entry] == NO)
		[searchField setStringValue:query];
	
	if(selectedEngine != engineFolder && [query hasPrefix:@"file://"]) {
		[engines selectItemAtIndex:engineFolder];
		[self handleEngine:self];
		selectedEngine = engineFolder;
		
		[saveSearch release];
		saveSearch = [lastSearch copy];
	}
	else if(selectedEngine != engineWeb && ([query hasPrefix:@"http://"] || [query hasPrefix:@"https://"] || [query hasPrefix:@"feed://"])) {
		[engines selectItemAtIndex:engineWeb];
		[self handleEngine:self];
		selectedEngine = engineWeb;
	}
		
	if([query length] == 0) {
		if(selectedEngine == engineFolder)
			askForFolder = YES;
		else {
			NSBeep();
			return;
		}
	}
	else if(selectedEngine == engineWeb && ([query isEqualToString:@"http://"] || [query isEqualToString:@"https://"] || [query isEqualToString:@"feed://"]))
		return;
	else if(selectedEngine == engineFolder && [query isEqualToString:@"file://"])
		return;
	
	if(askForFolder) {
		NSOpenPanel *panel = [NSOpenPanel openPanel];
		[panel setCanChooseDirectories:YES];
		[panel setCanChooseFiles:NO];
		[panel setAllowsMultipleSelection:NO];
		
		if([panel runModalForTypes:nil] == NSOKButton) {
			NSArray* filePaths = [panel filenames];
			NSString* path = [filePaths objectAtIndex:0];
			[searchField setStringValue:path];
			query = [searchField stringValue];
			
			[[self window] makeFirstResponder:searchField];
		}
		else {
			[[self window] makeFirstResponder:searchField];
			return;
		}
	}

	NSArray* items = [searchField objectValues];
	if([items indexOfObject:query] == NSNotFound)
		[searchField addItemWithObjectValue:query];
			
	[(BrowserController*)browserController setDocument:self];

	NSString* url = nil;
	NSString* filter = nil;
	NSString* ignore = nil;
	NSArray* imageSubs = nil; 
	BOOL scrape = NO;
	
	lastResultCount = 0;

	if(selectedEngine == engineWeb) {
		[statusIcon setImage:[NSImage imageNamed:@"scan"]];

		[searchPanel setTitle:NSLocalizedString(@"SearchResults", @"")];
		[statusBar setStringValue:@""];
		
		if([query hasPrefix:@"http://"] == NO && [query hasPrefix:@"https://"] == NO && [query hasPrefix:@"feed://"] == NO)
			query = [NSString stringWithFormat:@"http://%@", query];
		
		NSRange r = [query rangeOfString:@"."];
		if(r.location == NSNotFound)
			query = [NSString stringWithFormat:@"%@.com", query];

		NSString* escapedQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if(escapedQuery)
			query = escapedQuery;		
		
		[searchField setStringValue:query];
		url = query;
				
		[lastSearch release];
		lastSearch = nil;
		
		[self clearResults];

		moreValue = 0;
		[(Grid*)grid resetGrid];
		[preview setImage:nil];
		selectedResult = nil;
		[info setNeedsDisplay:YES];

		[statusBar setStringValue:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Scraping", @"")]];
		
		scrape = YES;
	}
	else if(selectedEngine == engineFolder) {
		if([query hasPrefix:@"file://"] == NO) {
			NSURL* fileURL = [NSURL fileURLWithPath:query];
			if(fileURL == nil)
				return;

			query = [fileURL absoluteString];
			[searchField setStringValue:query];
		}
		else
			[searchField setStringValue:query];
		
		url = query;

		[statusIcon setImage:[NSImage imageNamed:@"scan"]];
		
		[searchPanel setTitle:NSLocalizedString(@"SearchResults", @"")];
		[statusBar setStringValue:@""];
		
		[lastSearch release];
		lastSearch = nil;
		
		[self clearResults];
		
		moreValue = 0;
		[(Grid*)grid resetGrid];
		[preview setImage:nil];
		selectedResult = nil;
		[info setNeedsDisplay:YES];
		
		[statusBar setStringValue:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Scraping", @"")]];
	}
	else {
		int engineIndex = (selectedEngine < engineSeparator ? (selectedEngine - engineGoogle) : (selectedEngine - engineGoogle) - 1);
		NSDictionary* currentEngine = [engineList objectAtIndex:engineIndex];

		NSArray* local = [[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"];
		NSString* language = @"en";
		NSString* preferredLanguage = [local objectAtIndex:0];
		if(preferredLanguage)
			language = preferredLanguage;
		
		NSString* forceLanguage = [currentEngine objectForKey:@"Language"];
		if(forceLanguage)
			language = forceLanguage;
		
		NSString* safeString = nil;
		switch([safe selectedSegment]) {
			case 0:		safeString = @"&safe=on";		break;
			case 1:		safeString = @"&safe=mixed";	break;
			case 2:		safeString = @"&safe=off";		break;
		}
		
		NSString* sizeString = nil;
		switch([size selectedSegment]) {
			case 0:		sizeString = @"&imgsz=";			break;
			case 1:		sizeString = @"&imgsz=huge";		break;
			case 2:		sizeString = @"&imgsz=xxlarge";		break;
			case 3:		sizeString = @"&imgsz=medium";		break;
			case 4:		sizeString = @"&imgsz=small";		break;
		}
		
		NSString* separator = [currentEngine objectForKey:@"Separator"];
		{
			NSMutableString* mutableQuery = [[query mutableCopy] autorelease];
			[mutableQuery replaceOccurrencesOfString:@" " withString:(separator ? separator : @"+") options:0 range:NSMakeRange(0, [mutableQuery length])];
			query = mutableQuery;
		}
		
		NSString* escapedQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if(escapedQuery)
			query = escapedQuery;
	
		if(
			lastSearch &&
			[lastSearch isEqualToString:query] &&
			moreEngine == selectedEngine &&
			(moreEngine != engineGoogle || moreSafe == [safe selectedSegment]) && 
			(moreEngine != engineGoogle || moreSize == [size selectedSegment])
		) {
			[statusBar setStringValue:@""];
			
			if(moreValue == 0) {
				NSNumber* moreStart = [currentEngine objectForKey:@"MoreStart"];
				moreValue = (moreStart ? [moreStart intValue] : 0);
			}
			
			NSNumber* moreOffset = [currentEngine objectForKey:@"MoreOffset"];
			moreValue += (moreOffset ? [moreOffset intValue] : 1);
			
			@try {
				if(selectedEngine == engineGoogle)
					url = [NSString stringWithFormat:[currentEngine objectForKey:@"GoogleMoreQuery"], query, language, moreValue, safeString, sizeString];
				else {
					if([currentEngine objectForKey:@"MoreQuery"])
						url = [NSString stringWithFormat:[currentEngine objectForKey:@"MoreQuery"], query, moreValue];
					else if([currentEngine objectForKey:@"More"]) {
						NSString* prefix = [NSString stringWithFormat:[currentEngine objectForKey:@"Query"], query];
						NSString* postfix = [NSString stringWithFormat:[currentEngine objectForKey:@"More"], moreValue];
						url = [NSString stringWithFormat:@"%@%@", prefix, postfix];
					}
				}
			}
			
			@catch (NSException* exception) {
				if([currentEngine objectForKey:@"MoreQuery"])
					NSLog(@"Plugin error (\"%@\"): MoreQuery key format error", [currentEngine objectForKey:@"Title"]);
				else
					NSLog(@"Plugin error (\"%@\"): More key format error", [currentEngine objectForKey:@"Title"]);
				
				[statusBar setStringValue:NSLocalizedString(@"PluginError", @"")];
				NSBeep();
				return;
			}
		}
		
		if(url == nil) {
			[searchPanel setTitle:NSLocalizedString(@"SearchResults", @"")];
	
			@try {
				if(selectedEngine == engineGoogle)
					url = [NSString stringWithFormat:[currentEngine objectForKey:@"GoogleQuery"], query, language, safeString, sizeString];
				else
					url = [NSString stringWithFormat:[currentEngine objectForKey:@"Query"], query];
			}
			
			@catch (NSException* exception) {
				NSLog(@"Plugin error (\"%@\"): Query key format error", [currentEngine objectForKey:@"Title"]);
				[statusBar setStringValue:NSLocalizedString(@"PluginError", @"")];
				NSBeep();
				return;
			}
			
			lastSearch = [query copy];
			
			[self clearResults];

			moreValue = 0;
			[(Grid*)grid resetGrid];
			[preview setImage:nil];
			selectedResult = nil;
			[info setNeedsDisplay:YES];
		}
		
		filter = [currentEngine objectForKey:@"Filter"];
		ignore = [currentEngine objectForKey:@"Ignore"];
		imageSubs = [currentEngine objectForKey:@"ImageSubs"];

		[statusBar setStringValue:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Searching", @"")]];
	}
	
	if(url && [(BrowserController*)browserController submitQuery:url withFilter:filter ignoring:ignore imageSubs:imageSubs scrape:scrape] == YES) {
		[engines setEnabled:NO];
		[safe setEnabled:NO];
		[size setEnabled:NO];
		[searchField setEnabled:NO];
		[searchButton setTitle:NSLocalizedString(@"Stop", @"")];
		[wait startAnimation:self];
	}
}

- (IBAction)handleChange:(id)sender
{
	id defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithInt:[safe selectedSegment]] forKey:@"GoogleSafe"];
	[defaults setObject:[NSNumber numberWithInt:[size selectedSegment]] forKey:@"GoogleSize"];

	[self controlTextDidChange:nil];
}

- (void)trackResults:(NSMutableArray*)results
{
	NSEnumerator* resultEnumerator = [results objectEnumerator];
	NSImage* result;		
	while(result = [resultEnumerator nextObject])
		[result setDelegate:self];
}

- (void)syncResults:(int)resultCount
{
	moreEngine = engineNone;
	moreSafe = -1;
	moreSize = -1;
	
	NSMutableArray* results = [(Grid*)grid getResults];
	
	if(resultCount) {
		NSString* title;
	
		int selectedEngine = [engines indexOfSelectedItem];		
		if(selectedEngine == engineWeb) {
			title = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"ScrapeResults", @""), [results count]];
			//[searchButton setTitle:NSLocalizedString(@"Start", @"")];
		}
		else if(selectedEngine == engineFolder) {
			title = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"ScrapeResults", @""), [results count]];
			//[searchButton setTitle:NSLocalizedString(@"Start", @"")];
		}
		else {
			title = [NSString stringWithFormat:@"%@ (%d+)", NSLocalizedString(@"SearchResults", @""), [results count]];
			//[searchButton setTitle:NSLocalizedString(@"More", @"")];
			
			moreEngine = selectedEngine;
			
			if(selectedEngine == engineGoogle) {
				moreSafe = [safe selectedSegment];
				moreSize = [size selectedSegment];
			}
		}
		[searchPanel setTitle:title];
			
		int row = 0;
		int column = 0;
		int newIndex = [results count] - resultCount;
		if(newIndex > 0) {
			[grid getRow:&row column:&column ofCell:[[grid cells] objectAtIndex:newIndex]];
			[grid selectCellAtRow:row column:column];
			[grid scrollCellToVisibleAtRow:row column:column];
		}
		else if(newIndex == 0) {
			[grid getRow:&row column:&column ofCell:[[grid cells] objectAtIndex:0]];
			[grid selectCellAtRow:row column:column];
			[grid scrollCellToVisibleAtRow:row column:column];
		}
		
		lastResultCount += resultCount;
	}
	else {
		//[searchButton setTitle:NSLocalizedString(@"Start", @"")];
	}
}

- (void)lock
{
	[searchButton setEnabled:NO];
}

- (void)unlock
{
	[searchButton setEnabled:YES];
}

- (BOOL)isReady
{
	if([[searchButton title] isEqualToString:NSLocalizedString(@"Stop", @"")])
		return NO;
	
	return [searchButton isEnabled];
}

- (void)ready
{
	[self ready:nil];
}

- (void)ready:(NSString*)message
{
	[searchButton setEnabled:YES];
	
	[safe setEnabled:YES];
	[size setEnabled:YES];
	
	[engines setEnabled:YES];
	[searchField setEnabled:YES];
	[wait stopAnimation:self];

	NSMutableArray* results = [(Grid*)grid getResults];
	if([results count] == 0) {
		[openImage setEnabled:NO];
		[scanFolder setEnabled:NO];
		[scanPage setEnabled:NO];
		[scanLink setEnabled:NO];

		NSString* status = NSLocalizedString(@"NoResults", @"");
		if(message && [message length])
			status = [status stringByAppendingString:[NSString stringWithFormat:@" (%@)", message]];
		[statusBar setStringValue:status];

		[searchButton setTitle:NSLocalizedString(@"Start", @"")];

		[[self window] makeFirstResponder:searchField];
		[searchField selectText:self];
	}
	else {
		[openImage setEnabled:YES];
		[scanFolder setEnabled:YES];
		[scanPage setEnabled:YES];
		[scanLink setEnabled:YES];
		
		int selectedEngine = [engines indexOfSelectedItem];		
		if(selectedEngine == engineWeb) {
			NSString* query = [searchField stringValue];
			NSRange colon = [query rangeOfString:@"://"];
			if(colon.location != NSNotFound)
				query = [query substringFromIndex:colon.location + 3];
			
			NSString* status = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"ResultsFrom", @""), query];
			if(message && [message length])
				status = [status stringByAppendingString:[NSString stringWithFormat:@" (%@)", message]];
			[statusBar setStringValue:status];

			[searchButton setTitle:NSLocalizedString(@"Start", @"")];
		}
		else if(selectedEngine == engineFolder) {
			NSString* status = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"ResultsFrom", @""), @"localhost"];
			if(message && [message length])
				status = [status stringByAppendingString:[NSString stringWithFormat:@" (%@)", message]];
			[statusBar setStringValue:status];
			
			[searchButton setTitle:NSLocalizedString(@"Start", @"")];
		}
		else {
			if(moreEngine) {
				if(lastResultCount == 0) {
					NSString* title = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"SearchResults", @""), [results count]];
					[searchPanel setTitle:title];
					
				}
				
				[searchButton setTitle:NSLocalizedString(@"More", @"")];
			}
			else
				[searchButton setTitle:NSLocalizedString(@"Start", @"")];

			int engineIndex = (selectedEngine < engineSeparator ? (selectedEngine - engineGoogle) : (selectedEngine - engineGoogle) - 1);
			NSDictionary* currentEngine = [engineList objectAtIndex:engineIndex];
			NSString* root = [currentEngine objectForKey:@"Root"];
			if(root == NULL)
				root = [engines titleOfSelectedItem];
				
			NSString* status = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"ResultsFrom", @""), root];
			if(message && [message length])
				status = [status stringByAppendingString:[NSString stringWithFormat:@" (%@)", message]];
			[statusBar setStringValue:status];
		}
		
		[[self window] makeFirstResponder:grid];
	}
}

- (void)select:(id)sender
{
	ImageResult* result = [(Thumbnail*)sender objectValue];
	selectedResult = result;
	if(selectedResult) {
		NSImage* previewImage = [result preview];
		if(previewImage)
			[preview setImage:previewImage];
		else
			[preview setImage:selectedResult];

		[openImage setEnabled:!([selectedResult requiresPreview] && [selectedResult missingPreview])];
	}
	
	[info setNeedsDisplay:YES];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return 4;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if([[aTableColumn identifier] isEqualToString:@"title"]) {
		switch(rowIndex) {
			case 0:
				return NSLocalizedString(@"Image", @"");
				
			case 1:
				return NSLocalizedString(@"Page", @"");
				
			case 2:
				return NSLocalizedString(@"Link", @"");
				
			case 3:
				return NSLocalizedString(@"Size", @"");
		}
	}
	else {
		switch(rowIndex) {
			case 0:
				return [selectedResult imageURL];
				
			case 1:
				return [selectedResult pageURL];
				
			case 2:
				return [selectedResult linkURL];
				
			case 3:
				return [selectedResult infoString];
		}
	}
	
	return nil;
}

- (void)clearResults
{
	NSMutableArray* results = [(Grid*)grid getResults];

	NSEnumerator* resultEnumerator = [results objectEnumerator];
	NSImage* result;		
	while(result = [resultEnumerator nextObject])
		[result setDelegate:nil];
	
	NSMutableDictionary* linkResults = [(Grid*)grid getLinkResults];

	resultEnumerator = [[linkResults allValues] objectEnumerator];
	while(result = [resultEnumerator nextObject])
		[result setDelegate:nil];
}

- (BOOL)badgesAreVisible
{
	return ([badges intValue] == NSOnState ? YES : NO);
}

- (BOOL)brokenAreVisible
{
	return ([broken intValue] == NSOnState ? YES : NO);
}

- (void)resolveBroken
{
	if([broken intValue] == NSOffState)
		[broken setIntValue:NSOnState];
}

- (void)setStatusImage:(NSImage*)image
{
	[statusIcon setImage:image];
	[statusIcon setNeedsDisplay:YES];
	[[self window] display];
}

- (void)setStatusText:(NSString*)text
{
	[statusBar setStringValue:text];
	[statusBar setNeedsDisplay:YES];
	[[self window] display];
}

- (NSString*)statusText
{
	return [statusBar stringValue];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    if([anItem action] == @selector(actionMore:)) {
		if([[searchButton title] isEqualToString:NSLocalizedString(@"More", @"")])
			return YES;
			
		return NO;
	}

	if([(id)anItem isMemberOfClass:[NSMenuItem class]] == NO)
		return YES;
	
	NSMenuItem* item = (NSMenuItem*)anItem;
	
	if([item action] == @selector(actionDetails:)) {
		if([details state] == NSOnState)
			[item setTitle:NSLocalizedString(@"HideDetails", @"")];
		else
			[item setTitle:NSLocalizedString(@"ShowDetails", @"")];
		
	}
	
	if([item action] == @selector(actionBadges:)) {
		if([badges state] == NSOnState)
			[item setTitle:NSLocalizedString(@"HideBadges", @"")];
		else
			[item setTitle:NSLocalizedString(@"ShowBadges", @"")];
		
	}
	
	if([item action] == @selector(actionBroken:)) {
		if([broken state] == NSOnState)
			[item setTitle:NSLocalizedString(@"HideBroken", @"")];
		else
			[item setTitle:NSLocalizedString(@"ShowBroken", @"")];
		
		if([(Grid*)grid areResultsBroken] == NO)
			return NO;
	}

	if([item action] == @selector(actionSort:)) {
		NSMutableArray* results = [(Grid*)grid getResults];
		if([results count] == 0)
			return NO;
	}
	
	if([item action] == @selector(actionSort:) || [item action] == @selector(actionDownloadAll:)) {
		if(batch && [batch isRunning])
			return NO;
		
		NSMutableArray* results = [(Grid*)grid getResultsDownloadable];
		if([results count] == 0)
			return NO;
	}
	
	if([item action] == @selector(actionVerifyAll:)) {
		if(batch && [batch isRunning])
			return NO;
		
		NSMutableArray* results = [(Grid*)grid getResultsNeedingVerification];
		if([results count] == 0)
			return NO;
	}
	
	if([item action] == @selector(actionClearHistory:)) {
		return ([searchField numberOfItems] > 0 ? YES : NO);
	}
	
	if([item action] == @selector(actionLock:)) {
		if(searchLocked)
			[item setTitle:NSLocalizedString(@"UnlockSearch", @"")];
		else
			[item setTitle:NSLocalizedString(@"LockSearch", @"")];
	}
	
	if([item action] == @selector(actionSave:)) {
		[item setTitle:NSLocalizedString(@"SaveSearch", @"")];
	}
	
	if([item action] == @selector(actionRotateSize:) || [item action] == @selector(actionRotateSafe:)) {
		if([engines indexOfSelectedItem] != engineGoogle)
			return NO;
	}
	
	if([item action] == @selector(actionPlugin:)) {
		NSString* title = [NSString stringWithFormat:NSLocalizedString(@"DefaultPlugin", @""), [engines title]];
		[item setTitle:title];
		
		id defaults = [NSUserDefaults standardUserDefaults];
		NSString* engine = [defaults objectForKey:@"DefaultEngine"];
		if([engine isEqualToString:[engines title]])
			return NO;

	}
	
	if([item action] == @selector(actionSearch:)) {
		[item setTitle:[searchButton title]];
		
		if([searchButton isEnabled] == NO)
			return NO;
	}
	
	return YES;
}

// NSComboBox delegate
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	int selectedEngine = [engines indexOfSelectedItem];
	NSString* entry = [searchField stringValue];
	if([entry length] == 0 && selectedEngine != engineFolder)
		[searchButton setEnabled:NO];
	else
		[searchButton setEnabled:YES];
	
	if(
	   lastSearch &&
	   [lastSearch isEqualToString:entry] &&
	   moreEngine == selectedEngine &&
	   (moreEngine != engineGoogle || moreSafe == [safe selectedSegment]) && 
	   (moreEngine != engineGoogle || moreSize == [size selectedSegment])
	)
		[searchButton setTitle:NSLocalizedString(@"More", @"")];
	else
		[searchButton setTitle:NSLocalizedString(@"Start", @"")];
}

// ImageResult delegate
- (void)didUpdatePreview:(id)sender
{
	if(selectedResult && [selectedResult isEqualTo:sender]) {
		NSImage* previewImage = [(ImageResult*)selectedResult preview];
		if(previewImage)
			[preview setImage:previewImage];
		else
			[preview setImage:selectedResult];

		[preview setNeedsDisplay:YES];
		
		if([selectedResult requiresPreview]) {
			[grid setNeedsDisplay:YES];
			[infoPanel setNeedsDisplay:YES];
			
			[openImage setEnabled:![selectedResult missingPreview]];
		}
	}
	else
		[grid setNeedsDisplay:YES];
}

- (void)didUpdateThumbnail:(id)sender
{
	[grid setNeedsDisplay:YES];
}

// NSWindow delegate
- (void)windowDidResize:(NSNotification *)aNotification
{
	NSRect frame = [[self window] frame];
	CFPreferencesSetAppValue(CFSTR("SearchWidth"), [NSNumber numberWithFloat:frame.size.width], kCFPreferencesCurrentApplication);	
	CFPreferencesSetAppValue(CFSTR("SearchHeight"), [NSNumber numberWithFloat:frame.size.height], kCFPreferencesCurrentApplication);	
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[browserController close];
	
	[self clearResults];
}

@end
