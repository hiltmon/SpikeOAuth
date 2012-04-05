//
//  SpikeOAuthAppDelegate.m
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/3/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import "SpikeOAuthAppDelegate.h"

@implementation SpikeOAuthAppDelegate

@synthesize window = _window;
@synthesize stackExchangeController = _stackExchangeController;
@synthesize disqusController = _disqusController;
@synthesize twitterController = _twitterController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)stackExchangeButtonClicked:(id)sender {
    
    if(!self.stackExchangeController)
    {
        self.stackExchangeController = [[NVStackExchangeController alloc] initWithWindowNibName:@"NVStackExchangeController"];
    }
    
    [self.stackExchangeController showWindow:self];
}

- (IBAction)disqusButtonClicked:(id)sender {
    
    if(!self.disqusController)
    {
        self.disqusController = [[NVDisqusController alloc] initWithWindowNibName:@"NVDisqusController"];
    }
    
    [self.disqusController showWindow:self];
}

- (IBAction)twitterButtonClicked:(id)sender {
    
    if(!self.twitterController)
    {
        self.twitterController = [[NVTwitterController alloc] initWithWindowNibName:@"NVTwitterController"];
    }
    
    [self.twitterController showWindow:self];
}

@end
