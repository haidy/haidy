//
//  ExUtils.h
//  Haidy-House
//
//  Created by Jan Koranda on 8/24/12.
//
//

#import <Foundation/Foundation.h>

@interface ExUtils : NSObject
{
    BOOL fInHome;
}


+(NSURL*) constructUrlFromPage:(NSString*)aPage;
+(BOOL) inHome;
+(void) setInHome:(BOOL)aInHome;
+(NSURL*) blankPage;
+(BOOL) setRequiredRequestParams:(NSURLRequest*)aRequest;
+(void) setRequiredCookies:(NSURLRequest*)aRequest;
@end
