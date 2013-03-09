//
//  ImageResult.h
//  Beholder
//
//  Created by Danny Espinoza on 10/19/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageController.h"


@interface ImageResult : NSImage {
	unsigned long timestamp;
	
	NSString* origURL;
	NSString* imageURL;
	NSString* pageURL;
	NSString* linkURL;
	
	int imageWidth;
	int imageHeight;
	int imageSize;
	NSString* infoString;
	NSColor* averageColor;
	
	BOOL requiresPreview;
	BOOL testedPreview;
	BOOL missingPreview;
	BOOL infoIsApproximate;
	BOOL infoIsActual;
	
	NSImage* imagePreview;
	NSData* imageData;
		
	ImageController* ic;

	NSURLConnection* session;
	NSMutableData* sessionData;
	BOOL sessionTest;
	BOOL sessionDownload;
	NSString* sessionPath;
}

- (void)commonInit;

- (unsigned long)timestamp;
- (int)imageWidth;
- (int)imageHeight;
- (int)imageSize;

- (NSString*)origURL;
- (NSString*)imageURL;
- (NSString*)pageURL;
- (NSString*)linkURL;
- (NSString*)infoString;
- (NSColor*)averageColor;

- (NSImage*)preview;
- (NSData*)data;

- (void)setOrigURL:(NSString*)url;
- (void)setImageURL:(NSString*)url;
- (void)setPageURL:(NSString*)url;
- (void)setLinkURL:(NSString*)url;
- (void)setImageWidth:(int)width andHeight:(int)height;
- (void)setImageSize:(int)size;
- (void)setTimestamp:(unsigned long)time;

- (BOOL)requiresPreview;
- (void)setRequiresPreview:(BOOL)value;
- (void)setInfoIsApproximate:(BOOL)value;
- (void)setInfoIsActual:(BOOL)value;

- (BOOL)testedPreview;
- (BOOL)missingPreview;
- (BOOL)checkingPreview;
- (BOOL)loadingPreview;
- (BOOL)badgesAreVisible;
- (BOOL)hasWindow;

- (id)poll;

- (void)setImagePreview:(NSImage*)preview;
- (void)setImageData:(NSData*)data;

- (void)calcInfoFromImage;
- (void)buildInfoString;

- (void)verify:(id)sender;
- (void)downloadToFolder:(NSString*)path;
- (void)download;
- (void)save;
- (void)view;

- (NSColor*)calculateAverageColor;

@end

@interface NSObject(ImageResultDelegate)
- (void)didUpdatePreview:(id)sender;
- (void)didUpdateThumbnail:(id)sender;
@end
