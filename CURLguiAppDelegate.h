//
//  CURLguiAppDelegate.h
//  CURLgui
//
//  Created by liam on 10-03-27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CURLguiAppDelegate : NSObject{
    IBOutlet	NSWindow	*window;
	IBOutlet	NSTextField	*urlField;
	NSLock					*lock;
	IBOutlet	NSTableView	*tableView;
	NSMutableArray			*tableData;
	NSTimer					*timer;
}

- (IBAction)startAction:(id)sender;
- (IBAction)downloadAction:(id)sender;
- (IBAction)stopAction:(id)sender;

@end
