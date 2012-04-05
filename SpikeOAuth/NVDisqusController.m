//
//  NVDisqusController.m
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/4/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import "NVDisqusController.h"

//#import "GTMHTTPFetcherLogging.h"

@interface NVDisqusController ()

- (void)signInToDisqus;
- (void)updateUI;
- (void)setAuthentication:(GTMOAuth2Authentication *)auth;
- (BOOL)isSignedIn;

@end

@implementation NVDisqusController

static NSString *const kDisqusKeychainItemName = @"SpikeOAuth: Disqus";

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
//        [GTMHTTPFetcher setLoggingEnabled:YES];
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
    [self signInToDisqus];
}

// utility for making a request from an old URL with some additional parameters
// Copied from GTMOAuth2SignIn
+ (NSMutableURLRequest *)mutableURLRequestWithURL:(NSURL *)oldURL
                                      paramString:(NSString *)paramStr {
    NSString *query = [oldURL query];
    if ([query length] > 0) {
        query = [query stringByAppendingFormat:@"&%@", paramStr];
    } else {
        query = paramStr;
    }
    
    NSString *portStr = @"";
    NSString *oldPort = [[oldURL port] stringValue];
    if ([oldPort length] > 0) {
        portStr = [@":" stringByAppendingString:oldPort];
    }
    
    NSString *qMark = [query length] > 0 ? @"?" : @"";
    NSString *newURLStr = [NSString stringWithFormat:@"%@://%@%@%@%@%@",
                           [oldURL scheme], [oldURL host], portStr,
                           [oldURL path], qMark, query];
    NSURL *newURL = [NSURL URLWithString:newURLStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:newURL];
    return request;
}

- (IBAction)fetchButtonClicked:(id)sender
{
    [apiResultTextView setString:@"Doing an authenticated API fetch..."];
    [apiResultTextView display];
    
    NSURL *url = [NSURL URLWithString:@"https://disqus.com/api/3.0/users/details.json"];
    
    NSMutableDictionary *paramsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       cachedAuth.accessToken, @"access_token",
                                       cachedAuth.clientID, @"api_key",
//                                       cachedAuth.clientSecret, @"api_secret",
                                       nil];

    NSString *paramStr = [GTMOAuth2Authentication encodedQueryParametersForDictionary:paramsDict];
    
    NSMutableURLRequest *request;
    request = [[self class] mutableURLRequestWithURL:url
                                         paramString:paramStr];
    
    NSLog(@"FETCH URL: %@", request);

    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
//    [myFetcher setAuthorizer:cachedAuth];
    [myFetcher beginFetchWithDelegate:self
                    didFinishSelector:@selector(disqusFetcher:finishedWithData:error:)];
}

- (void)disqusFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error 
{
    if (error != nil) 
    {
        NSLog(@"FETCH FAILED");
        [apiResultTextView setString:[error description]];
        NSString *str = [[NSString alloc] initWithData:retrievedData
                                              encoding:NSUTF8StringEncoding];
        NSLog(@"\nERROR DATA: %@", str);
        [[[apiResultTextView textStorage] mutableString] appendString:str];
    } 
    else 
    {
        // fetch succeeded
        NSLog(@"FETCH OK");
        NSString *str = [[NSString alloc] initWithData:retrievedData
                                               encoding:NSUTF8StringEncoding];
        [apiResultTextView setString:str];
    }
    
    // The access token may have changed
    [self updateUI];

}

- (void)signOut {
    // Remove the stored Disqus authentication from the keychain, if any
    [GTMOAuth2WindowController removeAuthFromKeychainForName:kDisqusKeychainItemName];
    
    // Discard our retained authentication object
    [self setAuthentication:nil];
    
    [self updateUI];
}

- (GTMOAuth2Authentication *)authForDisqus
{
    NSURL *tokenURL = [NSURL URLWithString:@"https://disqus.com/api/oauth/2.0/access_token//"];
    
    // We'll make up an arbitrary redirectURI.  The controller will watch for
    // the server to redirect the web view to this URI, but this URI will not be
    // loaded, so it need not be for any actual web page.
    NSString *redirectURI = @"http://www.noverse.com/OAuthDisqusCallback";
    
    NSString *clientID = [[NSUserDefaults standardUserDefaults] valueForKey:@"disqusClientID"];
    NSString *clientSecret = [[NSUserDefaults standardUserDefaults] valueForKey:@"disqusClientSecret"];
    
    NSLog(@"Client ID: %@", clientID);
    NSLog(@"Client Secret: %@", clientSecret);
    NSLog(@"Redirect URI: %@", redirectURI);
    
    GTMOAuth2Authentication *auth;
    auth = [GTMOAuth2Authentication authenticationWithServiceProvider:@"Disqus"
                                                             tokenURL:tokenURL
                                                          redirectURI:redirectURI
                                                             clientID:clientID
                                                         clientSecret:clientSecret];
    return auth;
}

- (void)signInToDisqus 
{
    [self signOut];
    
    GTMOAuth2Authentication *auth = [self authForDisqus];
    auth.scope = @"read,write";
    
    if ([auth.clientID length] == 0 || [auth.clientSecret length] == 0) {
        NSBeginAlertSheet(@"Error", nil, nil, nil, self.window,
                          self, NULL, NULL, NULL,
                          @"The sample code requires a valid client ID"
                          " and client secret to sign in.");
        return;
    }
    
    // display the authentication sheet
    // NOTE: The double // at the end prevents google from stripping the trailing / which
    //       is needed in this API call
    NSURL *authURL = [NSURL URLWithString:@"https://disqus.com/api/oauth/2.0/authorize//"];
    
    GTMOAuth2WindowController *windowController;
    windowController = [GTMOAuth2WindowController controllerWithAuthentication:auth
                                                              authorizationURL:authURL
                                                              keychainItemName:kDisqusKeychainItemName
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
        
        [apiResultTextView setString:@"Authentication succeeded"];
        
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
        [fetchButton setEnabled:YES];
        //        [mExpireNowButton setEnabled:YES];
    } else {
        // Signed out
        [usernameField setStringValue:@"-Not signed in-"];
        [serviceNameField setStringValue:@""];
        [accessTokenField setStringValue:@"-No token-"];
        [expirationField setStringValue:@""];
        [refreshTokenField setStringValue:@""];
        //        [mSignInOutButton setTitle:@"Sign In..."];
        [fetchButton setEnabled:NO];
        //        [mExpireNowButton setEnabled:NO];
    }
}

@end
