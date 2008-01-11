//
//  MyDocument.m
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/12/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "MyDocument.h"
#import "MyController.h"

static NSString * const PreferedCatalogItemTypeKey	= @"preferedCatalogItemType";
static NSString * const CatalogItemsKey				= @"catalogItems";
static NSString * const WindowFrameStringKey		= @"windowFrameString";
static NSString * const ShowSettingsKey				= @"showSettings";
static NSString * const XMLParseCommandKey			= @"command";
static NSString * const RecentSchemaURLStrings		= @"recentSchemaURLStrings";


@interface MyDocument (Private)
@end


@implementation MyDocument

- (id)init;
{
	self = [super init];
	if (self != nil) {
		controller = [[MyController alloc] init];
	}
	return self;
}


- (void)dealloc;
{
	[controller release];
	[super dealloc];
}


#pragma mark -
#pragma mark NSDocument

- (void)makeWindowControllers;
{
	[self addWindowController:controller];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError;
{
	NSString *windowFrameString			= [[controller window] stringWithSavedFrame];
	NSNumber *showSettings				= [NSNumber numberWithBool:[controller showSettings]];
	XMLParseCommand *command			= [controller command];
	NSArray *recentSchemaURLStrings		= [controller recentSchemaURLStrings];
	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
		windowFrameString, WindowFrameStringKey,
		showSettings, ShowSettingsKey,
		command, XMLParseCommandKey,
		recentSchemaURLStrings, RecentSchemaURLStrings,
		nil];	
	
	return [NSKeyedArchiver archivedDataWithRootObject:d];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError;
{	
	NSDictionary *d = [NSKeyedUnarchiver unarchiveObjectWithData:data];

	NSString *windowFrameString			   = [d objectForKey:WindowFrameStringKey];
	BOOL showSettings					   = [[d objectForKey:ShowSettingsKey] boolValue];
	XMLParseCommand *command			   = [d objectForKey:XMLParseCommandKey];
	NSMutableArray *recentSchemaURLStrings = [NSMutableArray arrayWithArray:[d objectForKey:RecentSchemaURLStrings]];

	[[controller window] setFrameFromString:windowFrameString];
	[controller setShowSettings:showSettings];
	[controller setCommand:command];
	[controller setRecentSchemaURLStrings:recentSchemaURLStrings];
	
	return YES;
}

@end
