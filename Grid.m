//
//  Grid.m
//  Beholder
//
//  Created by Danny Espinoza on 10/16/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "Grid.h"
#import "ImageResult.h"
#import "Thumbnail.h"
#import "BrowserController.h"


static int CalcWidth(
	float max,
	float min,
	float gap,
	float *outWidth)
{
	unsigned n = (int)(max / (min + gap));
	if(n == 0)
		n = 1;
		
	*outWidth = (max / (float)n) - gap;
	
	return n;
}

@implementation Grid

- (id)init
{
    self = [super init];
	
    if(self) {
		results = nil;
		linkResults = nil;
    }
	
    return self;
}

- (void)dealloc
{
	[results release];
	[linkResults release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	minSize = NSMakeSize(128.0, 128.0);
	
	[self setDrawsBackground:YES];
	[self setBackgroundColor:[NSColor blackColor]];
	
	[self setCellClass:[Thumbnail class]];
	[self setIntercellSpacing:NSMakeSize(0.0, 0.0)];
		
	results = [[NSMutableArray alloc] init];
	
	[self setTabKeyTraversesCells:YES];
	[self setMode:NSListModeMatrix];
	[self setAllowsEmptySelection:YES];
	
	[self setDoubleAction:@selector(openThumbnail:)];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (NSMutableArray*)getResults
{
	return results;
}

- (NSMutableDictionary*)getLinkResults
{
	return linkResults;
}

- (NSMutableArray*)getResultsNeedingVerification
{
	NSMutableArray* returnValue = nil;
	
	NSEnumerator* resultEnumerator = [results objectEnumerator];
	ImageResult* result;
	
	while(result = [resultEnumerator nextObject]) {
		if([result requiresPreview] == NO || [result missingPreview] || [result checkingPreview] || [result preview] || [result testedPreview])
			continue;
		
		if(returnValue == nil)
			returnValue = [[NSMutableArray alloc] init];
		
		[returnValue addObject:result];
	}	
	
	return [returnValue autorelease];
}

- (NSMutableArray*)getResultsDownloadable
{
	NSMutableArray* returnValue = nil;
	
	NSEnumerator* resultEnumerator = [results objectEnumerator];
	ImageResult* result;
	
	while(result = [resultEnumerator nextObject]) {
		if([result requiresPreview] && [result missingPreview])
			continue;
		
		if(returnValue == nil)
			returnValue = [[NSMutableArray alloc] init];
		
		[returnValue addObject:result];
	}	
	
	return [returnValue autorelease];
}


- (BOOL)areResultsBroken
{
	NSEnumerator* resultEnumerator = [results objectEnumerator];
	ImageResult* result;
	
	while(result = [resultEnumerator nextObject]) {
		if([result requiresPreview] && [result missingPreview])
			return YES;
	}	
	
	return NO;
}

- (void)setResults:(NSMutableArray*)newResults
{
	[results release];
	results = [newResults retain];
}

- (BOOL)addResult:(ImageResult*)newResult
{
	NSSize size = [newResult size];
	if(size.width == 1 && size.height == 1)
		return NO;
		
	if(results) {
		NSEnumerator* resultEnumerator = [results objectEnumerator];
		ImageResult* result;

		NSString* origURL = [newResult origURL];
		
		while(result = [resultEnumerator nextObject]) {
			if([origURL isEqualToString:[result origURL]] == YES)
				return NO;
		}
	}
	
	[results addObject:newResult];
	
	return YES;
}

- (void)resetGrid
{
	[results removeAllObjects];
	[linkResults removeAllObjects];

	[self resyncGrid];
}

- (void)syncGrid:(NSMutableArray*)newResults
{
	NSArray* cells = [self cells];
	
	NSMutableArray* sync = (newResults ? newResults : results);

	NSEnumerator* resultEnumerator = [sync objectEnumerator];
	NSEnumerator* cellEnumerator = [cells objectEnumerator];
	NSCell* cell;
	
	BOOL showBroken = [document brokenAreVisible];
	
	while(cell = [cellEnumerator nextObject]) {
		if([cell objectValue] == nil) {
			ImageResult* result = [resultEnumerator nextObject];
			
			if(showBroken == NO) {
				while(result && [result requiresPreview] && [result missingPreview])
					result = [resultEnumerator nextObject];
			}
			
			if(result) {
				[cell setObjectValue:result];
				[cell setEnabled:YES];	
				[(Thumbnail*)cell setGrid:self];	
			}
			else
				[cell setEnabled:NO];	
		}
	}
}

- (void)resyncGrid
{
	NSArray* cells = [self cells];
	
	NSEnumerator* cellEnumerator = [cells objectEnumerator];
	NSCell* cell;
	while(cell = [cellEnumerator nextObject]) {
		[cell setObjectValue:nil];
		[cell setEnabled:NO];
	}
	
	NSRect frame = [super frame];
	frame.size.height = 0;
	[super setFrame:frame];
}

- (void)refreshGrid
{
	NSRect frame = [self frame];
	[self setFrame:frame];
}

- (void)retileGrid
{
	NSCell* selection = nil;
	
	NSArray* cells = [self cells];
	NSEnumerator* cellEnumerator = [cells objectEnumerator];
	NSCell* cell;
	while(cell = [cellEnumerator nextObject]) {
		if([cell state] == NSOnState) {
			selection = cell;
			break;
		}
	}
	
	NSRect frame = [self frame];
	NSSize sz = frame.size;
	NSSize newCellSize, spacing = [self intercellSpacing];

	int cols = CalcWidth(sz.width, minSize.width, spacing.width, &newCellSize.width);
	int rows = 0;
	
	int t = [results count];
	while(t > 0) {
		rows++;
		t -= cols;
	}
	
	[self setCellSize:NSMakeSize(minSize.height, minSize.width)];

	if([self numberOfRows] != rows || [self numberOfColumns] != cols) {
		[self renewRows:rows columns:cols];
				
		if(selection) {
			int row = 0;
			int column = 0;
			[self getRow:&row column:&column ofCell:selection];
			[self selectCellAtRow:row column:column];
		}		
		
		// sort grid here!
	}
}

- (void)setGridSize:(NSSize)size
{
	minSize = size;
	minSize.height++;
	minSize.width++;
	
	[self refreshGrid];
	[self setNeedsDisplay:YES];
}

- (void)setDocument:(MyDocument*)doc
{
	document = doc;
}

- (void)setFrame:(NSRect)frame
{
	NSCell* selection = nil;
	
	NSArray* cells = [self cells];
	NSEnumerator* cellEnumerator = [cells objectEnumerator];
	NSCell* cell;
	while(cell = [cellEnumerator nextObject]) {
		if([cell state] == NSOnState) {
			selection = cell;
			break;
		}
	}

	[super setFrame:frame];
	
	[self retileGrid];

	frame.size.height = (float)[self numberOfRows] * minSize.height;
	[super setFrame:frame];

	if(selection) {
		int row = 0;
		int column = 0;
		[self getRow:&row column:&column ofCell:selection];
		[self scrollCellToVisibleAtRow:row column:column];
	}		
}

- (void)clickThumbnail:(id)sender
{
	[self deselectAllCells];

	if(document)
		[document select:sender];
}

- (void)mouseDown:(NSEvent *)theEvent
{	
	[super mouseDown:theEvent];

	if([theEvent clickCount] == 2) {
		if(([theEvent modifierFlags] & NSControlKeyMask) != 0)
			[scanPageButton performClick:self];
		else if(([theEvent modifierFlags] & NSCommandKeyMask) != 0)
			[scanLinkButton performClick:self];
		else if(([theEvent modifierFlags] & NSAlternateKeyMask) != 0)
			[scanFolderButton performClick:self];
		else
			[openImageButton performClick:self];
	}
	else if([theEvent clickCount] == 3) {
		[[self window] makeKeyAndOrderFront:self];
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
	switch([theEvent keyCode]) {
		case 0x24:
		case 0x4C:
			[openImageButton performClick:self];
			break;
			
		case 0x73:
		{
			NSArray* cells = [self cells];
			if([cells count]) {
				int row = 0;
				int column = 0;
				[self getRow:&row column:&column ofCell:[cells objectAtIndex:0]];
				[self selectCellAtRow:row column:column];
			}
			
			break;
		}
	
		case 0x77:
		{
			NSCell* selection = nil;

			NSArray* cells = [self cells];
			NSEnumerator* cellEnumerator = [cells objectEnumerator];
			NSCell* cell;
			while(cell = [cellEnumerator nextObject]) {
				if([cell isEnabled] == YES) {
					selection = cell;
				}
			}

			if(selection) {
				int row = 0;
				int column = 0;
				[self getRow:&row column:&column ofCell:selection];
				[self selectCellAtRow:row column:column];
			}
			
			break;
		}
	
		case 0x35:
			[document handleEngine:self];
			break;
	
		default:
			[super keyDown:theEvent];
	}
}
	
- (void)actionOpenImage:(id)sender
{
	NSCell* selection = [self getSelection];

	if(selection) {
		ImageResult* result = (ImageResult*) [selection image];
		if(result)
			[result view];
	}
}

- (void)actionScanFolder:(id)sender
{
	NSCell* selection = [self getSelection];

	if(selection) {
		ImageResult* result = (ImageResult*) [selection image];
		NSString* imageURL = [result imageURL];
		
		if(result && imageURL) {
			NSRange lastPath =  [imageURL rangeOfString:@"/" options:NSBackwardsSearch];
			if(lastPath.location != NSNotFound) {
				NSString* folderURL = [imageURL substringToIndex:lastPath.location + 1];
			
				if(folderURL) {
					NSDocumentController* dc = [NSDocumentController sharedDocumentController];
					NSDocument* newDocument = nil;
					
					if([dc respondsToSelector:@selector(openUntitledDocumentAndDisplay:error:)])
						newDocument = [dc openUntitledDocumentAndDisplay:NO error:nil];
					else {
						newDocument = [[MyDocument alloc] init];

						if(newDocument)
							[dc addDocument:newDocument];
					}
					
					if(newDocument) {
						[newDocument makeWindowControllers];
						[newDocument showWindows];

						[(MyDocument*)newDocument startScan:folderURL];
					}
				}
			}
		}
	}
}

- (void)actionScanPage:(id)sender
{
	NSCell* selection = [self getSelection];

	if(selection) {
		ImageResult* result = (ImageResult*) [selection image];
		if(result && [result pageURL]) {
			NSDocumentController* dc = [NSDocumentController sharedDocumentController];
			NSDocument* newDocument = nil;
			
			if([dc respondsToSelector:@selector(openUntitledDocumentAndDisplay:error:)])
				newDocument = [dc openUntitledDocumentAndDisplay:NO error:nil];
			else {
				newDocument = [[MyDocument alloc] init];

				if(newDocument)
					[dc addDocument:newDocument];
			}

			if(newDocument) {
				[newDocument makeWindowControllers];
				[newDocument showWindows];

				[(MyDocument*)newDocument startScan:[result pageURL]];
			}
		}
	}
}

- (void)actionScanLink:(id)sender
{
	NSCell* selection = [self getSelection];

	if(selection) {
		ImageResult* result = (ImageResult*) [selection image];
		NSString* linkURL = [result linkURL];

		if(result && linkURL) {
			if([BrowserController URLHasImageExtension:linkURL]) {
				if(linkResults == nil)
					linkResults = [[NSMutableDictionary alloc] init];
				
				ImageResult* linkResult = [linkResults objectForKey:linkURL];
					
				if(linkResult == nil) {
					linkResult = [[ImageResult alloc] init];
					[linkResult setDelegate:[result delegate]];
					[linkResult setImageURL:linkURL];
					[linkResult setRequiresPreview:YES];
					
					[linkResults setObject:linkResult forKey:linkURL];
				}

				[linkResult view];

				return;
			}
			
			NSDocumentController* dc = [NSDocumentController sharedDocumentController];
			NSDocument* newDocument = nil;
			
			if([dc respondsToSelector:@selector(openUntitledDocumentAndDisplay:error:)])
				newDocument = [dc openUntitledDocumentAndDisplay:NO error:nil];
			else {
				newDocument = [[MyDocument alloc] init];

				if(newDocument)
					[dc addDocument:newDocument];
			}

			if(newDocument) {
				[newDocument makeWindowControllers];
				[newDocument showWindows];

				[(MyDocument*)newDocument startScan:linkURL];
			}
		}
	}
}

- (void)actionVerify:(id)sender
{
	NSCell* selection = [self getSelection];
	
	if(selection) {
		ImageResult* result = (ImageResult*) [selection image];
		if(result) {
			[result verify:self];
		}
	}
}

- (void)actionDownload:(id)sender
{
	NSCell* selection = [self getSelection];
	
	if(selection) {
		ImageResult* result = (ImageResult*) [selection image];
		if(result) {
			[result download];
		}
	}
}

- (NSCell*)getSelection
{
	NSCell* selection = nil;
	
	NSArray* cells = [self cells];
	NSEnumerator* cellEnumerator = [cells objectEnumerator];
	NSCell* cell;
	while(cell = [cellEnumerator nextObject]) {
		if([cell state] == NSOnState) {
			selection = cell;
			break;
		}
	}
	
	return selection;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if([item action] == @selector(selectAll:)) {
		return NO;
	}

	if([item action] == @selector(actionVerify:)) {
		NSCell* selection = [self getSelection];
		
		if(selection) {
			ImageResult* result = (ImageResult*) [selection image];
			if([result requiresPreview] == NO || [result missingPreview] || [result checkingPreview] || [result preview] || [result testedPreview]) {
				return NO;
			}
		}
	}

	if([item action] == @selector(actionOpenImage:) || [item action] == @selector(actionDownload:)) {
		NSCell* selection = [self getSelection];
		
		if(selection) {
			ImageResult* result = (ImageResult*) [selection image];
			if([result requiresPreview] && [result missingPreview])
				return NO;
		}
	}
		
	return YES;
}


@end
