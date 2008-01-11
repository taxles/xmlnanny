//
//  XMLParsingSchematronStrategy.h
//  XMLNanny
//
//  Created by Todd Ditchendorf on 12/24/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMLParsingStrategy.h"
#import <libxslt/xsltinternals.h>


@interface XMLParsingSchematronStrategy : XMLParsingStrategy {
	xsltStylesheetPtr metaStylesheet;
}
@end
