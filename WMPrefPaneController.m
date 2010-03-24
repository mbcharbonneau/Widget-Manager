//
//  WMPrefPaneController.m
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "WMPrefPaneController.h"
#import "WMDashboardManager.h"
#import "WMManager.h"
#import "WMWidget.h"

static NSImage *appleIcon = nil;
static NSImage *runningIcon = nil;

@implementation WMPrefPaneController

#pragma mark API

- (void)reloadMainView;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	WMManager *manager = [WMManager sharedManager];
	
	[[WMDashboardManager sharedManager] refresh];
	[manager scan];
	
	NSString *format = NSLocalizedStringFromTableInBundle( @"%ld installed, %ld enabled.", nil, [NSBundle bundleForClass:[self class]], @"" );
	[widgetCount setStringValue:[NSString stringWithFormat:format, (long)[manager widgetsCount], (long)[manager enabledWidgetsCount]]];
	[tableView reloadData];
		
	if ( [tableView selectedRow] != -1 )
	{
		WMWidget *widget = [[[WMManager sharedManager] widgets] objectAtIndex:[tableView selectedRow]];
				
		if ( [widget isEnabled] )
			[disableButton setTitle:NSLocalizedStringFromTableInBundle( @"Disable", nil, [NSBundle bundleForClass:[self class]], @"" )];
		else
			[disableButton setTitle:NSLocalizedStringFromTableInBundle( @"Enable", nil, [NSBundle bundleForClass:[self class]], @"" )];
	
		// Reload any info text fields that may have changed since the last
		// refresh.
		
		[pathField setStringValue:[widget path]];
	}
	
	[pool release];
}

#pragma mark Action Methods

- (IBAction)search:(id)sender;
{
	NSString *searchString = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet symbolCharacterSet]];
	NSPredicate *predicate = nil;
	
	if ( ( searchString != nil ) && ( ![searchString isEqualToString:@""] ) )
	{
		predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF.name contains[cd] '%@'", searchString]];
	}
	
	[[WMManager sharedManager] setFilter:predicate];
	[self reloadMainView]; 
}

- (IBAction)openSelected:(id)sender;
{
	NSInteger row = [tableView selectedRow];
	
	if ( row >= 0 )
	{
		WMWidget *widget = [[[WMManager sharedManager] widgets] objectAtIndex:row];
		[widget open];
	}
}

- (IBAction)revealSelected:(id)sender;
{
	NSInteger row = [tableView selectedRow];
	
	if ( row >= 0 )
	{
		WMWidget *widget = [[[WMManager sharedManager] widgets] objectAtIndex:row];
		[widget reveal];
	}
}

- (IBAction)disableOrEnableSelected:(id)sender;
{
	NSInteger row = [tableView selectedRow];
	
	if ( row >= 0 )
	{
		WMManager *manager = [WMManager sharedManager];
		WMWidget *widget = [[manager widgets] objectAtIndex:row];
		
		if ( [widget isEnabled] )
		{
			[manager disableWidget:widget];
		}
		else
		{
			[manager enableWidget:widget];
		}
		
		[self reloadMainView];
	}
}

- (IBAction)removeSelected:(id)sender;
{
	NSInteger row = [tableView selectedRow];
	
	if ( row >= 0 )
	{
		WMManager *manager = [WMManager sharedManager];
		WMWidget *widget = [[manager widgets] objectAtIndex:row];
		
		[manager removeWidget:widget];
		[tableView deselectAll:self];
		[self reloadMainView];
	}
}

- (IBAction)reloadDashboard:(id)sender;
{
	[[WMDashboardManager sharedManager] killDock];
}

/*	Note: I'm keeping these seperate, just in case I want to create additional
functionality here in the future. */

- (IBAction)openWebsite:(id)sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.downtownsoftwarehouse.com/software/WidgetManager/"]];
}

- (IBAction)getSupport:(id)sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.downtownsoftwarehouse.com/software/WidgetManager/support/"]];
}

- (IBAction)sendFeedback:(id)sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:m.charbonneau@downtownsoftwarehouse.com?SUBJECT=Widget%20Manager%20Feedback"]]; 	
}

#pragma mark NSPreferencePane Overrides

- (void)mainViewDidLoad;
{
	NSImage *icon = [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"ActionGear" ofType:@"tiff"]];
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:icon];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[actionButton cell] setMenuItem:item];
	
	[icon release];
	[item release];
	
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(openSelected:)];
	[tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	
	// Create the table view Widget menu.
	
	NSMenu *menu = [[NSMenu alloc] init];
	
	NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle( @"Open Widget", nil, [NSBundle bundleForClass:[self class]], @"" ) action:@selector(openSelected:) keyEquivalent:@""];
	NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle( @"Reveal In Finder", nil, [NSBundle bundleForClass:[self class]], @"" ) action:@selector(revealSelected:) keyEquivalent:@""];
	NSMenuItem *item3 = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle( @"Move To Trash", nil, [NSBundle bundleForClass:[self class]], @"" ) action:@selector(removeSelected:) keyEquivalent:@""];
	
	[item1 setTarget:self];
	[item2 setTarget:self];
	[item3 setTarget:self];
	
	[menu addItem:item1];
	[menu addItem:item2];
	[menu addItem:item3];
	
	[tableView setMenu:menu];
	
	[menu release];
	[item1 release];
	[item2 release];
	[item3 release];
	
	// Set a timer to rescan the filesystem and reload the dashboard defaults plist.
	
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(reloadMainView) userInfo:nil repeats:YES];
	[timer fire];
	
	if ( [tableView numberOfRows] > 1 )
	{
		[tableView selectRow:0 byExtendingSelection:NO];
	}
}

#pragma mark NSObject Overrides

+ (void)initialize;
{
	appleIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:@"AppleWidget" ofType:@"tiff"]];
	runningIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:@"RunningWidget" ofType:@"tiff"]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
	SEL selector = [menuItem action];
	NSInteger row = [tableView selectedRow];
	WMWidget *widget = ( row != -1 ) ? [[[WMManager sharedManager] widgets] objectAtIndex:row] : nil;
	
	if ( selector == @selector(openSelected:) )
		return ( row != -1 && [widget isEnabled] );
	else if ( selector == @selector(revealSelected:) )
		return ( row != -1 );
	else if ( selector == @selector(removeSelected:) )
		return ( row != -1 );
	
	return YES;
}

#pragma mark NSTableView Data Source Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
{
	return [[[WMManager sharedManager] widgets] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{
	WMWidget *widget = [[[WMManager sharedManager] widgets] objectAtIndex:rowIndex];
	NSString *identifier = [aTableColumn identifier];
	
	if ( [identifier isEqualToString:@"enabled"] )
	{
		return [NSNumber numberWithBool:[widget isEnabled]];
	}
	else if ( [identifier isEqualToString:@"appleWidget"] )
	{
		return [widget isAppleWidget] ? appleIcon : nil;
	}
	else if ( [identifier isEqualToString:@"name"] )
	{
		return [widget name];
	}
	else if ( [identifier isEqualToString:@"version"] )
	{
		return [widget version];
	}
	else if ( [identifier isEqualToString:@"path"] )
	{
		return [widget path];
	}
	else if ( [identifier isEqualToString:@"running"] )
	{
		return [[WMDashboardManager sharedManager] isWidgetRunning:widget] ? runningIcon : nil;
	}
	
	return nil;
}

#pragma mark NSTableView Delegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger row = [tableView selectedRow];
	BOOL enabled = NO;
	NSImage *image = nil;
	NSString *name = @"";
	NSString *path = @"";
	NSURL *websiteURL = nil;
		
	if ( row != -1 )
	{
		WMWidget *widget = [[[WMManager sharedManager] widgets] objectAtIndex:row];
		enabled = YES;
		
		if ( [widget isEnabled] )
			[disableButton setTitle:NSLocalizedStringFromTableInBundle( @"Disable", nil, [NSBundle bundleForClass:[self class]], @"" )];
		else
			[disableButton setTitle:NSLocalizedStringFromTableInBundle( @"Enable", nil, [NSBundle bundleForClass:[self class]], @"" )];
		
		image = [widget image];
		name = [widget name];
		path = [widget path];
		websiteURL = [widget website];
	}
	
	// Set the info viewer selection. This would be a good place to introduce bindings
	// to the application, if I decide to go that route in the future.
	
	[iconView setImage:image];
	[nameField setStringValue:name];
	[pathField setStringValue:path];
	[websiteField setObjectValue:websiteURL];
	
	[disableButton setEnabled:enabled];
	[removeButton setEnabled:enabled];
}

- (void)tableView:(NSTableView *)view didClickTableColumn:(NSTableColumn *)tableColumn
{
	NSSortDescriptor *sort = [tableColumn sortDescriptorPrototype];
	WMManager *manager = [WMManager sharedManager];
	
	[manager setSort:( [sort isEqual:[manager sort]] ) ? [sort reversedSortDescriptor] : sort];
	[view deselectAll:self];
	[view reloadData];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation;
{
	NSString *identifier = [aTableColumn identifier];
	WMWidget *widget = [[[WMManager sharedManager] widgets] objectAtIndex:row];
	NSString *toolTip = nil;
	
	// New delegate method for 10.4! Return a useful tooltip if needed.

	if ( [identifier isEqualToString:@"appleWidget"] )
	{
		if ( [widget isAppleWidget] )
			toolTip = NSLocalizedStringFromTableInBundle( @"Created by Apple Computer, Inc.", nil, [NSBundle bundleForClass:[self class]], @"" );
	}
	else if ( [identifier isEqualToString:@"path"] )
	{
		toolTip = [widget path];
	}
	else if ( [identifier isEqualToString:@"running"] )
	{
		if ( [[WMDashboardManager sharedManager] isWidgetRunning:widget] )
			toolTip = NSLocalizedStringFromTableInBundle( @"Widget is running in Dashboard", nil, [NSBundle bundleForClass:[self class]], @"" );
	}
	
	return toolTip;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation;
{
	NSDragOperation acceptDrop = NSDragOperationNone;
	NSPasteboard *pboard;
	
    pboard = [info draggingPasteboard];
	if ( [[pboard types] containsObject:NSFilenamesPboardType] )
	{
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		NSEnumerator *oe = [files objectEnumerator];
		NSString *fileName;
		
		// Validate the dragged files:
		
		while ( fileName = [oe nextObject] )
		{
			if ( [[fileName pathExtension] caseInsensitiveCompare:@"wdgt"] == NSOrderedSame ||
				 [[fileName pathExtension] caseInsensitiveCompare:@"disabled"] == NSOrderedSame )
			{
				[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
				acceptDrop = NSDragOperationCopy;
				break;
			}
		}
	}
	
	return acceptDrop;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation;

{
	NSPasteboard *pboard = [info draggingPasteboard]; 
	
	if ( [[pboard types] containsObject:NSFilenamesPboardType] )
	{
		NSEnumerator *enumerator = [[pboard propertyListForType:NSFilenamesPboardType] objectEnumerator];
		NSString *filename;

		while ( filename = [enumerator nextObject] )
		{
			WMWidget *widget = [WMWidget widgetWithPath:filename];
			
			if ( widget != nil )
			{
				[[WMManager sharedManager] installWidget:widget];
			}
			
			[self reloadMainView];
		}
	}
	return YES;
}

@end
