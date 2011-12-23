//
//  CURLguiAppDelegate.m
//  CURLgui
//
//  Created by keefo on 10-03-27.
//  Copyright 2010 __Beyondcow Inc__. All rights reserved.
//

#import "CURLguiAppDelegate.h"

@implementation CURLguiAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	lock=[[NSLock alloc] init];
	tableData=[[NSMutableArray alloc] init];
	timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target: self selector: @selector(tableViewReload:) userInfo: nil repeats:YES];
}
- (void)dealloc {
	// Insert code here to initialize your application
	[timer invalidate];
	timer=nil;
	[lock release];
	[tableData release];
	[super dealloc];
}

- (void)tableViewReload:(id)sender
{
	if([tableView lockFocusIfCanDraw]){
		[tableView reloadData];
		[tableView display];
		[tableView unlockFocus];
	}
}

- (void)downloadFile:(NSMutableDictionary *)r
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: @"/usr/bin/curl"];
	NSArray *arguments = [NSArray arrayWithObjects: @"-o", [NSString stringWithFormat:@"%@/Downloads/%@",NSHomeDirectory(),[r objectForKey:@"name"]], [r objectForKey:@"url"], nil];
	[task setArguments: arguments];
	NSPipe *errpipe = [NSPipe pipe];
	[task setStandardError:errpipe];
	NSFileHandle *errfile = [errpipe fileHandleForReading];
	[task launch];
	int i=0;
	char useless[64],progress[64],xferd[64],total[64],received[64],dspeed[64],uspeed[64],spenttime[64],totaltime[64],lefttime[64],speed[64];
	char temp[1024];
	[r setObject:@"running" forKey:@"status"];
	while (1) {
		[NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow:1]];
		if ([r objectForKey:@"op"]!=nil) {
			[r setObject:@"--:--:--" forKey:@"lefttime"];
			[task terminate];
			break;
		}
		NSData *data=[errfile availableData];
		if ([data length]>0) {
			NSString *errs=[[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
			errs = [errs stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			memset(temp,0,1024*sizeof(char));
			strcpy(temp,[errs cStringUsingEncoding:NSASCIIStringEncoding]);
			sscanf(temp,"%s %s %s %s %s %s %s %s %s %s %s %s", progress, total, useless,  received, useless, xferd, dspeed, uspeed, totaltime, spenttime, lefttime,  speed);

			NSString *str=[NSString stringWithCString:progress encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"progress"];

			str=[NSString stringWithCString:total encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"total"];
			
			str=[NSString stringWithCString:received encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"received"];
			
			str=[NSString stringWithCString:xferd encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"xferd"];
		
			str=[NSString stringWithCString:dspeed encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"dspeed"];
			
			str=[NSString stringWithCString:uspeed encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"uspeed"];
			
			str=[NSString stringWithCString:totaltime encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"totaltime"];
			
			str=[NSString stringWithCString:spenttime encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"spenttime"];
			
			str=[NSString stringWithCString:lefttime encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"lefttime"];
			
			str=[NSString stringWithCString:speed encoding:NSASCIIStringEncoding];
			if (str!=nil)[r setObject:str forKey:@"speed"];
			
			NSString *pro=[NSString stringWithCString:progress encoding:NSASCIIStringEncoding];
			if ([pro intValue]==100) {
				break;
			}
		}else {
			i++;
			if (i>10) {
				[r setObject:@"100" forKey:@"progress"];
				[r setObject:[r objectForKey:@"total"] forKey:@"received"];
				[r setObject:@"--:--:--" forKey:@"lefttime"];
				break;
			}
		}
	}
	[r setObject:@"stop" forKey:@"status"];
	[pool release];
}

- (IBAction)downloadAction:(id)sender
{
	NSArray *urllist=[[urlField stringValue] componentsSeparatedByString:@"\n"];
	NSEnumerator *e=[urllist objectEnumerator];
	NSString *url;
	while ((url=[e nextObject])!=nil) {
		if ([url length]>10) {
			NSMutableDictionary *r=[[NSMutableDictionary alloc] init];
			[r setObject:url forKey:@"url"];
			[r setObject:[url lastPathComponent] forKey:@"name"];
			[lock lock];
			[tableData addObject:r];
			[lock unlock];
			[r release];
			[NSThread detachNewThreadSelector:@selector(downloadFile:) toTarget:self withObject:r];
		}
	}
}
- (IBAction)startAction:(id)sender
{
	NSEnumerator *e = [tableView selectedRowEnumerator];
	NSNumber *index;
	while ((index=[e nextObject])!=nil) {
		NSMutableDictionary *r=[tableData objectAtIndex:[index intValue]];
		[r removeObjectForKey:@"op"];
		if (![@"running" isEqualToString:[r objectForKey:@"status"]]) {
			[NSThread detachNewThreadSelector:@selector(downloadFile:) toTarget:self withObject:r];			
		}
	}
}

- (IBAction)stopAction:(id)sender
{
	NSEnumerator *e = [tableView selectedRowEnumerator];
	NSNumber *index;
	while ((index=[e nextObject])!=nil) {
		NSMutableDictionary *r=[tableData objectAtIndex:[index intValue]];
		[r setObject:@"stop" forKey:@"op"];
	}
}

#pragma mark -
#pragma mark - NSTableView Delegate

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [tableData count];
}

- (id)tableView: (NSTableView *)theTableView objectValueForTableColumn: (NSTableColumn *)theColumn row: (int)rowIndex
{
	if (!(rowIndex >= 0 && rowIndex < [tableData count])) {
		return nil;
	}
	NSDictionary *p=[tableData objectAtIndex:rowIndex];
	return [p objectForKey:[theColumn identifier]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)row
{
	return YES;
}

#pragma mark -
#pragma mark - Application Delegate

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication 
					hasVisibleWindows:(BOOL)flag
{
	return NO;
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
	return YES;
}
@end
