//
//  WMManager.m
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Security/Security.h>
#import "WMManager.h"
#import "WMWidget.h"

static NSString *fileUtilityPath = nil;
static AuthorizationRef authorizationRef = NULL;

@interface WMManager (Private)

- (NSArray *)_widgetFilePaths;
- (BOOL)_checkAuthentication;
- (BOOL)_authenticatedFileMove:(NSString *)source destination:(NSString *)destination;
- (BOOL)_authenticatedFileRecycle:(NSString *)source;

@end

#pragma mark -

@implementation WMManager

#pragma mark API

+ (id)sharedManager;
{
	static id sharedManager = nil;
	
	if ( !sharedManager )
		sharedManager = [[self alloc] init];
	
	return sharedManager;
}

- (void)scan;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *widgets = [NSMutableArray array];
	NSArray *files = [self _widgetFilePaths];
		
	NSEnumerator *enumerator = [files objectEnumerator];
	NSString *filepath;
	
	while ( filepath = [enumerator nextObject] )
	{
		WMWidget *widget = [WMWidget widgetWithPath:filepath];
		if ( widget != nil )
		{
			[widgets addObject:widget];
		}
	}

	[_widgets release];
	_widgets = [widgets copy];
	
	[pool release];
}

- (void)enableWidget:(WMWidget *)widget;
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *destination = [[widget path] stringByDeletingPathExtension];
	NSString *filePath = [widget path];
	BOOL result = NO;
	
	if ( ![manager isDeletableFileAtPath:filePath] && [manager fileExistsAtPath:filePath] )
	{
		result = [self _authenticatedFileMove:filePath destination:destination];
	}
	else
	{
		result = [manager movePath:filePath toPath:destination handler:nil];
	}
	
	if ( !result )
	{
		NSString *title = NSLocalizedStringFromTableInBundle( @"Could not enable Widget", nil, [NSBundle bundleForClass:[self class]], @"" );
		NSString *msg = NSLocalizedStringFromTableInBundle( @"You may not have permission to modify the file, or it may be locked.", nil, [NSBundle bundleForClass:[self class]], @"" );
		
		NSRunAlertPanel( title, msg, nil, nil, nil );
	}
}

- (void)disableWidget:(WMWidget *)widget;
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *destination = [[widget path] stringByAppendingPathExtension:@"disabled"];
	NSString *filePath = [widget path];
	BOOL result = NO;
	
	if ( ![manager isDeletableFileAtPath:filePath] && [manager fileExistsAtPath:filePath] )
	{
		result = [self _authenticatedFileMove:filePath destination:destination];
	}
	else
	{
		result = [manager movePath:filePath toPath:destination handler:nil];
	}

	if ( !result )
	{
		NSString *title = NSLocalizedStringFromTableInBundle( @"Could not disable Widget", nil, [NSBundle bundleForClass:[self class]], @"" );
		NSString *msg = NSLocalizedStringFromTableInBundle( @"You may not have permission to modify the file, or it may be locked.", nil, [NSBundle bundleForClass:[self class]], @"" );
		
		NSRunAlertPanel( title, msg, nil, nil, nil );
	}
}

- (void)installWidget:(WMWidget *)widget;
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *folder = [@"~/Library/Widgets" stringByExpandingTildeInPath];
	NSString *destination = [folder stringByAppendingPathComponent:[[widget path] lastPathComponent]];
	
	// Create the directory if it doesn't exist.
	
	if ( ![manager fileExistsAtPath:folder] )
	{
		[manager createDirectoryAtPath:folder attributes:nil];
	}
	
	if ( [manager fileExistsAtPath:destination] )
	{
		[manager removeFileAtPath:destination handler:nil];
	}
	
	if ( ![manager copyPath:[widget path] toPath:destination handler:nil] )
	{
		NSString *title = NSLocalizedStringFromTableInBundle( @"Could not copy file", nil, [NSBundle bundleForClass:[self class]], @"" );
		NSString *msg = NSLocalizedStringFromTableInBundle( @"The disk may be full, or folder permissions may be incorrect.", nil, [NSBundle bundleForClass:[self class]], @"" );
			
		NSRunAlertPanel( title, msg, nil, nil, nil );
	}
}

- (void)removeWidget:(WMWidget *)widget;
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *filePath = [widget path];
	BOOL result = NO;
	
	if ( ![manager isDeletableFileAtPath:filePath] && [manager fileExistsAtPath:filePath] )
	{
		result = [self _authenticatedFileRecycle:filePath];
	}
	else
	{
		NSArray *files = [NSArray arrayWithObject:[filePath lastPathComponent]];
		NSString *folder = [filePath stringByDeletingLastPathComponent];
		NSInteger tag;
		
		result = [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:folder destination:@"" files:files tag:&tag];	
	}

	if ( !result )
	{
		NSString *title = NSLocalizedStringFromTableInBundle( @"Could not move file to Trash", nil, [NSBundle bundleForClass:[self class]], @"" );
		NSString *msg = NSLocalizedStringFromTableInBundle( @"You may not have permission to modify the file, or it may be locked.", nil, [NSBundle bundleForClass:[self class]], @"" );
		
		NSRunAlertPanel( title, msg, nil, nil, nil );
	}
}

- (NSInteger)widgetsCount;
{
	return [[self widgets] count];
}

- (NSInteger)enabledWidgetsCount;
{
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"SELF.isEnabled == TRUE"];
	NSArray *array = [[self widgets] filteredArrayUsingPredicate:filter];
	
	return [array count];
}

#pragma mark Accessor Methods

- (NSArray *)widgets;
{
	NSArray *widgets = _widgets;
	
	if ( [self filter] != nil )
	{
		widgets = [_widgets filteredArrayUsingPredicate:[self filter]];
	}
	
	if ( [self sort] != nil )
	{
		widgets = [widgets sortedArrayUsingDescriptors:[NSArray arrayWithObject:[self sort]]];
	}
	
	return widgets;
}

- (NSPredicate *)filter;
{
	return _filter;
}

- (NSSortDescriptor *)sort;
{
	return _sort;
}

- (void)setFilter:(NSPredicate *)aPredicate;
{
	if ( _filter != aPredicate )
	{
		[_filter release];
		_filter = [aPredicate retain];
	}
}

- (void)setSort:(NSSortDescriptor *)sortDescriptor;
{
	if ( _sort != sortDescriptor )
	{
		[_sort release];
		_sort = [sortDescriptor retain];
	}
}

#pragma mark NSObject Overrides

+ (void)initialize;
{
	fileUtilityPath = [[[NSBundle bundleForClass:self] pathForResource:@"WMFileUtility" ofType:@""] retain];
}

- (void)dealloc;
{
	[_widgets release];
	[self setFilter:nil];
	[self setSort:nil];
	[super dealloc];
}

@end

#pragma mark -

@implementation WMManager (Private)

- (NSArray *)_widgetFilePaths;
{
	NSMutableArray *widgetPaths = [NSMutableArray array];
	NSArray *searchPaths = [NSArray arrayWithObjects:@"/Library/Widgets", [@"~/Library/Widgets" stringByExpandingTildeInPath], nil];
	
	NSEnumerator *enumerator = [searchPaths objectEnumerator];
	NSString *searchPath;
	
	while ( searchPath = [enumerator nextObject] )
	{
		NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:searchPath];
		NSString *filename;
		NSInteger index;
		
		for ( index = 0; index < [contents count]; index++ )
		{
			filename = [contents objectAtIndex:index];
			
			// I could check the path extention here, but I don't think it's
			// even worth the effort.
			
			[widgetPaths addObject:[searchPath stringByAppendingPathComponent:filename]];
		}
	}

	return widgetPaths;
}

- (BOOL)_checkAuthentication;
{
	OSStatus status = noErr;
	
	if ( authorizationRef == NULL )
	{
		status = AuthorizationCreate( NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef );
	}
	
	return ( status == noErr );
}

- (BOOL)_authenticatedFileMove:(NSString *)source destination:(NSString *)destination;
{
	if ( ![self _checkAuthentication] )
		return NO;
	
	char *path = (char *)[fileUtilityPath UTF8String];
	char *args[4];
	
	args[0] = (char *)[@"move" UTF8String];
	args[1] = (char *)[[source stringByStandardizingPath] UTF8String];
	args[2] = (char *)[[destination stringByStandardizingPath] UTF8String];
	args[3] = NULL;
	
	OSStatus status = AuthorizationExecuteWithPrivileges( authorizationRef, path, 0, args, NULL );
	
	return ( status == noErr );
}

- (BOOL)_authenticatedFileRecycle:(NSString *)source;
{
	if ( ![self _checkAuthentication] )
		return NO;
	
	char *path = (char *)[fileUtilityPath UTF8String];
	char *args[3];
	
	args[0] = (char *)[@"recycle" UTF8String];
	args[1] = (char *)[[source stringByStandardizingPath] UTF8String];
	args[2] = NULL;
	
	OSStatus status = AuthorizationExecuteWithPrivileges( authorizationRef, path, 0, args, NULL );
	
	return ( status == noErr );
}

@end
