//
//  JsonService.m
//  Haidy-House
//
//  Created by Jan Koranda on 11/28/12.
//
//

#import "JsonService.h"
#import "ExUtils.h"

@interface JsonService()
+(id) getJsonDataWithMethod:(NSString*)aMethod andParametrs:(NSDictionary*)aParametrs;
@end

@implementation JsonService


///
///Synchroně načte data z webové služby. Data jsou převedena z JSON odpovědi, do očekávaného objektu. Předpokládá se, že bude metoda volána asynchroně, aby nebylo bržděno hlavní vlákno.
///
+(id) getJsonDataWithMethod:(NSString*)aMethod andParametrs:(NSDictionary*)aParametrs{
   
    static NSString *mPage = @"ServiceForMobile.svc";
    NSError* error = nil;
   
    //NSString *soapMessage = [NSString stringWithFormat:
    // @"{ %@ } ", parameter
    //                         ];
    
    
	//NSLog(@"%@", soapMessage);
    
    
    //varianta přes NSURLConnection, se synchroním dotazem, před jsme již v asynchroním makru
    //můžeme přidat hlavičky dotazu apod.
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:[[ExUtils constructUrlFromPage:mPage] URLByAppendingPathComponent:aMethod]];
    
    NSLog(@"Constructed URL in getJsonDataWithPage: %@", mRequest.URL.absoluteString);
    
    //prepare http body
    [mRequest setHTTPMethod: @"POST"];
    [mRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (aParametrs != nil)
        [mRequest setHTTPBody: [NSJSONSerialization dataWithJSONObject:aParametrs options:NSJSONWritingPrettyPrinted error:&error]];
    //else nejsou předané parametry, tak není co nastavit do body
    
    if (error != nil)
    {
        NSLog(@"Nepodařilo se serializovat data do JSON");
        return nil;
    }
    //else - data jsou serializovana a tak pokračujeme dále
    
    NSURLResponse *mResponse = nil;
    NSMutableData *mResponseData = (NSMutableData*)[NSURLConnection sendSynchronousRequest:mRequest returningResponse:&mResponse error:&error];
    
    if (error != nil)
        NSLog(@"Error loading data from method getJsonDataFromPage: %@", error);
    
    if (mResponseData.length == 0){
        NSLog(@"Služba %@ nevrátila data", mRequest.URL.absoluteString);
        return nil;
    }
    else
        NSLog(@"Služba %@ vrátila JSON data: %@", mRequest.URL.absoluteString, [[NSString alloc] initWithData:mResponseData encoding:NSUTF8StringEncoding]);
    
    
    //JSON data naparsujeme
    error = nil;
    NSDictionary *mJsonResult = [NSJSONSerialization JSONObjectWithData:mResponseData options:kNilOptions error:&error];
    
    if (error != nil){
        NSLog(@"Chyba při parsování JSON dat: %@", error);
        return nil;
    }
    
    //data jsou vždy vrácena ve formátu { "d": .... }
    if ([mJsonResult valueForKey:@"d"] == [NSNull null])
        return nil;
    else
        return [mJsonResult valueForKey:@"d"] ;
}

+(NSArray*) getFloorsInformation{
    return (NSArray*)[self getJsonDataWithMethod:@"GetFloorsInformation" andParametrs:nil];
}

+(NSArray*) getSipContacts{
    return (NSArray*)[self getJsonDataWithMethod:@"GetSipContacts" andParametrs:nil];
}

+(NSArray*) getSipScenesButtons{
    return (NSArray*)[self getJsonDataWithMethod:@"GetSipScenesButtons" andParametrs:nil];
}

+(void) activateSipSceneWithButton:(NSDictionary*)aButton{
    NSDictionary *mParametrs = [NSDictionary dictionaryWithObjectsAndKeys:aButton, @"aButton", nil];
    [self getJsonDataWithMethod:@"ActivateSipScene" andParametrs:mParametrs];
    return;
}

+(NSArray*) getRemoteServerSessions{
    return (NSArray*)[self getJsonDataWithMethod:@"GetRemoteServerSessions" andParametrs:nil];
}

+(NSArray*) getNotifications{
    return (NSArray*)[self getJsonDataWithMethod:@"CheckForImportantNotification" andParametrs:nil];
}

@end
