//
//  AppDelegate.h
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/13/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *XNPlaySoundsKey;
extern NSString *XNWrapTextKey;
extern NSString *XNExternalEditorKey;

@class PrefController, CatalogController;

@interface AppDelegate : NSObject {
	PrefController *prefController;
	CatalogController *catalogController;
}
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showCatalogWindow:(id)sender;
@end
