# Spike OAuth

**WARNING** This is a [Spike Solution](http://www.extremeprogramming.org/rules/spike.html) to test how to implement OAuth2 in a product I intend to develop.

This spike solution has been written to see if I can use Google's [OAuth2](http://code.google.com/p/gtm-oauth2/) and, where necessary, Google's [OAuth](http://code.google.com/p/gtm-oauth/) libraries to access and use a whole bunch of social networking sites for an application I intend to write for Mac, iPhone and iPad (iOS). As such, the spike is a simple Macintosh application that includes the desktop version of Google's code and its dependencies. These work the same on iOS so I believe this will be a good platform to use. If it works. Hence the spike.

## Current Status

Using OAuth2:

- ✓ StackExchange
- ✓ Disqus

Using OAuth1:

- ✓ Twitter

## Contributing

As this is a spike, please do not ask to contribute. If you have an OAuth2 (or OAuth1) service that's not listed, send me a message and I'll look into adding a sample for it.

## Known Library Hacks

- In `GTMOAuth2Authentication.m` function `updateExpirationDate`: Hack if the `expires_in` key is not found, use the `expires` key. This hack will probably fail under JSON as I am assuming a string version of the number, not a `NSNumber` instance. I'm not making it stick.
