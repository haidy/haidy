//
//  ExUtils.m
//  Haidy-House
//
//  Created by Jan Koranda on 8/24/12.
/*
 * Copyright (C) 2012  Haidy a.s., Prague, Czech Republic
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */


#import "ExUtils.h"

@interface ExUtils()
{
}
+(void) setUrlPartOne:(NSString*)aPartOneUrl;
+(NSString*) urlPartOne;

@end


@implementation ExUtils

static NSUserDefaults *fOldDefaults;

+(BOOL)reloadAfterChangeSettings:(NSUserDefaults *)aSettings{
    if (fOldDefaults == nil)
    {
        fOldDefaults = aSettings;
        return NO;
    }
    else
    {
        
    }
    
    return NO;
}

+(BOOL) inHome{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ImHome"];
}

+(void) setInHome:(BOOL)aInHome{
    [[NSUserDefaults standardUserDefaults] setBool:aInHome forKey:@"ImHome"];
    
    NSLog (@"Set ImHome: %@", [[NSUserDefaults standardUserDefaults] boolForKey:@"ImHome"] == YES ? @"true" : @"false");
}

+(BOOL) useSip{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"UseSIP"];
}

+(void) setUseSip:(BOOL)aUseSip{
    [[NSUserDefaults standardUserDefaults] setBool:aUseSip forKey:@"UseSIP"];
    NSLog (@"Set UseSIP: %@", [[NSUserDefaults standardUserDefaults] boolForKey:@"UseSIP"] == YES ? @"true" : @"false");
}

static NSArray* fRemoteServerSessions;

+(void) setUrlPartOne:(NSString *)aUrlPartOne{
    [[NSUserDefaults standardUserDefaults] setValue:aUrlPartOne forKey:@"UrlPartOne"];
    NSLog(@"UrlPartOne changed to: %@", aUrlPartOne);
}

+(NSString *)urlPartOne{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"UrlPartOne"];
}

+(void) setSelectedRemoteServerSession:(NSString*)aRemoteServerSession{
    [[NSUserDefaults standardUserDefaults] setValue:aRemoteServerSession forKey:@"SelectedRemoteServerSession"];
}


+(NSString*) selectedRemoteServerSession{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"SelectedRemoteServerSession"];
}

+(void) setNotificationArray:(NSMutableArray*)aArray{
    [[NSUserDefaults standardUserDefaults] setValue:aArray forKey:@"NotificationArray"];
}

static NSLock *fLock = nil;

+(NSMutableArray*) notificationArray{
    if (fLock == nil)
        fLock = [[NSLock alloc] init];
    
    [fLock lock];
    
    NSMutableArray* mNotificationArray = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] arrayForKey:@"NotificationArray"];
    if (mNotificationArray == nil)
    {
        mNotificationArray = [[NSMutableArray alloc] initWithObjects: nil];
        [self setNotificationArray:mNotificationArray];
    }
    //else dictionary je nic nemusíme dělat
    
    [fLock unlock];
    return mNotificationArray;
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
    if ([aPage rangeOfString:[self urlPartOne] options:NSCaseInsensitiveSearch].location == NSNotFound )
    {
        if ([mPageUrl rangeOfString:@"http://"].location == NSNotFound && mSecure == NO)
            mPageUrl = [NSString stringWithFormat:@"http://%@/%@/%@/%@", mPageUrl, [self urlPartOne], [self selectedRemoteServerSession], aPage];
        else if ([mPageUrl rangeOfString:@"https://"].location == NSNotFound && mSecure == YES)
            mPageUrl = [NSString stringWithFormat:@"https://%@/%@/%@/%@", mPageUrl, [self urlPartOne], [self selectedRemoteServerSession], aPage];
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

//Zjistí, zda došlo k chybě při načítání stránky z HAIDY webserveru. Pokud ano, tak získá novou defaultní první část url dotazu a přenastaví ji, aby se chyba nemohla opakovat. A nedocházelo tak k odhlašování.
//aLoadedUrl: Url stránky, která byla načtena
+(void)handlingErrorCode102WithWebKitErrorDomain:(NSString *)aLoadedUrl{
    //pokud dojde k této chybě, tak otestujeme,
    NSRange mRangeDefaultPartOneUrl = [aLoadedUrl rangeOfString:[ExUtils urlPartOne] options:NSCaseInsensitiveSearch];
    if (mRangeDefaultPartOneUrl.location != NSNotFound)
    {
        NSString *mNewDefaultPartOneUrl = [aLoadedUrl substringWithRange:mRangeDefaultPartOneUrl];
        [ExUtils setUrlPartOne:mNewDefaultPartOneUrl];
    }
    //else není potřeba, šlo o načtení stránky bez defaultPartOneUrl a to nás nezajímá
}

+(NSURL*)blankPage{
    NSString* mBlankPagePath = [[NSBundle mainBundle] pathForResource:@"BlankPage" ofType:@"html"];
    NSLog(@"BlankPage url: %@", mBlankPagePath);
   return  [NSURL fileURLWithPath:mBlankPagePath];
}

///aRequest - Request, který bude modifikován
///result - YES má se provést request, NO nemá se provést request a zavolá se znovu načtení s aktuální modifikací
+(BOOL)setRequiredRequestParams:(NSURLRequest *)aRequest{
    if ([aRequest.URL.absoluteString rangeOfString:@"BlankPage" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return YES; //má se načíst blankpage a k té nechceme přidávat nic
    //else není potřeba, je zbytek kódu
    
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
  
    if ([aRequest.URL.absoluteString rangeOfString:@"BlankPage" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return; //má se načíst blankpage a k té nechceme přidávat nic
    //else není potřeba, je zbytek kódu
    
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
    
    ////////
    //////// Vytvoření cookie, která informuje web, že jdou dotazy z obálky
    ////////
    
    NSMutableDictionary *wrapCookieProperties = [NSMutableDictionary dictionary];
    [wrapCookieProperties setObject:@"WrappApplication" forKey:NSHTTPCookieName];
    [wrapCookieProperties setObject:@"true" forKey:NSHTTPCookieValue];
    
    [wrapCookieProperties setObject:[self domainFromUrl:aRequest.URL.absoluteString] forKey:NSHTTPCookieDomain];
    [wrapCookieProperties setObject:[self domainFromUrl:aRequest.URL.absoluteString] forKey:NSHTTPCookieOriginURL];
    
    [wrapCookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    [wrapCookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
    
    // set expiration to one month from now or any NSDate of your choosing
    // this makes the cookie sessionless and it will persist across web sessions and app launches
    /// if you want the cookie to be destroyed when your app exits, don't set this
    [wrapCookieProperties setObject:[[NSDate date] dateByAddingTimeInterval:2629743] forKey:NSHTTPCookieExpires];
    
    NSHTTPCookie *wrapCookie = [NSHTTPCookie cookieWithProperties:wrapCookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:wrapCookie];
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

+(void)initRemoteServerSessions:(NSArray*)aRemoteServerSessions{
    fRemoteServerSessions = aRemoteServerSessions;
    if (aRemoteServerSessions.count > 0)
        [self setSelectedRemoteServerSession:[aRemoteServerSessions objectAtIndex:0]];
    else
        [self setSelectedRemoteServerSession:@"MujDum"];
    //toto je tu dočasné, než bude čas pořešit co s více session
    //else - je více nebo žádná session a tak nemůže automaticky vybrat aktivní session
}

@end
