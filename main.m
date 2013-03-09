//
//  main.m
//  Beholder
//
//  Created by Danny Espinoza on 9/29/06.
//  Copyright Mesa Dynamics, LLC 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#define MallocStackLogging 1

#if defined(MallocStackLogging)
#include <stdlib.h>
void sleepForLeaks(void);
#endif

int main(int argc, char *argv[])
{
#if defined(MallocStackLogging)
	atexit(sleepForLeaks);
#endif
	
    return NSApplicationMain(argc, (const char **) argv);
}

#if defined(MallocStackLogging)
void sleepForLeaks(void)
{
	for(;;)
		sleep(60);
}
#endif
