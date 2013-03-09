//
//  SearchController.m
//  Beholder
//
//  Created by Danny Espinoza on 12/21/06.
//  Copyright 2006 Mesa Dynamics, LLC. All rights reserved.
//

#import "SearchController.h"


@implementation SearchController

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [NSString stringWithFormat:@"%@ Search", displayName];
}

@end
