//
//  CatalogController.m
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/13/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "CatalogController.h"
#import "AppDelegate.h"
#import "XMLCatalogService.h"
#import "XMLCatalogServiceLibxmlImpl.h"


static NSString * const PreferedCatalogItemTypeKey	= @"preferedCatalogItemType";
static NSString * const CatalogItemsKey				= @"catalogItems";
//static NSString * const WindowFrameStringKey		= @"windowFrameString";
static NSString * const PrefsFileName				= @"catalogPrefs";
static NSString * const PrefsFileExt				= @"plist";

@interface CatalogController (Private)
- (void)setupFonts;
- (void)makeTextViewScrollHorizontally:(NSTextView *)textView
					  withinScrollView:(NSScrollView *)scrollView;
- (void)registerForNotifications;
- (void)setupCatalogTable;
- (void)updateCatalog;

- (void)loadCatalogPrefs;
- (void)saveCatalogPrefs;
@end

@implementation CatalogController

- (id)init;
{
	self = [super initWithWindowNibName:@"CatalogWindow"];
	if (self != nil) {
		catalogService = [[XMLCatalogServiceLibxmlImpl alloc] initWithDelegate:self];
		[self loadCatalogPrefs];
		[catalogService putCatalogContents:catalogItems];
	}
	return self;
}


- (void)dealloc;
{
	[catalogService release];
	[self setCatalogItems:nil];
	[self setCatalogXMLString:nil];
	[super dealloc];
}


#pragma mark -
#pragma mark NSWindowController

- (void)windowDidLoad;
{
	[self setupFonts];
	[self registerForNotifications];
	[self setupCatalogTable];
	[self makeTextViewScrollHorizontally:catalogXMLTextView
						withinScrollView:catalogXMLScrollView];
}


#pragma mark -
#pragma mark Actions

- (void)showWindow:(id)sender;
{
	[super showWindow:sender];
	[catalogService putCatalogContents:catalogItems];
}


#pragma mark -
#pragma mark NSControlNotifications

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self saveCatalogPrefs];
}


#pragma mark -
#pragma mark Private

- (void)makeTextViewScrollHorizontally:(NSTextView *)textView 
					  withinScrollView:(NSScrollView *)scrollView;
{
	BOOL wrap = [[NSUserDefaults standardUserDefaults] boolForKey:XNWrapTextKey];
	
	if (!wrap) {
		[scrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[textView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
		[[textView textContainer] setContainerSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
		[[textView textContainer] setWidthTracksTextView:NO];	
		[textView setMaxSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
	}
	
}


- (void)loadCatalogPrefs;
{
	NSString *path	 = [[NSBundle mainBundle] pathForResource:PrefsFileName ofType:PrefsFileExt];
	
	NSDictionary *d = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	
	//int type					= [[d objectForKey:PreferedCatalogItemTypeKey] intValue];
	NSMutableArray *items		= [NSMutableArray arrayWithArray:[d objectForKey:CatalogItemsKey]];
	//NSString *windowFrameString = [d objectForKey:WindowFrameStringKey];
	
	[self setPreferedCatalogItemType:1];
	[self setCatalogItems:items];
	//[[self window] setFrameFromString:windowFrameString];
}


- (void)saveCatalogPrefs;
{
	NSString *path = [[NSBundle mainBundle] resourcePath];
	path = [[path stringByAppendingPathComponent:PrefsFileName] stringByAppendingPathExtension:PrefsFileExt];
	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
		//[NSNumber numberWithInt:preferedCatalogItemType], PreferedCatalogItemTypeKey,
		catalogItems, CatalogItemsKey,
		//[[self window] stringWithSavedFrame], WindowFrameStringKey,
		nil];
	
	[NSKeyedArchiver archiveRootObject:d toFile:path];
}


- (void)setupFonts;
{
	NSFont *monaco = [NSFont fontWithName:@"Monaco" size:9.];
	[catalogXMLTextView setFont:monaco];
}


- (void)registerForNotifications;
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(windowWillClose:) 
			   name:NSWindowWillCloseNotification
			 object:[self window]];
	
	[nc addObserver:self
		   selector:@selector(textDidEndEditing:) 
			   name:NSControlTextDidEndEditingNotification
			 object:nil];
	
	[nc addObserver:self
		   selector:@selector(menuDidSendAction:) 
			   name:NSMenuDidSendActionNotification
			 object:nil];
	
	[nc addObserver:self
		   selector:@selector(tableSelectionDidChange:) 
			   name:NSTableViewSelectionDidChangeNotification
			 object:catalogTable];
}


- (void)setupCatalogTable;
{
	NSPopUpButtonCell *pCell = [[catalogTable tableColumnWithIdentifier:@"type"] dataCell];
	[pCell setFont:[NSFont controlContentFontOfSize:10.]];
	[pCell setMenu:catalogItemTypeMenu];
	
	[catalogTable setNeedsDisplay:YES];
}


- (void)updateCatalog;
{
	[self setBusy:YES];
	[catalogService putCatalogContents:catalogItems];
}


#pragma mark -
#pragma mark XMLCatalogServiceDelegate

- (void)catalogService:(id <XMLCatalogService>)service didUpdate:(NSString *)XMLString;
{
	[self setCatalogXMLString:XMLString];
	[self setBusy:NO];
}


- (void)catalogService:(id <XMLCatalogService>)service didError:(NSDictionary *)errInfo;
{
	[self setBusy:NO];
}


#pragma mark -
#pragma mark NSTextViewDelegate

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString;
{
	NSBeep();
	return NO;
}


#pragma mark -
#pragma mark NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset;
{
	if (offset == 0) {
		NSRect r = [[self window] frame];
		return r.size.height - 129.0;
	}
	return proposedMax;
}


- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(int)offset;
{
	if (offset == 0) {
		return 30.0;
	}
	return proposedMin;
}


#pragma mark -
#pragma mark NSControlNotifications

- (void)textDidEndEditing:(NSNotification *)aNotification;
{
	id textField = [aNotification object];
	if ([textField isDescendantOf:catalogTable]) {
		[self updateCatalog];
	}
}


- (void)menuDidSendAction:(NSNotification *)aNotification;
{	
	id menu = [aNotification object];
	if ([[[menu itemAtIndex:0] title] isEqualToString:@"Disabled"] 
		&& [[[menu itemAtIndex:1] title] isEqualToString:@"Public"]) {
		[self updateCatalog];
	}
}


- (void)tableSelectionDidChange:(NSNotification *)aNotification;
{
	[self updateCatalog];
}


#pragma mark -
#pragma mark Accessors

- (BOOL)busy;
{
	return busy;
}


- (void)setBusy:(BOOL)yn;
{
	busy = yn;
}


- (NSString *)catalogXMLString;
{
	return catalogXMLString;
}


- (void)setCatalogXMLString:(NSString *)newStr;
{
	if (catalogXMLString != newStr) {
		[catalogXMLString autorelease];
		catalogXMLString = [newStr retain];
	}
}

- (int)preferedCatalogItemType;
{
	return preferedCatalogItemType;
}


- (void)setPreferedCatalogItemType:(int)n;
{
	preferedCatalogItemType = n;
	[catalogService setPrefer:n];
}

- (NSMutableArray *)catalogItems;
{
	return catalogItems;
}


- (void)setCatalogItems:(NSMutableArray *)newItems;
{
	if (catalogItems != newItems) {
		[catalogItems autorelease];
		catalogItems = [newItems retain];
	}
}

@end
