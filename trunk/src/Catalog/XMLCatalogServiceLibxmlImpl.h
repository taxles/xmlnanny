//
//  XMLCatalogServiceLibxmlImpl.h
//  XMLNanny
//
//  Created by Todd Ditchendorf on 12/31/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMLCatalogService.h"
#import <libxml/catalog.h>


@interface XMLCatalogServiceLibxmlImpl : NSObject <XMLCatalogService> {
	id delegate;
	xmlCatalogPtr catalog;
}

@end
