//
//  WMWidget.m
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "WMWidget.h"

@implementation WMWidget

static NSArray *_tlds = nil;
static NSArray *_appleBlacklistIdentifiers = nil;

#pragma mark API

+ (id)widgetWithPath:(NSString *)filepath;
{
	id widget = [[self alloc] initWithPath:filepath];
	return [widget autorelease];
}

- (id)initWithPath:(NSString *)filepath;
{
	NSString *plistPath = [filepath stringByAppendingPathComponent:@"Info.plist"];
	NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	
	if ( !infoDict || ![super init] )
	{
		[self release];
		return nil;
	}
	
	NSString *displayName = [infoDict objectForKey:@"CFBundleDisplayName"];
	
	_path = [filepath copy];
	_identifier = [[infoDict objectForKey:@"CFBundleIdentifier"] copy];
	_name = ( displayName != nil ) ? [displayName copy] : [[infoDict objectForKey:@"CFBundleName"] copy];
	_version = [[infoDict objectForKey:@"CFBundleVersion"] copy];
	
	// Use the file path if the name does not exist.
	
	if ( !_name )
		_name = [filepath copy];

	return self;
}

- (void)open;
{
	if ( [self isEnabled] )
	{
		[[NSWorkspace sharedWorkspace] openFile:[self path]];
	}
	else
	{
		NSBeep();
	}
}

- (void)reveal;
{
	[[NSWorkspace sharedWorkspace] selectFile:[self path] inFileViewerRootedAtPath:[[self path] stringByDeletingLastPathComponent]];
}

- (BOOL)isEnabled;
{
	return ( [[[self path] pathExtension] caseInsensitiveCompare:@"wdgt"] == NSOrderedSame );
}

- (BOOL)isAppleWidget;
{
	NSString *identifier = [self identifier];
	return ( [identifier hasPrefix:@"com.apple.widget."] && ![_appleBlacklistIdentifiers containsObject:identifier] );
}

#pragma mark Accessor Methods

- (NSString *)identifier;
{
	return _identifier;
}

- (NSString *)name;
{
	return _name;
}

- (NSString *)version;
{
	return _version;
}

- (NSString *)path;
{
	return _path;
}

- (NSImage *)image;
{
	NSString *path = [[self path] stringByAppendingPathComponent:@"Icon.png"];
	NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	
	if ( image == nil )
	{
		image = [[NSWorkspace sharedWorkspace] iconForFileType:@"wdgt"];
		[image setSize:NSMakeSize( 64, 64 )];
	}
	
	return image;
}

- (NSURL *)website;
{
	// Create a URL based on the identifier. This method seems to be 
	// "pretty good" at finding a working URL, but is not guaranteed valid.
	
	NSArray *components = [[self identifier] componentsSeparatedByString:@"."];
	
	if ( [components count] < 2 )
		return nil;
	
	if ( ![_tlds containsObject:[[components objectAtIndex:0] uppercaseString]] )
		return nil;
	
	if ( [[components objectAtIndex:1] caseInsensitiveCompare:@"apple"] == NSOrderedSame && ![self isAppleWidget] )
		return nil;
	
	NSString *format = ( [components count] > 2 && [[components objectAtIndex:2] isEqualToString:@"www"] ) ? @"http://www.%@.%@" : @"http://%@.%@";
	NSString *string = [NSString stringWithFormat:format, [components objectAtIndex:1], [components objectAtIndex:0]];
	NSURL *url = [NSURL URLWithString:string];
	
	return url;
}

#pragma mark NSObject Overrides

+ (void)initialize;
{
	// Create the list of top level domains to use in the website detection
	// method. This functionality would be best suited for a different class,
	// but this is all likely to change soon anyway, so I'm leaving it in for
	// the time being.
	
	NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"tlds" ofType:@"txt"];
	NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	_tlds = [[contents componentsSeparatedByString:@"\n"] retain];
	
	// The following identifiers are not from Apple Computer Inc, no matter
	// what they claim!
	
	_appleBlacklistIdentifiers = [[NSArray alloc] initWithObjects:
		@"com.apple.widget.wikipedia",
		@"com.apple.widget.tvtracker",
		@"com.apple.widget.buzztracker",
		@"com.apple.widget.protparam",
		@"com.apple.widget.rebase",
		@"com.apple.widget.skype", 
		@"com.apple.widget.zipcoder",
		@"com.apple.widget.coconutBattery",
		@"com.apple.widget.NetStat",
		@"com.apple.widget.voices",
		@"com.apple.widget.style", nil];
}

- (void)dealloc;
{
	[_identifier release];
	[_name release];
	[_version release];
	[_path release];

	[super dealloc];
}

@end
