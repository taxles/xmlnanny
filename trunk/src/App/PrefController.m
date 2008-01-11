//
//  PrefController.m
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/13/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "PrefController.h"
#import "AppDelegate.h"

@interface PrefController (Private)
- (void)showExternalEditorDisplayString;
@end

@implementation PrefController

- (id)init;
{
	self = [super initWithWindowNibName:@"PrefWindow"];
	if (self != nil) {
	}
	return self;
}


- (void)dealloc;
{
	[super dealloc];
}


- (void)windowDidLoad;
{
	[[self window] setShowsResizeIndicator:NO];
	[self showExternalEditorDisplayString];
}


- (void)showExternalEditorDisplayString;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *path = [defaults objectForKey:XNExternalEditorKey];
	
	if (![path length]) {
		[externalEditorPopUpButton selectItemWithTag:0];
		return;
	}
	
	[self setExternalEditorDisplayString:[path lastPathComponent]];
	[externalEditorPopUpButton selectItemWithTag:1];

	NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:path];
	NSImage *img = [wrapper icon];
	[img setSize:NSMakeSize(16, 16)];
	[self setExternalEditorIcon:img];
	[wrapper release];
}


#pragma mark -
#pragma mark Accessors

- (BOOL)playSounds;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [[defaults objectForKey:XNPlaySoundsKey] boolValue];
}


- (void)setPlaySounds:(BOOL)yn;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithBool:yn] forKey:XNPlaySoundsKey];
}


- (BOOL)wrapText;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [[defaults objectForKey:XNWrapTextKey] boolValue];
}


- (void)setWrapText:(BOOL)yn;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithBool:yn] forKey:XNWrapTextKey];
}


- (id)externalEditor;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:XNExternalEditorKey];
}


- (void)setExternalEditor:(id)ed;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:ed forKey:XNExternalEditorKey];
}

- (IBAction)externalEditorChanged:(id)sender;
{
	if (0 == [sender selectedTag]) {
		[self setExternalEditor:@""];
	}
}

- (IBAction)browseForExternalEditor:(id)sender;
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	int res = [panel runModalForDirectory:@"/Applications"
									 file:nil
									types:[NSArray arrayWithObject:@"app"]];
	
	if (NSOKButton == res) {
		NSString *filename = [panel filename];
		[self setExternalEditor:filename];
		[self showExternalEditorDisplayString];
	}
}


- (NSString *)externalEditorDisplayString;
{
	return externalEditorDisplayString;
}


- (void)setExternalEditorDisplayString:(NSString *)newStr;
{
	if (newStr != externalEditorDisplayString) {
		[externalEditorDisplayString autorelease];
		externalEditorDisplayString = [newStr retain];
	}
}


- (NSImage *)externalEditorIcon;
{
	return externalEditorIcon;
}


- (void)setExternalEditorIcon:(NSImage *)newImg;
{
	if (newImg != externalEditorIcon) {
		[externalEditorIcon autorelease];
		externalEditorIcon = [newImg retain];
	}
}

@end
