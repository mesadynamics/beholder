//
//  Details.m
//  Beholder
//
//  Created by Danny Espinoza on 10/23/06.
//  Copyright 2006 Messa Dynamics, LLC. All rights reserved.
//

#import "Details.h"


@implementation Details

- (void)copy:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *string = nil;
     
    switch ([self numberOfSelectedRows])
    {
        case 0:
            return;
        
        default:
        {
            id selection = [self selectedRowIndexes];
            int index = [selection firstIndex]; 
            
			string = [NSString stringWithFormat: @"%@", 
				[[self dataSource] 
					tableView: self
					objectValueForTableColumn: 
						[[self tableColumns] objectAtIndex: 1]
					row: index]];
        }
    }
       
	if(string && [string length]) {	   
		[pb 
			declareTypes: [NSArray arrayWithObject:NSStringPboardType] 
			owner:nil];
			
		[pb setString:string
			 forType: NSStringPboardType];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	
	if([theEvent clickCount] == 2) {
		id selection = [self selectedRowIndexes];
		int index = [selection firstIndex]; 
			
		NSString* string = [NSString stringWithFormat: @"%@", 
			[[self dataSource] 
				tableView: self
				objectValueForTableColumn: 
					[[self tableColumns] objectAtIndex: 1]
				row: index]];
				
		if(string && [string length] && ([string hasPrefix:@"http://"] || [string hasPrefix:@"https://"])) {		
			NSURL* target = [NSURL URLWithString:string];
			if(target)
				LSOpenCFURLRef((CFURLRef) target, NULL);
		}
	}
}

@end
