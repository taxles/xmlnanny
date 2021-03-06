//
//  CatalogItem.h
//  XMLNanny
//
//  Created by Todd Ditchendorf on 12/31/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CatalogItem : NSObject {
	int type;
	NSString *orig;
	NSString *replace;
}
- (int)type;
- (void)setType:(int)newType;
- (NSString *)orig;
- (void)setOrig:(NSString *)newStr;
- (NSString *)replace;
- (void)setReplace:(NSString *)newStr;
@end
