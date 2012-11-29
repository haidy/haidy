//
//  JsonService.h
//  Haidy-House
//
//  Created by Jan Koranda on 11/28/12.
//
//

#import <Foundation/Foundation.h>

@interface JsonService : NSObject

+(NSArray*) getFloorsInformation;
+(NSArray*) getSipContacts;
+(NSArray*) getSipScenesButtons;
+(void) activateSipSceneWithButton:(NSDictionary*)aButton;
+(NSArray*) getRemoteServerSessions;

@end
