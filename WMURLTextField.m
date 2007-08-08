//
//  WMURLTextField.m
//  Widget Manager
//
//  Created by Marc Charbonneau on 5/29/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "WMURLTextField.h"

@interface WMURLTextField (Private)

- (NSRect)_visibleTextRect;

@end

@implementation WMURLTextField

#pragma mark API

- (void)setURLValue:(NSURL *)URL;
{
	[self setObjectValue:URL];
}

#pragma mark NSTextField Overrides

- (void)setTextColor:(NSColor *)aColor;
{
	// Text color is pre-defined.
	
	if ( ![aColor isEqual:[NSColor blueColor]] )
		return;
	
	[super setTextColor:aColor];
}

#pragma mark NSControl Overrides

- (id)initWithFrame:(NSRect)frameRect
{
	if ( ![super initWithFrame:frameRect] )
		return nil;
	
	[self setTextColor:[NSColor blueColor]];
	
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder;
{
	if ( ![super initWithCoder:decoder] )
		return nil;
	
	[self setTextColor:[NSColor blueColor]];
	
	return self;
}

- (void)setObjectValue:(id <NSCopying>)object;
{
	if ( ![(id)object isKindOfClass:[NSURL class]] && object != nil )
		[NSException raise:@"Invalid Class Expection" format:@"***Invalid object class for WMURLTextField: %@", NSStringFromClass( [(id)object class] )];
	
	[super setObjectValue:object];
}

#pragma mark NSView Overrides

- (void)resetCursorRects;
{
	[self addCursorRect:[self _visibleTextRect] cursor:[NSCursor pointingHandCursor]];
}

#pragma mark NSResponder Overrides

- (void)mouseDown:(NSEvent *)theEvent;
{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if ( NSMouseInRect( point, [self _visibleTextRect], [self isFlipped] ) )
	{
		NSURL *URL = [self objectValue];
		[[NSWorkspace sharedWorkspace] openURL:URL];
	}
}

@end

@implementation WMURLTextField (Private)

- (NSRect)_visibleTextRect;
{
	NSSize size = [[self cell] cellSizeForBounds:[self bounds]];
	NSRect textRect = [self bounds];
	textRect.size = size;
	
	return textRect;
}

@end
