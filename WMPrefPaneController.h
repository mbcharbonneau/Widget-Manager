//
//  WMPrefPaneController.h
//  Widget Manager
//
//  Created by Marc Charbonneau on 3/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>

@interface WMPrefPaneController : NSPreferencePane
{
	IBOutlet NSTableView *tableView;
	IBOutlet NSTextField *widgetCount;
	IBOutlet NSPopUpButton *actionButton;
	IBOutlet NSButton *disableButton;
	IBOutlet NSButton *removeButton;
	IBOutlet NSImageView *iconView;
	IBOutlet NSTextField *nameField;
	IBOutlet NSTextField *pathField;
	IBOutlet NSTextField *websiteField;
}

- (void)reloadMainView;

- (IBAction)search:(id)sender;
- (IBAction)openSelected:(id)sender;
- (IBAction)revealSelected:(id)sender;
- (IBAction)disableOrEnableSelected:(id)sender;
- (IBAction)removeSelected:(id)sender;
- (IBAction)reloadDashboard:(id)sender;

- (IBAction)openWebsite:(id)sender;
- (IBAction)getSupport:(id)sender;
- (IBAction)sendFeedback:(id)sender;

@end
