//
//  NVGoogleController.m
//  SpikeOAuth
//
//  Created by Hilton Lipschitz on 4/5/12.
//  Copyright (c) 2012 Noverse LLC. All rights reserved.
//

#import "NVGoogleController.h"

//#import "GTMHTTPFetcherLogging.h"

@interface NVGoogleController ()

- (void)signInToGoogle;
- (void)updateUI;
- (void)setAuthentication:(GTMOAuth2Authentication *)auth;
- (BOOL)isSignedIn;

@end

@implementation NVGoogleController

static NSString *const kGoogleKeychainItemName = @"SpikeOAuth: Google";

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
    [self signInToGoogle];
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
    
    NSURL *url = [NSURL URLWithString:@"https://www.googleapis.com/analytics/v3/data/ga"];
    
    // initialize a date object
    NSDate *currentDate = [[NSDate alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];

//    // create a dateComponents with 2 years and 6 months
//    NSDateComponents *newComponents = [[NSDateComponents alloc] init];
//    [newComponents setDay:-1];    
//    // get a new date by adding components
//    NSDate *oldDate = [[NSCalendar currentCalendar] dateByAddingComponents:newComponents toDate:currentDate options:0];

    
    NSMutableDictionary *paramsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"ga:9189812", @"ids",
                                       [formatter stringFromDate:currentDate], @"start-date",
                                       [formatter stringFromDate:currentDate], @"end-date",
                                       @"ga:pageviews,ga:visitors,ga:newVisits", @"metrics",
                                       nil];
    
    NSString *paramStr = [GTMOAuth2Authentication encodedQueryParametersForDictionary:paramsDict];
    
    NSMutableURLRequest *request;
    request = [[self class] mutableURLRequestWithURL:url
                                         paramString:paramStr];
    
    NSLog(@"FETCH URL: %@", request);
    
    GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [myFetcher setAuthorizer:cachedAuth];
    [myFetcher beginFetchWithDelegate:self
                    didFinishSelector:@selector(googleFetcher:finishedWithData:error:)];
}

- (void)googleFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error 
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
    [GTMOAuth2WindowController removeAuthFromKeychainForName:kGoogleKeychainItemName];
    
    // Discard our retained authentication object
    [self setAuthentication:nil];
    
    [self updateUI];
}

- (GTMOAuth2Authentication *)authForGoogle
{
    NSURL *tokenURL = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/token"];
    
    // We'll make up an arbitrary redirectURI.  The controller will watch for
    // the server to redirect the web view to this URI, but this URI will not be
    // loaded, so it need not be for any actual web page.
    NSString *redirectURI = @"urn:ietf:wg:oauth:2.0:oob";
    
    NSString *clientID = [[NSUserDefaults standardUserDefaults] valueForKey:@"googleClientID"];
    NSString *clientSecret = [[NSUserDefaults standardUserDefaults] valueForKey:@"googleClientSecret"];
    
    NSLog(@"Client ID: %@", clientID);
    NSLog(@"Client Secret: %@", clientSecret);
    NSLog(@"Redirect URI: %@", redirectURI);
    
    GTMOAuth2Authentication *auth;
    auth = [GTMOAuth2Authentication authenticationWithServiceProvider:@"Google"
                                                             tokenURL:tokenURL
                                                          redirectURI:redirectURI
                                                             clientID:clientID
                                                         clientSecret:clientSecret];
    return auth;
}

- (void)signInToGoogle 
{
    [self signOut];
    
    GTMOAuth2Authentication *auth = [self authForGoogle];
    auth.scope = @"https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/analytics.readonly";
    
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
    NSURL *authURL = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/auth"];
    
    GTMOAuth2WindowController *windowController;
    windowController = [GTMOAuth2WindowController controllerWithAuthentication:auth
                                                              authorizationURL:authURL
                                                              keychainItemName:kGoogleKeychainItemName
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
