//
//  PrefController.h
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/13/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PrefController : NSWindowController {
	IBOutlet NSPopUpButton *externalEditorPopUpButton;
	int externalEditorPopUpSelectedTag;
	NSString *externalEditorDisplayString;
	NSImage *externalEditorIcon;
}
- (IBAction)externalEditorChanged:(id)sender;
- (IBAction)browseForExternalEditor:(id)sender;

- (BOOL)playSounds;
- (void)setPlaySounds:(BOOL)yn;
- (BOOL)wrapText;
- (void)setWrapText:(BOOL)yn;
- (id)externalEditor;
- (void)setExternalEditor:(id)ed;
- (NSString *)externalEditorDisplayString;
- (void)setExternalEditorDisplayString:(NSString *)newStr;
- (NSImage *)externalEditorIcon;
- (void)setExternalEditorIcon:(NSImage *)newImg;
@end
