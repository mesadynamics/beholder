//
//  GradientView.h
//  Beholder
//
//  Created by Danny Espinoza on 9/29/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CTGradient.h"

@interface GradientView : NSView {
	SInt32 macVersion;
	CTGradient* gradient;
}

@end
