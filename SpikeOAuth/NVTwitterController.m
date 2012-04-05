//
//  NVTwitterController.m
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/5/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import "NVTwitterController.h"

//#import "GTMHTTPFetcherLogging.h"

@interface NVTwitterController ()

- (void)signInToTwitter;
- (void)updateUI;
- (void)setAuthentication:(GTMOAuthAuthentication *)auth;
- (BOOL)isSignedIn;

@end

@implementation NVTwitterController

static NSString *const kTwitterKeychainItemName = @"SpikeOAuth: Twitter";

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        // [GTMHTTPFetcher setLoggingEnabled:YES];
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
    [self signInToTwitter];
}

// utility for making a request from an old URL with some additional parameters
// Copied from GTMOAuth2SignIn
//+ (NSMutableURLRequest *)mutableURLRequestWithURL:(NSURL *)oldURL
//                                      paramString:(NSString *)paramStr {
//    NSString *query = [oldURL query];
//    if ([query length] > 0) {
//        query = [query stringByAppendingFormat:@"&%@", paramStr];
//    } else {
//        query = paramStr;
//    }
//    
//    NSString *portStr = @"";
//    NSString *oldPort = [[oldURL port] stringValue];
//    if ([oldPort length] > 0) {
//        portStr = [@":" stringByAppendingString:oldPort];
//    }
//    
//    NSString *qMark = [query length] > 0 ? @"?" : @"";
//    NSString *newURLStr = [NSString stringWithFormat:@"%@://%@%@%@%@%@",
//                           [oldURL scheme], [oldURL host], portStr,
//                           [oldURL path], qMark, query];
//    NSURL *newURL = [NSURL URLWithString:newURLStr];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:newURL];
//    return request;
//}

- (IBAction)fetchButtonClicked:(id)sender
{
    [apiResultTextView setString:@"Doing an authenticated API fetch..."];
    [apiResultTextView display];
    
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/home_timeline.json"];
    
//    NSMutableDictionary *paramsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                       // cachedAuth.accessToken, @"access_token",
//                                       // cachedAuth.clientID, @"api_key",
//                                       // cachedAuth.clientSecret, @"api_secret",
//                                       nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [cachedAuth authorizeRequest:request];
    
    NSLog(@"FETCH URL: %@", request);
    
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    //    [myFetcher setAuthorizer:cachedAuth];
    [myFetcher beginFetchWithDelegate:self
                    didFinishSelector:@selector(twitterFetcher:finishedWithData:error:)];
}

- (void)twitterFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error 
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
    // Remove the stored Twitter authentication from the keychain, if any
    [GTMOAuthWindowController removeParamsFromKeychainForName:kTwitterKeychainItemName];
    
    // Discard our retained authentication object
    [self setAuthentication:nil];
    
    [self updateUI];
}

- (GTMOAuthAuthentication *)authForTwitter {
    // Note: to use this sample, you need to fill in a valid consumer key and
    // consumer secret provided by Twitter for their API
    //
    // http://twitter.com/apps/
    //
    // The controller requires a URL redirect from the server upon completion,
    // so your application should be registered with Twitter as a "web" app,
    // not a "client" app
    NSString *myConsumerKey = [[NSUserDefaults standardUserDefaults] valueForKey:@"twitterConsumerKey"];
    NSString *myConsumerSecret = [[NSUserDefaults standardUserDefaults] valueForKey:@"twitterConsumerSecret"];
    
    if ([myConsumerKey length] == 0 || [myConsumerSecret length] == 0) {
        return nil;
    }
    
    GTMOAuthAuthentication *auth;
    auth = [[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
                                                        consumerKey:myConsumerKey
                                                         privateKey:myConsumerSecret];
    
    // setting the service name lets us inspect the auth object later to know
    // what service it is for
    [auth setServiceProvider:@"Twitter"];
    return auth;
}

- (void)signInToTwitter {
    
    [self signOut];
    
    NSURL *requestURL = [NSURL URLWithString:@"http://twitter.com/oauth/request_token"];
    NSURL *accessURL = [NSURL URLWithString:@"http://twitter.com/oauth/access_token"];
    NSURL *authorizeURL = [NSURL URLWithString:@"http://twitter.com/oauth/authorize"];
    NSString *scope = @"http://api.twitter.com/";
    
    GTMOAuthAuthentication *auth = [self authForTwitter];
//    if (!auth) {
//        [self displayErrorThatTheCodeNeedsATwitterConsumerKeyAndSecret];
//    }
    
    // set the callback URL to which the site should redirect, and for which
    // the OAuth controller should look to determine when sign-in has
    // finished or been canceled
    //
    // This URL does not need to be for an actual web page
    [auth setCallback:@"http://www.noverse.com/OAuthTwitterCallback"];
    
    GTMOAuthWindowController *windowController;
    windowController = [[GTMOAuthWindowController alloc] initWithScope:scope
                                                               language:nil
                                                        requestTokenURL:requestURL
                                                      authorizeTokenURL:authorizeURL
                                                         accessTokenURL:accessURL
                                                         authentication:auth
                                                         appServiceName:kTwitterKeychainItemName
                                                         resourceBundle:nil];
    [windowController signInSheetModalForWindow:self.window
                                       delegate:self
                               finishedSelector:@selector(windowController:finishedWithAuth:error:)];
}

- (void)windowController:(GTMOAuthWindowController *)windowController
        finishedWithAuth:(GTMOAuthAuthentication *)auth
                   error:(NSError *)error {
    
    [apiResultTextView setString:@""];
    
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        NSLog(@"Authentication error: %@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            NSString *str = [[NSString alloc] initWithData:responseData
                                                   encoding:NSUTF8StringEncoding];
            NSLog(@"%@", str);
            [apiResultTextView setString:str];
        }
        
        [self setAuthentication:nil];
    } else {
        // Authentication succeeded
        //
        // At this point, we either use the authentication object to explicitly
        // authorize requests, like
        //
        //   [auth authorizeRequest:myNSURLMutableRequest]
        //
        // or store the authentication object into a Google API service object like
        //
        //   [[self contactService] setAuthorizer:auth];
        
        // save the authentication object
        [self setAuthentication:auth];
    }
    
    [self updateUI];
}

- (void)setAuthentication:(GTMOAuthAuthentication *)auth 
{
    cachedAuth = auth;
    //    [cachedAuth autorelease];
    //    cachedAuth = [auth retain];
}

- (BOOL)isSignedIn {
    BOOL isSignedIn = [cachedAuth canAuthorize];
    return isSignedIn;
}

- (void)updateUI {
    // update the text showing the signed-in state and the button title
    if ([self isSignedIn]) {
        // signed in
        NSString *token = [cachedAuth token];
        NSString *email = [cachedAuth userEmail];
        
        BOOL isVerified = [[cachedAuth userEmailIsVerified] boolValue];
        if (!isVerified) {
            // email address is not verified
            //
            // The email address is listed with the account info on the server, but
            // has not been confirmed as belonging to the owner of this account.
            email = [email stringByAppendingString:@" (unverified)"];
        }
        
        [accessTokenField setStringValue:(token != nil ? token : @"")];
        [usernameField setStringValue:(email != nil ? email : @"")];
//        [mSignInOutButton setTitle:@"Sign Out"];
        [fetchButton setEnabled:YES];
    } else {
        // signed out
        [usernameField setStringValue:@"-Not signed in-"];
        [accessTokenField setStringValue:@"-No token-"];
//        [mSignInOutButton setTitle:@"Sign In..."];
        [fetchButton setEnabled:NO];
    }
}


@end
