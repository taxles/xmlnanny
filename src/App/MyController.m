//
//  MyController.m
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/12/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import "MyController.h"
#import "AppDelegate.h"
#import "XMLParsingService.h"
#import "XMLParseCommand.h"
#import "XMLParsingServiceLibxmlImpl.h"
#import <WebKit/WebKit.h>


typedef enum {
	CheckboxTagLoadDTD = 0,
	CheckboxTagDefaultDTDAttrs,
	CheckboxTagSubstituteEntities,
	CheckboxTagMergeCDATA,
	CheckboxTagProcessXIncludes
} CheckboxTag;


@interface NSString (HTMLSupport)
- (NSString *)stringByReplacingHTMLEntities;
@end

@implementation NSString (HTMLSupport)
- (NSString *)stringByReplacingHTMLEntities;
{
	NSMutableString *mstr = [NSMutableString stringWithString:self];
	[mstr replaceOccurrencesOfString:@"&"
						  withString:@"&amp;"
							 options:0
							   range:NSMakeRange(0, [mstr length])];
	[mstr replaceOccurrencesOfString:@"<"
						  withString:@"&lt;"
							 options:0
							   range:NSMakeRange(0, [mstr length])];
	[mstr replaceOccurrencesOfString:@">"
						  withString:@"&gt;"
							 options:0
							   range:NSMakeRange(0, [mstr length])];
	
	return [NSString stringWithString:mstr];
}
@end


@interface DOMElement (IEExtentions)
- (void)setClassName:(NSString *)className;
- (void)setInnerText:(NSString *)innerText;
- (void)setInnerHTML:(NSString *)innerHTML;
@end

@interface MyController (Private)
- (void)setupFonts;
- (void)loadParseResultsDocument;
- (void)makeTextViewScrollHorizontally:(NSTextView *)textView
					  withinScrollView:(NSScrollView *)scrollView;
- (void)setSchemaURLComboBoxPlaceHolderString;
- (BOOL)addRecentSchemaURLString:(NSString *)str;
- (BOOL)addRecentXPathString:(NSString *)str;
- (NSArray *)contextMenuItems;
- (void)setContextMenuItems:(NSArray *)newItems;
- (BOOL)isRemoteURLString:(NSString *)URLString;
- (NSString *)HTMLStringForErrorInfo:(NSDictionary *)info;
- (void)appendResultItemWithClassName:(NSString *)className 
							innerHTML:(NSString *)innerHTML 
						   attributes:(NSDictionary *)attrs;
- (void)playSuccessSound;
- (void)playErrorSound;
- (void)playWarningSound;
- (void)playSoundNamed:(NSString *)name;
- (void)changeSizeForSettings;
- (void)errorItemClicked:(float)line filename:(NSString *)filename;
- (void)selectTextInExternalEditor:(NSArray *)args;
- (void)selectTextInBBEditFile:(NSString *)filename line:(int)line;
- (void)selectTextInSubEthaEditFile:(NSString *)filename line:(int)line;
- (void)selectTextInTextMateFile:(NSString *)filename line:(int)line;
- (void)selectTextInTextEditFile:(NSString *)filename line:(int)line;
- (void)selectTextInUknownEditor:(NSString *)filename line:(int)line;
- (void)doProblemItemWithClassName:(NSString *)className error:(NSDictionary *)info;
@end


@implementation MyController

- (id)init;
{
	self = [super initWithWindowNibName:@"MyDocument"];
	if (self != nil) {
		parsingService = [[XMLParsingServiceLibxmlImpl alloc] initWithDelegate:self];
	}
	return self;
}


- (void)dealloc;
{
	[parsingService release];
	[self setContextMenuItems:nil];
	[self setCommand:nil];
	[self setRecentSchemaURLStrings:nil];
	[self setSourceXMLString:nil];
	[super dealloc];
}


#pragma mark -
#pragma mark NSWindowcontroller

- (void)windowDidLoad;
{
	[self setupFonts];
	[self loadParseResultsDocument];
	[self makeTextViewScrollHorizontally:sourceXMLTextView
						withinScrollView:sourceXMLScrollView];
	[self setSchemaURLComboBoxPlaceHolderString];

	if (!command) {
		[self setCommand:[[[XMLParseCommand alloc] init] autorelease]];
	}
}


#pragma mark -
#pragma mark Actions

- (IBAction)parameterWasChanged:(id)sender;
{
	[[self document] updateChangeCount:NSSaveOperation];
	
	BOOL checked = (NSOnState == [sender state]);
	
	switch ([sender tag]) {
		
		case CheckboxTagLoadDTD:
			if (!checked) {
				[command setDefaultDTDAttributes:NO];
				[command setSubstituteEntities:NO];
			}
			break;
		case CheckboxTagDefaultDTDAttrs:
			if (checked) {
				[command setLoadDTD:YES];
			}
			break;
		case CheckboxTagSubstituteEntities:
			if (checked) {
				[command setLoadDTD:YES];
			}
			break;
	}
}


- (IBAction)validationTypeWasChanged:(id)sender;
{	
	[[self document] updateChangeCount:NSSaveOperation];

	[command setSchemaURLString:nil];
	
	[self setSchemaURLComboBoxPlaceHolderString];
}


- (IBAction)openLocation:(id)sender;
{
	id comboBox;
	if ([sender tag]) {
		comboBox = schemaURLComboBox;
	} else {
		comboBox = sourceURLComboBox;
	}
	[[self window] makeFirstResponder:comboBox];
}


- (IBAction)browse:(id)sender;
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	const int res = [panel runModalForDirectory:nil file:nil];
	NSString *filename = [panel filename];
	if (NSFileHandlingPanelOKButton == res) {
		if ([sender tag]) {
			[command setSchemaURLString:filename];
		} else {
			[command setSourceURLString:filename];
		}
		[[self document] updateChangeCount:NSSaveOperation];
	}
}


- (IBAction)parse:(id)sender;
{
	[self clear:self];
	
	NSString *sourceURLString = [command sourceURLString];
	
	if (![sourceURLString length]) {
		NSBeep();
		return;
	}
	
	if (![sourceURLString hasPrefix:@"/"]) {
		if (![self isRemoteURLString:sourceURLString]) {
			sourceURLString = [NSString stringWithFormat:@"http://%@", sourceURLString];
			[command setSourceURLString:sourceURLString];
		}
	}
	
	XMLValidationType type		= [command validationType];
	NSString *schemaURLString	= [command schemaURLString];
	
	if (XMLValidationTypeXSD == type || 
		XMLValidationTypeRNG == type || 
		XMLValidationTypeRNC == type || 
		XMLValidationTypeSchematron == type) {
		
		if (![schemaURLString length]) {
			NSBeep();
			return;
		}
	}
	
	[self setBusy:YES];
	errorCount = 0;
	
	if ([schemaURLString length]) {
		[self addRecentSchemaURLString:schemaURLString];
	}
	
	[parsingService parse:command];
}


- (IBAction)clear:(id)sender;
{
	DOMDocument *document = [[parseResultsWebView mainFrame] DOMDocument];
	DOMElement *ul = [document getElementById:@"result-list"];
	[ul setInnerHTML:@""];
	
	[self setSourceXMLString:nil];
}


- (IBAction)makeTextActualSize:(id)sender;
{
    [parseResultsWebView makeTextStandardSize:sender];
}


- (IBAction)makeTextBigger:(id)sender;
{
    [parseResultsWebView makeTextLarger:sender];
}


- (IBAction)makeTextSmaller:(id)sender;
{
    [parseResultsWebView makeTextSmaller:sender];
}


#pragma mark -
#pragma mark Private

- (void)setupFonts;
{
	NSFont *monaco = [NSFont fontWithName:@"Monaco" size:9.0];
	[sourceXMLTextView setFont:monaco];
}


- (void)loadParseResultsDocument;
{
	NSString *path	 = [[NSBundle mainBundle] pathForResource:@"results" ofType:@"html"];
	
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
	[[parseResultsWebView mainFrame] loadRequest:req];
}


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


- (void)setSchemaURLComboBoxPlaceHolderString;
{
	XMLValidationType type = [command validationType];
	
	NSString *str = nil;
	
	switch(type) {
		case XMLValidationTypeDTD:
			str = NSLocalizedString(@"Auto-detect DTD", @"");
			break;
		case XMLValidationTypeXSD:
		case XMLValidationTypeRNG:
		case XMLValidationTypeRNC:
		case XMLValidationTypeSchematron:
			str = @"Required";
			break;
	}
	
	[[schemaURLComboBox cell] setPlaceholderString:str];
}


- (BOOL)addRecentSchemaURLString:(NSString *)str;
{
	BOOL res = NO;
	if (![recentSchemaURLStrings containsObject:str]) {
		res = YES;
		[recentSchemaURLStrings addObject:str];
	}
	return res;
}


- (NSArray *)contextMenuItems;
{
	@synchronized (self) {
		if (!contextMenuItems) {
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Clear", @"")
														   action:@selector(clear:)
													keyEquivalent:@""] autorelease];
			NSArray *a = [NSArray arrayWithObject:item];
			[self setContextMenuItems:a];
		}
	}
	return contextMenuItems;
}


- (void)setContextMenuItems:(NSArray *)newItems;
{
	if (contextMenuItems != newItems) {
		[contextMenuItems autorelease];
		contextMenuItems = [newItems retain];
	}
}


- (BOOL)isRemoteURLString:(NSString *)URLString;
{
	return [URLString hasPrefix:@"http://"] || [URLString hasPrefix:@"https://"];
}


- (NSString *)HTMLStringForErrorInfo:(NSDictionary *)info;
{
	NSMutableString *res = [NSMutableString string];
	
	[res appendString:[NSString stringWithFormat:@"%@ %@: ", 
		[info objectForKey:XMLParseErrorDomainStrKey],
		[info objectForKey:XMLParseErrorLevelStrKey]]];
	
	NSNumber *line = [info objectForKey:XMLParseErrorLineKey];
	if (line) {
		[res appendString:[NSString stringWithFormat:@"line %@: ", line]];
	}
	[res appendString:[info objectForKey:XMLParseErrorMessageKey]];
	
	NSString *ctxtStr = [[info objectForKey:XMLParseErrorContextStrKey] stringByReplacingHTMLEntities];
	
	BOOL isSchematron = [[info objectForKey:XMLParseErrorDomainStrKey] hasPrefix:@"Schematron"];
	NSString *formatStr = nil;	
	if (isSchematron) {
		formatStr = @"<div>For Pattern: <pre>%@</pre></div>";
	} else {
		formatStr = @"<div><pre>%@</pre></div>";
	}
	[res appendString:[NSString stringWithFormat:formatStr, ctxtStr]];
	
	if (isSchematron) {
		NSString *diagnostics = [info objectForKey:XMLParseErrorDiagnosticsKey];
		if ([diagnostics length]) {
			[res appendFormat:@"<div>Diagnostics: %@</div>", diagnostics];
		}
		NSString *role = [info objectForKey:XMLParseErrorRoleKey];
		if ([role length]) {
			[res appendFormat:@"<div>Role: %@</div>", role];
		}
		NSString *subject = [info objectForKey:XMLParseErrorSubjectKey];
		if ([subject length]) {
			[res appendFormat:@"<div>Subject: %@</div>", subject];
		}
	}
	return res;
}


- (void)appendResultItemWithClassName:(NSString *)className 
							innerHTML:(NSString *)innerHTML 
						   attributes:(NSDictionary *)attrs;
{	
	DOMDocument *document = [[parseResultsWebView mainFrame] DOMDocument];
	DOMElement *li = [document createElement:@"li"];
	[li setClassName:className];
	[li setInnerHTML:innerHTML];
	
	NSEnumerator *e = [attrs keyEnumerator];
	NSString *key;
	while (key = [e nextObject]) {
		[li setAttribute:key value:[attrs objectForKey:key]];
	}
	
	[[document getElementById:@"result-list"] appendChild:li];
}


- (NSString *)nameForValidationType:(XMLValidationType)type;
{
	NSString *res = nil;
	
	switch ([command validationType]) {
		case XMLValidationTypeDTD:
			res = @"DTD";
			break;
		case XMLValidationTypeXSD:
			res = @"XML Schema";
			break;
		case XMLValidationTypeRNG:
			res = @"RELAX NG";
			break;
		case XMLValidationTypeRNC:
			res = @"RELAX NG Compact Syntax";
			break;
		case XMLValidationTypeSchematron:
			res = @"Schematron";
			break;
	}
	
	return res;
}


- (void)playSuccessSound;
{
	[self playSoundNamed:@"Hero"];
}


- (void)playErrorSound;
{
	[self playSoundNamed:@"Basso"];
}


- (void)playWarningSound;
{
	[self playSoundNamed:@"Bottle"];
}


- (void)playSoundNamed:(NSString *)name;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL playSounds = [[defaults objectForKey:XNPlaySoundsKey] boolValue];

	if (playSounds) {
		[[NSSound soundNamed:name] play];
	}
}


- (void)doProblemItemWithClassName:(NSString *)className error:(NSDictionary *)info;
{	
	NSString *msg = [self HTMLStringForErrorInfo:info];
	
	
	NSString *filename = [info objectForKey:XMLParseErrorFilenameKey];
	
	NSDictionary *attrs = nil;
	NSNumber *line = [info objectForKey:XMLParseErrorLineKey]; 
	if (line) {
		NSString *attrVal = [NSString stringWithFormat:@"errorItemClicked(%d, '%@')", [line intValue], filename];
		attrs = [NSDictionary dictionaryWithObject:attrVal forKey:@"onclick"];
	}
	
	[self appendResultItemWithClassName:className innerHTML:msg attributes:attrs];
}


- (void)changeSizeForSettings;
{
	NSPoint p = [bottomView bounds].origin;
	p.y = (showSettings) ? 80.0 : 0.0;
	[bottomView setBoundsOrigin:p];
	[bottomView setNeedsDisplay:YES];	
}


- (void)errorItemClicked:(float)line filename:(NSString *)filename;
{	
	if (!filename || [filename isEqualToString:@"(null)"]) {
		filename = [command schemaURLString];
	}
	
	NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithFloat:line], filename, nil];
	[self performSelector:@selector(selectTextInExternalEditor:)
			   withObject:args];
}


- (void)selectTextInExternalEditor:(NSArray *)args;
{
	int line = [[args objectAtIndex:0] intValue];
	NSString *filename = [args objectAtIndex:1];
	
	if ([self isRemoteURLString:filename]) {
		[self selectTextInUknownEditor:filename line:line];
		return;
	}
	
	NSString *externalEditor = [[NSUserDefaults standardUserDefaults] objectForKey:XNExternalEditorKey];
	
	if (NSNotFound != [externalEditor rangeOfString:@"BBEdit"].location) {
		[self selectTextInBBEditFile:filename line:line];
	} else if (NSNotFound != [externalEditor rangeOfString:@"TextMate"].location) {
		[self selectTextInTextMateFile:filename line:line];
	} else if (NSNotFound != [externalEditor rangeOfString:@"SubEthaEdit"].location) {
		[self selectTextInSubEthaEditFile:filename line:line];
	} else if (NSNotFound != [externalEditor rangeOfString:@"TextEdit"].location) {
		[self selectTextInTextEditFile:filename line:line];
	} else {
		[self selectTextInUknownEditor:filename line:line];
	}
}


- (void)selectTextInBBEditFile:(NSString *)filename line:(int)line;
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"openBBEditDocAtLine" ofType:@"txt"];
	NSString *format = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	NSString *source = [NSString stringWithFormat:format, filename, line];
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
	[script executeAndReturnError:nil];
	[script release];
}


- (void)selectTextInSubEthaEditFile:(NSString *)filename line:(int)line;
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"openSubEthaEditDocAtLine" ofType:@"txt"];
	NSString *format = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	NSString *source = [NSString stringWithFormat:format, filename, line];
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
	[script executeAndReturnError:nil];
	[script release];
}


- (void)selectTextInTextMateFile:(NSString *)filename line:(int)line;
{
	NSString *args = [NSString stringWithFormat:@"-l %d %@", line, filename];
	[NSTask launchedTaskWithLaunchPath:@"/usr/local/bin/mate"
							 arguments:[args componentsSeparatedByString:@" "]];
}


- (void)selectTextInTextEditFile:(NSString *)filename line:(int)line;
{
	NSString *args = [NSString stringWithFormat:@"-e %@", filename];
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open"
							 arguments:[args componentsSeparatedByString:@" "]];
}


- (void)selectTextInUknownEditor:(NSString *)filename line:(int)line;
{
	NSString *externalEditor = [[NSUserDefaults standardUserDefaults] objectForKey:XNExternalEditorKey];

    if ([externalEditor length]) {
        NSString *args = [NSString stringWithFormat:@"-a %@ %@", externalEditor, filename];
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open"
                                 arguments:[args componentsSeparatedByString:@" "]];
    } else {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:filename]];
    }
}


#pragma mark -
#pragma mark WebScripting

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
	if (@selector(errorItemClicked:filename:) == sel) {
		return @"errorItemClicked";
	} else {
		return nil;
	}
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	return (nil == [self webScriptNameForSelector:sel]);
}


+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
	return YES;
}


#pragma mark -
#pragma mark XMLParsingServiceDelegate

- (void)parsingService:(id <XMLParsingService>)service willParse:(XMLParseCommand *)c;
{
	//NSLog(@"controller willParse:");
	
	if (![command verbose]) {
		return;
	}	
	
	BOOL checkedValidity = (XMLValidationTypeNone != [command validationType]);
	
	NSString *filename = [[command sourceURLString] lastPathComponent];
	
	NSMutableString *msg = nil;
	NSString *schemaFilename = [[command schemaURLString] lastPathComponent];
	
	if (checkedValidity) {
		msg = [NSMutableString stringWithFormat:@"Checking <tt>%@</tt> for validity against ", filename];
		switch ([command validationType]) {
			case XMLValidationTypeDTD:
				if ([schemaFilename length]) {
					[msg appendFormat:@"user-specified DTD: <tt>%@</tt>", schemaFilename];
				} else {
					[msg appendString:@"auto-detected DTD"];
				}
				break;
			case XMLValidationTypeXSD:
				if ([schemaFilename length]) {
					[msg appendFormat:@"user-specified XML Schema: <tt>%@</tt>", schemaFilename];
				} else {
					[msg appendString:@"auto-detected XML Schema"];
				}
				break;
			case XMLValidationTypeRNG:
				[msg appendFormat:@"RELAX NG schema: <tt>%@</tt>", schemaFilename];
				break;
			case XMLValidationTypeRNC:
				[msg appendFormat:@"RELAX NG Compact Syntax schema: <tt>%@</tt>", schemaFilename];
				break;
			case XMLValidationTypeSchematron:
				[msg appendFormat:@"Schematron schema: <tt>%@</tt>", schemaFilename];
				break;
		}
		
	} else {
		msg = [NSMutableString stringWithFormat:@"Checking <tt>%@</tt> for well-formedness", filename];
	}
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


- (void)parsingService:(id <XMLParsingService>)service didParse:(XMLParseCommand *)c;
{
	NSString *filename = [[command sourceURLString] lastPathComponent];
	
	BOOL checkedValidity = (XMLValidationTypeNone != [command validationType]);
	NSString *result = (checkedValidity ? NSLocalizedString(@"valid", @"") : NSLocalizedString(@"well-formed", @""));

	NSString *attrVal = [NSString stringWithFormat:@"errorItemClicked(%d, '%@')", 0, [command sourceURLString]];
	NSDictionary *attrs = [NSDictionary dictionaryWithObject:attrVal forKey:@"onclick"];

	if (!errorCount) {
		
		NSString *msg = [NSString stringWithFormat:@"<tt>%@</tt> is %@", filename, result];
		[self appendResultItemWithClassName:@"success-item" innerHTML:msg attributes:attrs];
		[self playSuccessSound];
		
	} else {
		
		NSString *msg = [NSString stringWithFormat:@"<tt>%@</tt> is NOT %@", filename, result];
		[self appendResultItemWithClassName:@"error-item" innerHTML:msg attributes:attrs];
		[self playErrorSound];
		
	}
	
	[parseResultsWebView setNeedsDisplay:YES];
	[[self window] makeFirstResponder:parseResultsWebView];
	[self setBusy:NO];
}


- (void)parsingService:(id <XMLParsingService>)service willFetchSchema:(NSString *)schemaURLString;
{
	//NSLog(@"controller willFetchSchema:");
	
	if (![command verbose]) {
		return;
	}
	
	NSString *schemaType = [self nameForValidationType:[command validationType]];
	
	NSString *schemaFilename = [schemaURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Fetching %@: <tt>%@</tt>", schemaType, schemaFilename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


- (void)parsingService:(id <XMLParsingService>)service didFetchSchema:(NSString *)schemaURLString;
{
	//NSLog(@"controller didFetchSchema:");
	
	if (![command verbose]) {
		return;
	}
	
	NSString *schemaType = [self nameForValidationType:[command validationType]];
	
	NSString *schemaFilename = [schemaURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Successfully fetched %@: <tt>%@</tt>", schemaType, schemaFilename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


- (void)parsingService:(id <XMLParsingService>)service willParseSchema:(NSString *)schemaURLString;
{
	//NSLog(@"controller willParseSchema:");
	
	if (![command verbose]) {
		return;
	}
	
	NSString *schemaType = [self nameForValidationType:[command validationType]];
	
	NSString *schemaFilename = [schemaURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Parsing %@: <tt>%@</tt>", schemaType, schemaFilename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


- (void)parsingService:(id <XMLParsingService>)service didParseSchema:(NSString *)schemaURLString duration:(NSTimeInterval)duration;
{
	//NSLog(@"controller didParseSchema:");
	
	if (![command verbose]) {
		return;
	}
	
	NSString *schemaType = [self nameForValidationType:[command validationType]];
	
	NSString *schemaFilename = [schemaURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Finished parsing %@: <tt>%@</tt>", schemaType, schemaFilename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
	
}


- (void)parsingService:(id <XMLParsingService>)service willFetchSource:(NSString *)sourceURLString;
{
	//NSLog(@"controller willFetchSource:");
	
	if (![command verbose]) {
		return;
	}
	
	NSString *filename = [sourceURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Fetching document: <tt>%@</tt>", filename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


- (void)parsingService:(id <XMLParsingService>)service didFetchSource:(NSString *)sourceURLString duration:(NSTimeInterval)duration;
{
	//NSLog(@"controller didFetchSource:");
	
	if (![command verbose]) {
		return;
	}
	
	NSString *filename = [sourceURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Successfully fetched document: <tt>%@</tt>", filename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


- (void)parsingService:(id <XMLParsingService>)service willParseSource:(NSString *)sourceURLString;
{
	//NSLog(@"controller willParseSource:");
	
	if (![command verbose]) {
		return;
	}
	
	NSString *filename = [sourceURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Parsing document: <tt>%@</tt>", filename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


- (void)parsingService:(id <XMLParsingService>)service didParseSource:(NSString *)sourceURLString sourceXMLString:(NSString *)data duration:(NSTimeInterval)duration;
{
	//NSLog(@"controller didParseSource:");
	
	[self setSourceXMLString:data];
	
	if (![command verbose]) {
		return;
	}	
	
	NSString *filename = [sourceURLString lastPathComponent];
	
	NSString *msg = [NSString stringWithFormat:@"Finished parsing document: <tt>%@</tt>", filename];
	
	[self appendResultItemWithClassName:@"info-item" innerHTML:msg attributes:nil];
}


#pragma mark -
#pragma mark ErrorHandler

- (void)parsingService:(id <XMLParsingService>)service warning:(NSDictionary *)info;
{
	errorCount++;
	[self doProblemItemWithClassName:@"warning-item" error:info];
	[self playWarningSound];
}


- (void)parsingService:(id <XMLParsingService>)service error:(NSDictionary *)info;
{
	errorCount++;
	[self doProblemItemWithClassName:@"error-item" error:info];
	[self playErrorSound];
}


- (void)parsingService:(id <XMLParsingService>)service fatalError:(NSDictionary *)info;
{
	errorCount++;
	[self doProblemItemWithClassName:@"error-item" error:info];
	[self playErrorSound];
}


#pragma mark -
#pragma mark SchematronMessageHandler

- (void)parsingService:(id <XMLParsingService>)service assertFired:(NSDictionary *)info;
{
	errorCount++;
	[self doProblemItemWithClassName:@"assert-item" error:info];
	[self playErrorSound];
}


- (void)parsingService:(id <XMLParsingService>)service reportFired:(NSDictionary *)info;
{
	[self doProblemItemWithClassName:@"report-item" error:info];
}


#pragma mark -
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject;
{
	[windowScriptObject setValue:self forKey:@"PlugIn"];
}


#pragma mark -
#pragma mark WebResourceLoadDelegate

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource;
{
	NSString *absURLStr = [[request URL] absoluteString];
	NSRange r = [absURLStr rangeOfString:@"/Contents/Resources/"];
	if (NSNotFound == r.location) {
		return nil;
	}
	return request;
}


#pragma mark -
#pragma mark WebUIDelegate

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems 
{
	return [self contextMenuItems]; 
}


- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo 
{
	return WebDragDestinationActionLoad;
}


- (void)webView:(WebView *)sender willPerformDragDestinationAction:(WebDragDestinationAction)action forDraggingInfo:(id <NSDraggingInfo>)draggingInfo 
{
	NSPasteboard *pboard = [draggingInfo draggingPasteboard];
	NSUInteger index = [[pboard types] indexOfObject:NSFilenamesPboardType];
	if (NSNotFound != index) {
		NSString *filename = [[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
		[command setSchemaURLString:filename];
		[self clear:self];
	}
}


#pragma mark -
#pragma mark NSComboBoxDataSource

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index;
{
	return [recentSchemaURLStrings objectAtIndex:index];
}


- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
{
	return [recentSchemaURLStrings count];
}


- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString
{
	if (aComboBox == schemaURLComboBox) {
		NSEnumerator *e = [recentSchemaURLStrings objectEnumerator];
		NSString *URLString = nil;
		//	NSString *filename = nil;
		while (URLString = [e nextObject]) {
			//		filename = [URLString lastPathComponent];
			if ([URLString hasPrefix:uncompletedString]) {
				//		if ([filename hasPrefix:uncompletedString]) {
				//			int pathLen = [URLString length] - [filename length];
				//			NSRange r1 = [filename rangeOfString:uncompletedString];
				//			NSRange r2 = NSMakeRange(r1.length + pathLen, [URLString length]);
				//			r2;
				//			return URLString;
				return URLString;
				}
			}
		}
	return nil;
	}


- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	NSEnumerator *e = [recentSchemaURLStrings objectEnumerator];
	NSString *str = nil;
	int i = 0;
	while (str = [e nextObject]) {
		if ([[str lastPathComponent] hasPrefix:aString]) {
			return i;
		}
		i++;
	}
	return NSNotFound;
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

- (CGFloat)splitView:(NSSplitView *)sv constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset;
{
	if (0 == offset) {
		NSRect r = [[self window] frame];
		return r.size.height - 10.0;
	}
	return proposedMax;
}


- (CGFloat)splitView:(NSSplitView *)sv constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset;
{
	if (0 == offset) {
		return 20.0;
	}
	return proposedMin;
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


- (BOOL)showSettings;
{
	return showSettings;
}


- (void)setShowSettings:(BOOL)yn;
{
	showSettings = yn;
	[self changeSizeForSettings];
}


- (XMLParseCommand *)command;
{
	return command;
}


- (void)setCommand:(XMLParseCommand *)c;
{
	if (command != c) {
		[command autorelease];
		command = [c retain];
	}
}


- (NSMutableArray *)recentSchemaURLStrings;
{
	return recentSchemaURLStrings;
}


- (void)setRecentSchemaURLStrings:(NSMutableArray *)newStrs;
{
	if (recentSchemaURLStrings != newStrs) {
		[recentSchemaURLStrings autorelease];
		recentSchemaURLStrings = [newStrs retain];
	}
}


- (NSString *)sourceXMLString;
{
	return sourceXMLString;
}


- (void)setSourceXMLString:(NSString *)newStr;
{
	if (sourceXMLString != newStr) {
		[sourceXMLString autorelease];
		sourceXMLString = [newStr retain];
	}
}

@end
