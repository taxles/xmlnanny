//
//  NSString+libxml2Support.h
//  XMLNanny
//
//  Created by Todd Ditchendorf on 12/23/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libxml/xmlstring.h>

@interface NSString (libxml2Support)
+ (id)stringWithXmlChar:(const xmlChar *)xc;
- (const xmlChar *)xmlChar;
- (NSString *)stringByRemovingCurlyBraces;
@end

