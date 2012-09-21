//
//  AppDelegate.h
//  Haidy House
//
//  Created by Jan Koranda on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreTelephony/CTCallCenter.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
    CTCallCenter* callCenter;
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

-(void) synchronizeDefaults;
-(void) registerDefaultsFromSettingsBundle;
-(void) setupUI;

//sip methods
-(void) setupGSMInteraction;
-(void) startSIPApplication;

@end
