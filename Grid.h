//
//  Grid.h
//  Beholder
//
//  Created by Danny Espinoza on 10/16/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"
#import "ImageResult.h"


@interface Grid : NSMatrix {
	MyDocument* document;

	NSSize minSize;
	NSMutableArray* results;
	NSMutableDictionary* linkResults;
	
	IBOutlet NSButton* openImageButton; // dbl
	IBOutlet NSButton* scanPageButton; // cmd dbl
	IBOutlet NSButton* scanLinkButton; // shift dbl
	IBOutlet NSButton* scanFolderButton; // option dbl
}

- (void)setDocument:(MyDocument*)doc;

- (NSMutableArray*)getResults;
- (NSMutableDictionary*)getLinkResults;

- (NSMutableArray*)getResultsNeedingVerification;
- (NSMutableArray*)getResultsDownloadable;
- (BOOL)areResultsBroken;

- (void)setResults:(NSMutableArray*)newResults;
- (BOOL)addResult:(ImageResult*)newResult;

- (void)resetGrid;
- (void)syncGrid:(NSMutableArray*)newResults;
- (void)resyncGrid;
- (void)refreshGrid;
- (void)retileGrid;
- (void)setGridSize:(NSSize)size;

- (void)clickThumbnail:(id)sender;

- (void)actionOpenImage:(id)sender;
- (void)actionScanFolder:(id)sender;
- (void)actionScanPage:(id)sender;
- (void)actionScanLink:(id)sender;
- (void)actionVerify:(id)sender;
- (void)actionDownload:(id)sender;

- (NSCell*)getSelection;

@end

