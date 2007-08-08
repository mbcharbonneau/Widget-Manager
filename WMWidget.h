//
//  WMWidget.h
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WMWidget : NSObject
{
	NSString *_identifier;
	NSString *_name;
	NSString *_version;
	NSString *_path;
}

+ (id)widgetWithPath:(NSString *)filepath;
- (id)initWithPath:(NSString *)filepath;

- (void)open;
- (void)reveal;
- (BOOL)isEnabled;
- (BOOL)isAppleWidget;

- (NSString *)identifier;
- (NSString *)name;
- (NSString *)version;
- (NSString *)path;

- (NSImage *)image;
- (NSURL *)website;

@end
