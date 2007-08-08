//
//  WMTableView.m
//  Widget Manager
//
//  Created by Marc Charbonneau on 5/29/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "WMTableView.h"


@implementation WMTableView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent;
{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int row = [self rowAtPoint:point];
	
	if ( row != -1 )
	{
		[self selectRow:row byExtendingSelection:NO];
		return [super menuForEvent:theEvent];
	}
	
	return nil;
}

@end
