//
//  MyController.h
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/12/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;
@class XMLParseCommand;
@protocol XMLParsingService;


@interface MyController : NSWindowController {
	IBOutlet WebView *parseResultsWebView;
	IBOutlet NSComboBox *sourceURLComboBox;
	IBOutlet NSComboBox *schemaURLComboBox;
	IBOutlet NSScrollView *sourceXMLScrollView;
	IBOutlet NSTextView *sourceXMLTextView;
	IBOutlet NSView *bottomView;
	
	BOOL busy;
	BOOL showSettings;
	
	id <XMLParsingService> parsingService;
	int errorCount;
	NSArray *contextMenuItems;
	XMLParseCommand *command;
	NSMutableArray *recentSchemaURLStrings;
	NSString *sourceXMLString;
}
- (IBAction)parameterWasChanged:(id)sender;
- (IBAction)validationTypeWasChanged:(id)sender;
- (IBAction)openLocation:(id)sender;
- (IBAction)browse:(id)sender;
- (IBAction)parse:(id)sender;
- (IBAction)clear:(id)sender;

- (IBAction)makeTextBigger:(id)sender;
- (IBAction)makeTextSmaller:(id)sender;

- (BOOL)busy;
- (void)setBusy:(BOOL)yn;
- (BOOL)showSettings;
- (void)setShowSettings:(BOOL)yn;
- (XMLParseCommand *)command;
- (void)setCommand:(XMLParseCommand *)c;
- (NSMutableArray *)recentSchemaURLStrings;
- (void)setRecentSchemaURLStrings:(NSMutableArray *)newStrs;
- (NSString *)sourceXMLString;
- (void)setSourceXMLString:(NSString *)newStr;
@end
