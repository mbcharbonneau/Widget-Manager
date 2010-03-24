//
//  WMManager.h
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WMWidget;

@interface WMManager : NSObject
{
	NSArray *_widgets;
	NSPredicate *_filter;
	NSSortDescriptor *_sort;
}

+ (id)sharedManager;

- (void)scan;
- (void)enableWidget:(WMWidget *)widget;
- (void)disableWidget:(WMWidget *)widget;
- (void)installWidget:(WMWidget *)widget;
- (void)removeWidget:(WMWidget *)widget;

- (NSInteger)widgetsCount;
- (NSInteger)enabledWidgetsCount;

- (NSArray *)widgets;
- (NSPredicate *)filter;
- (NSSortDescriptor *)sort;

- (void)setFilter:(NSPredicate *)aPredicate;
- (void)setSort:(NSSortDescriptor *)sortDescriptor;

@end
