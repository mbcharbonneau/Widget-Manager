//
//  WMDashboardManager.m
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "WMDashboardManager.h"
#import "WMWidget.h"

@implementation WMDashboardManager

#pragma mark API

+ (id)sharedManager;
{
	static id sharedManager = nil;
	
	if ( !sharedManager )
		sharedManager = [[self alloc] init];
	
	return sharedManager;
}

- (void)killDock;
{
	system( "ps axwww | grep -i CoreServices/Dock.app/Contents/MacOS/Dock | grep -v grep | awk '{print $1}' | xargs kill -3" );
	
	// todo: I should have a better way of finding the dock process. This returns the PID of Dock for all users,
	//       which fails, but is still undesirable.
	
	// For some users the dock will not re-launch automatically; this should take care of that.
	
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.dock" 
														 options:NSWorkspaceLaunchWithoutActivation 
								  additionalEventParamDescriptor:nil
												launchIdentifier:nil];
}

- (void)refresh;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	CFStringRef key = (CFStringRef)@"layer-gadgets";
	CFStringRef appID = (CFStringRef)@"com.apple.dashboard";
	
	CFPreferencesAppSynchronize( appID );
	NSArray *infoArray = (NSArray *)CFPreferencesCopyValue( key, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost );
	NSEnumerator *enumerator = [infoArray objectEnumerator];
	NSDictionary *info;
	
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[infoArray count]];
	
	while ( info = [enumerator nextObject] )
	{
		NSString *path = [info objectForKey:@"path"];
		
		if ( path != nil )
		{
			[paths addObject:[path stringByStandardizingPath]];
		}
	}
	
	[infoArray release];
	
	[_runningWidgetPaths release];
	_runningWidgetPaths = [paths copy];
	
	[pool release];
}

- (BOOL)isWidgetRunning:(WMWidget *)widget;
{
	return [_runningWidgetPaths containsObject:[widget path]];
}

@end
