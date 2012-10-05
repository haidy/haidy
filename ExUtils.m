//
//  ExUtils.m
//  Haidy-House
//
//  Created by Jan Koranda on 8/24/12.
//
//

#import "ExUtils.h"

@implementation ExUtils


static NSNumber* fInHome = nil;

+(BOOL) inHome{
    if (fInHome == nil)
    {
        fInHome = [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"ImHome"]];
        NSLog (@"Loaded ImHome: %@", [[NSUserDefaults standardUserDefaults] boolForKey:@"ImHome"] == YES ? @"true" : @"false");
        
    }
    return [fInHome boolValue];
}

+(void) setInHome:(BOOL)aInHome{
    fInHome = [NSNumber numberWithBool:aInHome];
}



+(NSURL*) constructUrlFromPage:(NSString*)aPage{
    
    //Pokud příchozí stránka obsahuje HTTP, tak ji zkusím naparsovat a ev. rovnou vrátit
    if ([aPage rangeOfString:@"http://"].location != NSNotFound)
    {
        NSURL *mUrl = [NSURL URLWithString:aPage];
        if (mUrl != nil)
            return mUrl;
    }
    
    NSString *mPageUrl = nil;
    BOOL mSecure = NO;
    
    if ([self inHome] == YES)
    {
        mPageUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"HomeUrl"];
        mSecure = [[NSUserDefaults standardUserDefaults] boolForKey:@"HomeSecure"];
    }
    else
    {
        mPageUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"RemotelyUrl"];
        mSecure = [[NSUserDefaults standardUserDefaults] boolForKey:@"RemotelySecure"];
    }
    
    //může nám přijít stránka již s přesnější specifikací na HaidySmartClient, podle toho budeme vytvářet URL
    if ([[aPage lowercaseString] rangeOfString:@"haidysmartclient"].location == NSNotFound)
    {
        if ([mPageUrl rangeOfString:@"http://"].location == NSNotFound && mSecure == NO)
            mPageUrl = [NSString stringWithFormat:@"http://%@/HaidySmartClient/%@", mPageUrl, aPage];
        else if ([mPageUrl rangeOfString:@"https://"].location == NSNotFound && mSecure == YES)
            mPageUrl = [NSString stringWithFormat:@"https://%@/HaidySmartClient/%@", mPageUrl, aPage];
    }
    else
    {
        if ([mPageUrl rangeOfString:@"http://"].location == NSNotFound && mSecure == NO)
            mPageUrl = [NSString stringWithFormat:@"http://%@%@", mPageUrl, aPage];
        else if ([mPageUrl rangeOfString:@"https://"].location == NSNotFound && mSecure == YES)
            mPageUrl = [NSString stringWithFormat:@"https://%@%@", mPageUrl, aPage];
    }
                        
    //Create a final URL object.
    NSURL *mUrl = [NSURL URLWithString:mPageUrl];
    if (mUrl == nil)
    {
        UIAlertView *allert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server url", nil) message:NSLocalizedString(@"Bad URL", @"Asi špatný url.") delegate:nil cancelButtonTitle:NSLocalizedString(@"Button Close", nil) otherButtonTitles:nil, nil ];
        [allert show];
        return [self blankPage];
    }
    
    return mUrl;
}

+(NSURL*)blankPage{
    NSString* mBlankPagePath = [[NSBundle mainBundle] pathForResource:@"BlankPage" ofType:@"html"];
    NSLog(@"BlankPage url: %@", mBlankPagePath);
   return  [NSURL fileURLWithPath:mBlankPagePath];
}

///aRequest - Request, který bude modifikován
///result - YES má se provést request, NO nemá se provést request a zavolá se znovu načtení s aktuální modifikací
+(BOOL)setRequiredRequestParams:(NSURLRequest *)aRequest{
    //oblezlička proto, abych mohl aplikačně přidávat parametry do všech requestů
    if ([aRequest.URL.absoluteString rangeOfString:@"animations"].location == NSNotFound)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *appendUrl = [NSString stringWithFormat: @"textures=%@&animations=%@",[defaults stringForKey:@"Textures"], [defaults stringForKey:@"Animations"]];
        NSLog(@"Append parametrs to URL: %@", appendUrl);
        
        NSMutableString *existingUrl = [[NSMutableString alloc] initWithString:aRequest.URL.absoluteString];
        
        if ([existingUrl rangeOfString:@"?"].location == NSNotFound)
            [existingUrl appendFormat:@"?%@", appendUrl];
        else
            [existingUrl appendFormat:@"&%@", appendUrl];
        
        [(NSMutableURLRequest*)aRequest setURL:[aRequest.URL initWithString:existingUrl]];
        return NO;
    }

    return YES;
}

///Nastaví povinné cookies
///aRequest - zdroj pro URL k jakému se má cookie vlastně nastavit
+ (void)setRequiredCookies:(NSURLRequest*)aRequest{
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:@"CulturePreference" forKey:NSHTTPCookieName];
    
    
    
    //Vezmeme z aplikace seznam podporovaných jazyků, ten porovnáme s preferovanými jazyky v systému a to nám vratí pole preferovaných jazyků. Pokud bude mít uživatel vybraný jazyk, který naše aplikace nepodporuje, tak metoda vrátí defaultní jazyk vývojového prostředí. 
    NSArray *mApplicationPreferedLanguages = [NSBundle preferredLocalizationsFromArray:[[NSBundle mainBundle] preferredLocalizations]];
    
    NSLog(@"Count prefered language %d, Prefered language: %@", mApplicationPreferedLanguages.count, [mApplicationPreferedLanguages objectAtIndex:0]);
    
    NSString *mUICulture = [mApplicationPreferedLanguages objectAtIndex:0];
    NSString *mCulture = [[[NSLocale currentLocale] localeIdentifier] stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    
    NSString *mCulturePreferenceValue = [NSString stringWithFormat:@"%@|%@", mUICulture, mCulture ];
    
    [cookieProperties setObject:mCulturePreferenceValue forKey:NSHTTPCookieValue];
    
    [cookieProperties setObject:[self domainFromUrl:aRequest.URL.absoluteString] forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:[self domainFromUrl:aRequest.URL.absoluteString] forKey:NSHTTPCookieOriginURL];
    
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
    
    // set expiration to one month from now or any NSDate of your choosing
    // this makes the cookie sessionless and it will persist across web sessions and app launches
    /// if you want the cookie to be destroyed when your app exits, don't set this
    [cookieProperties setObject:[[NSDate date] dateByAddingTimeInterval:2629743] forKey:NSHTTPCookieExpires];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

+(NSString*)domainFromUrl:(NSString*)url
{
    NSArray *first = [url componentsSeparatedByString:@"/"];
    for (NSString *part in first) {
        if ([part rangeOfString:@"."].location != NSNotFound){
            return part;
        }
    }
    return nil;
}

+(BOOL) runningOnIpad {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

@end
