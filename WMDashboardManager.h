//
//  WMDashboardManager.h
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WMWidget;

@interface WMDashboardManager : NSObject
{
	NSArray *_runningWidgetPaths;
}

+ (id)sharedManager;

- (void)killDock;
- (void)refresh;
- (BOOL)isWidgetRunning:(WMWidget *)widget;

@end