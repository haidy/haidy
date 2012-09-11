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

@end
