//
//  NVTwitterController.h
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/5/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GTMOAuthWindowController.h"

@interface NVTwitterController : NSWindowController
{
    IBOutlet NSTextView *apiResultTextView;
    IBOutlet NSTextField *usernameField;
    IBOutlet NSTextField *accessTokenField;
    
    IBOutlet NSButton *fetchButton;
    
    GTMOAuthAuthentication *cachedAuth;
}

- (IBAction)signInButtonClicked:(id)sender;
- (IBAction)fetchButtonClicked:(id)sender;

@end
