//
//  AppDelegate.m
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/13/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "AppDelegate.h"
#import "PrefController.h"
#import "CatalogController.h"

NSString * XNPlaySoundsKey		= @"playSounds";
NSString * XNWrapTextKey		= @"wrapText";
NSString * XNExternalEditorKey	= @"externalEditor";

@implementation AppDelegate

+ (void)initialize;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], XNPlaySoundsKey,
		[NSNumber numberWithBool:NO], XNWrapTextKey,
		@"", XNExternalEditorKey,
		nil];
	
	[defaults registerDefaults:dict];
}


- (id)init;
{
	self = [super init];
	if (self != nil) {
		catalogController = [[CatalogController alloc] init];
	}
	return self;
}


- (void)dealloc;
{
	[catalogController release];
	[prefController release];
	[super dealloc];
}



- (IBAction)showPreferencesWindow:(id)sender;
{
	@synchronized (self) {
		if (!prefController) {
			prefController = [[PrefController alloc] init];
		}
	}
	[prefController showWindow:self];
}


- (IBAction)showCatalogWindow:(id)sender;
{
	[catalogController showWindow:self];
}

@end
