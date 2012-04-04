//
//  SpikeOAuthAppDelegate.h
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/3/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NVStackExchangeController.h"
#import "NVDisqusController.h"

@interface SpikeOAuthAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (retain) NVStackExchangeController *stackExchangeController;
@property (retain) NVDisqusController *disqusController;

- (IBAction)stackExchangeButtonClicked:(id)sender;
- (IBAction)disqusButtonClicked:(id)sender;

@end
