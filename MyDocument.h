//
//  MyDocument.h
//  Beholder
//
//  Created by Danny Espinoza on 9/29/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "ImageResult.h"
#import "Batch.h"

@interface MyDocument : NSDocument
{
	IBOutlet NSWindowController* browserController;
	IBOutlet NSMatrix* grid;
	IBOutlet NSScrollView* scroller;
	
	IBOutlet NSBox* searchPanel;
	IBOutlet NSBox* infoPanel;
	IBOutlet NSTextField* statusBar;

	IBOutlet NSButton* details;
	IBOutlet NSButton* openImage;
	IBOutlet NSButton* scanFolder;
	IBOutlet NSButton* scanPage;
	IBOutlet NSButton* scanLink;
	IBOutlet NSButton* lock;

	IBOutlet NSComboBox* searchField;
	IBOutlet NSButton* searchButton;
	IBOutlet NSPopUpButton* engines;
	IBOutlet NSProgressIndicator* wait;
	
	IBOutlet NSImageView* preview;
	IBOutlet NSTableView* info;
	
	IBOutlet NSSlider* thumbsize;
	IBOutlet NSButton* collapse;
	
	IBOutlet NSButton* badges;
	IBOutlet NSButton* broken;
	
	IBOutlet NSTextField* safeTitle;
	IBOutlet NSSegmentedControl* safe;
	IBOutlet NSTextField* sizeTitle;
	IBOutlet NSSegmentedControl* size;
	
	IBOutlet NSImageView* header;
	IBOutlet NSImageView* footer;
	IBOutlet NSImageView* statusIcon;
	
	IBOutlet NSProgressIndicator* batchProgress;
		
	NSWindow* window;
	NSString* lastSearch;
	NSString* saveSearch;
	BOOL searchLocked;
	
	NSString* loadFolder;
	NSMutableArray* load;
	NSString* loadQuery;
	NSString* loadTitle;
	NSString* loadMessage;
	NSString* loadEngineName;
	int loadSafe;
	int loadSize;
	NSString* loadLastSearch;
	NSString* loadMoreEngineName;
	NSArray* loadHistory;
	BOOL loadLocked;
	
	int moreValue;
	int moreEngine;
	int moreSafe;
	int moreSize;
	
	int lastResultCount;
	
	ImageResult* selectedResult;

	NSMutableArray* engineList;
	Batch* batch;
}

- (void)actionSave:(id)sender;
- (void)actionBadges:(id)sender;
- (void)actionBroken:(id)sender;
- (void)actionVerifyAll:(id)sender;
- (void)actionDownloadAll:(id)sender;
- (void)actionClearHistory:(id)sender;
- (void)actionLock:(id)sender;
- (void)actionPlugin:(id)sender;

- (void)actionPreviousEngine:(id)sender;
- (void)actionNextEngine:(id)sender;
- (void)actionRotateSize:(id)sender;
- (void)actionRotateSafe:(id)sender;
- (void)actionSearch:(id)sender;

- (void)startScan:(NSString*)url;
- (void)startSearch:(NSString*)query;

- (NSWindow*)window;

- (IBAction)handleSmaller:(id)sender;
- (IBAction)handleBigger:(id)sender;
- (IBAction)handleCollapse:(id)sender;
- (IBAction)handleThumbsize:(id)sender;
- (IBAction)handleEngine:(id)sender;
- (IBAction)handleSearch:(id)sender;
- (IBAction)handleChange:(id)sender;

- (void)trackResults:(NSMutableArray*)results;
- (void)syncResults:(int)resultCount;

- (void)lock;
- (void)unlock;

- (BOOL)isReady;
- (void)ready;
- (void)ready:(NSString*)message;

- (void)select:(id)sender;

- (void)clearResults;

- (BOOL)badgesAreVisible;
- (BOOL)brokenAreVisible;
- (void)resolveBroken;

- (void)setStatusImage:(NSImage*)image;
- (void)setStatusText:(NSString*)text;

- (NSString*)statusText;

@end
