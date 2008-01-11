//
//  MyDocument.h
//  XML Nanny
//
//  Created by Todd Ditchendorf on 1/12/07.
//  Copyright 2007 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyController;

@interface MyDocument : NSDocument {
	MyController *controller;
}

@end
