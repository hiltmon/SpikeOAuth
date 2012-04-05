//
//  NVGoogleController.h
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/5/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GTMOAuth2WindowController.h"

@interface NVGoogleController : NSWindowController
{
    IBOutlet NSTextView *apiResultTextView;
    IBOutlet NSTextField *usernameField;
    IBOutlet NSTextField *serviceNameField;
    IBOutlet NSTextField *accessTokenField;
    IBOutlet NSTextField *expirationField;
    IBOutlet NSTextField *refreshTokenField;

    IBOutlet NSButton *fetchButton;

    GTMOAuth2Authentication *cachedAuth;
}

- (IBAction)signInButtonClicked:(id)sender;
- (IBAction)fetchButtonClicked:(id)sender;

@end
