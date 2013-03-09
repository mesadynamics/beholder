//
//  Thumbnail.h
//  Beholder
//
//  Created by Danny Espinoza on 10/19/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Grid.h"
#import "CTGradient.h"


@interface Thumbnail : NSImageCell {
	SInt32 macVersion;
	CTGradient* gradient;	
	Grid* grid;
	
	int tag;
}

- (void)setGrid:(Grid*)owner;

@end
