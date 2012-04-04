//
//  NVStackExchangeController.m
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/3/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import "NVStackExchangeController.h"

@interface NVStackExchangeController ()

- (void)signInToStackExchange;
- (void)updateUI;
- (void)setAuthentication:(GTMOAuth2Authentication *)auth;
- (BOOL)isSignedIn;

@end

@implementation NVStackExchangeController

static NSString *const kStackExchangeKeychainItemName = @"SpikeOAuth: StackExchange";

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)signInButtonClicked:(id)sender
{
//    NSLog(@"Client ID: %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"stackExchangeClientID"]);
//    NSLog(@"Client Secret: %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"stackExchangeClientSecret"]);
//    
    [self signInToStackExchange];
}

- (IBAction)signUpButtonClicked:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://stackapps.com/apps/oauth/register"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)signOut {
    // Remove the stored StackExchange authentication from the keychain, if any
    [GTMOAuth2WindowController removeAuthFromKeychainForName:kStackExchangeKeychainItemName];
    
    // Discard our retained authentication object
    [self setAuthentication:nil];
    
    [self updateUI];
}

- (GTMOAuth2Authentication *)authForStackExchange
{
    NSURL *tokenURL = [NSURL URLWithString:@"https://stackexchange.com/oauth/access_token"];
    
    // We'll make up an arbitrary redirectURI.  The controller will watch for
    // the server to redirect the web view to this URI, but this URI will not be
    // loaded, so it need not be for any actual web page.
    NSString *redirectURI = @"http://www.noverse.com/OAuthStackExchangeCallback";
//    NSString *redirectURI = @"https://stackexchange.com/oauth/login_success";
    
    NSString *clientID = [[NSUserDefaults standardUserDefaults] valueForKey:@"stackExchangeClientID"];
    NSString *clientSecret = [[NSUserDefaults standardUserDefaults] valueForKey:@"stackExchangeClientSecret"];
    
    NSLog(@"Client ID: %@", clientID);
    NSLog(@"Client Secret: %@", clientSecret);
    NSLog(@"Redirect URI: %@", redirectURI);
    
    GTMOAuth2Authentication *auth;
    auth = [GTMOAuth2Authentication authenticationWithServiceProvider:@"StackExchange"
                                                             tokenURL:tokenURL
                                                          redirectURI:redirectURI
                                                             clientID:clientID
                                                         clientSecret:clientSecret];
    return auth;
}

- (void)signInToStackExchange 
{
    [self signOut];
    
    GTMOAuth2Authentication *auth = [self authForStackExchange];
    auth.scope = @"";
    
    if ([auth.clientID length] == 0 || [auth.clientSecret length] == 0) {
        NSBeginAlertSheet(@"Error", nil, nil, nil, self.window,
                          self, NULL, NULL, NULL,
                          @"The sample code requires a valid client ID"
                          " and client secret to sign in.");
        return;
    }
    
    // display the authentication sheet
    NSURL *authURL = [NSURL URLWithString:@"https://stackexchange.com/oauth"];
    
    GTMOAuth2WindowController *windowController;
    windowController = [GTMOAuth2WindowController controllerWithAuthentication:auth
                                                              authorizationURL:authURL
                                                              keychainItemName:kStackExchangeKeychainItemName
                                                                resourceBundle:nil];
    
    // optional: display some html briefly before the sign-in page loads
    NSString *html = @"<html><body><div align=center>Loading sign-in page...</div></body></html>";
    [windowController setInitialHTMLString:html];
    
    // TODO: Optional persistence
    windowController.shouldPersistUser = NO;
    
    [windowController signInSheetModalForWindow:self.window
                                       delegate:self
                               finishedSelector:@selector(windowController:finishedWithAuth:error:)];
}

- (void)windowController:(GTMOAuth2WindowController *)windowController
        finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
    [apiResultTextView setString:@""];
    
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        NSString *errorStr = [error localizedDescription];
        
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // Show the body of the server's authentication failure response
            errorStr = [[NSString alloc] initWithData:responseData
                                              encoding:NSUTF8StringEncoding];
        } else {
            NSString *str = [[error userInfo] objectForKey:kGTMOAuth2ErrorMessageKey];
            if ([str length] > 0) {
                errorStr = str;
            }
        }
        [apiResultTextView setString:errorStr];
        
        [self setAuthentication:nil];
    } else {
        // Authentication succeeded
        //
        // At this point, we either use the authentication object to explicitly
        // authorize requests, like
        //
        //  [auth authorizeRequest:myNSURLMutableRequest
        //       completionHandler:^(NSError *error) {
        //         if (error == nil) {
        //           // request here has been authorized
        //         }
        //       }];
        //
        // or store the authentication object into a fetcher or a Google API service
        // object like
        //
        //   [fetcher setAuthorizer:auth];
        
        // save the authentication object
        [self setAuthentication:auth];
        
        [apiResultTextView setString:@"Authentication succeeded\n"];
        [[[apiResultTextView textStorage] mutableString] appendString:auth.accessToken];
        
        // We can also access custom server response parameters here.
        //
        // For example, DailyMotion's token endpoint returns a uid value:
        //
        //   NSString *uid = [auth.parameters valueForKey:@"uid"];
    }
    
    [self updateUI];
}

- (void)setAuthentication:(GTMOAuth2Authentication *)auth 
{
    cachedAuth = auth;
//    [cachedAuth autorelease];
//    cachedAuth = [auth retain];
}

- (BOOL)isSignedIn 
{
    BOOL isSignedIn = cachedAuth.canAuthorize;
    return isSignedIn;
}

- (void)updateUI {
    // Update the text showing the signed-in state and the button title
    if ([self isSignedIn]) {
        // Signed in
        NSString *accessToken = cachedAuth.accessToken;
        NSString *refreshToken = cachedAuth.refreshToken;
        NSString *expiration = [cachedAuth.expirationDate description];
        NSString *email = cachedAuth.userEmail;
        NSString *serviceName = cachedAuth.serviceProvider;
        
        BOOL isVerified = [cachedAuth.userEmailIsVerified boolValue];
        if (!isVerified) {
            // Email address is not verified
            //
            // The email address is listed with the account info on the server, but
            // has not been confirmed as belonging to the owner of this account.
            email = [email stringByAppendingString:@" (unverified)"];
        }
        
        [accessTokenField setStringValue:(accessToken != nil ? accessToken : @"")];
        [expirationField setStringValue:(expiration != nil ? expiration : @"")];
        [refreshTokenField setStringValue:(refreshToken != nil ? refreshToken : @"")];
        [usernameField setStringValue:(email != nil ? email : @"")];
        [serviceNameField setStringValue:(serviceName != nil ? serviceName : @"")];
//        [mSignInOutButton setTitle:@"Sign Out"];
//        [mDoAnAuthenticatedFetchButton setEnabled:YES];
//        [mExpireNowButton setEnabled:YES];
    } else {
        // Signed out
        [usernameField setStringValue:@"-Not signed in-"];
        [serviceNameField setStringValue:@""];
        [accessTokenField setStringValue:@"-No token-"];
        [expirationField setStringValue:@""];
        [refreshTokenField setStringValue:@""];
//        [mSignInOutButton setTitle:@"Sign In..."];
//        [mDoAnAuthenticatedFetchButton setEnabled:NO];
//        [mExpireNowButton setEnabled:NO];
    }
}

@end
