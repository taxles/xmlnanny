//
//  CatalogController.h
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/13/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol XMLCatalogService;

@interface CatalogController : NSWindowController {
	IBOutlet NSTableView *catalogTable;
	IBOutlet NSMenu *catalogItemTypeMenu;
	IBOutlet NSScrollView *catalogXMLScrollView;
	IBOutlet NSTextView *catalogXMLTextView;
	
	BOOL busy;
	
	id <XMLCatalogService> catalogService;
	NSMutableArray *catalogItems;
	NSString *catalogXMLString;
	int preferedCatalogItemType;
}
- (BOOL)busy;
- (void)setBusy:(BOOL)yn;
- (NSString *)catalogXMLString;
- (void)setCatalogXMLString:(NSString *)newStr;
- (int)preferedCatalogItemType;
- (void)setPreferedCatalogItemType:(int)n;
- (NSMutableArray *)catalogItems;
- (void)setCatalogItems:(NSMutableArray *)newItems;
@end
