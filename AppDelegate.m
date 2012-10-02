//
//  AppDelegate.m
//  Haidy House
//
//  Created by Jan Koranda on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "WebViewController.h"

#import "LinphoneManager.h"
#include "linphonecore.h"

#if __clang__ && __arm__
extern int __divsi3(int a, int b);
int __aeabi_idiv(int a, int b);
int __aeabi_idiv(int a, int b) {
	return __divsi3(a,b);
}
#endif

///doimplementovat delegáta skončil jsem někde u applicationDidBecomeActive

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self synchronizeDefaults];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground
        && [[NSUserDefaults standardUserDefaults] boolForKey:@"disable_autoboot_preference"]) {
		// autoboot disabled, doing nothing
	} else {
        [self startSIPApplication];
    }
      
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    // Override point for customization after application launch.
    UIViewController *mRootViewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        mRootViewController = [[WebViewController alloc] initWithNibName:@"WebViewController_iPhone" bundle:nil];
    } else {
        mRootViewController = [[WebViewController alloc] initWithNibName:@"WebViewController_iPad" bundle:nil];
    }
    
    UINavigationController *mNavigatonController = [[UINavigationController alloc] initWithRootViewController:mRootViewController];
    self.window.rootViewController = mNavigatonController;
    [self.window makeKeyAndVisible];
        
    return YES;
    
    
    /*
     UIViewController *viewController1, *viewController2, *viewController3;
     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
     viewController1 = [[WebViewController alloc] initWithNibName:@"WebViewController_iPhone" bundle:nil];
     viewController2 = [[SIPViewController alloc] initWithNibName:@"SIPViewController_iPhone" bundle:nil];
     viewController3 = [[WebViewControllerMap alloc] initWithNibName:@"WebViewControllerMap_iPhone" bundle:nil];
     } else {x
     viewController1 = [[WebViewController alloc] initWithNibName:@"WebViewController_iPad" bundle:nil];
     viewController2 = [[SIPViewController alloc] initWithNibName:@"SIPViewController_iPad" bundle:nil];
     viewController3 = [[WebViewControllerMap alloc] initWithNibName:@"WebViewControllerMap_iPad" bundle:nil];
     }
     
     self.tabBarController = [[UITabBarController alloc] init];
     self.tabBarController.viewControllers = [NSArray arrayWithObjects:viewController1,  viewController3, viewController2, nil];
     
     UIImage *homeImage = [UIImage imageNamed:@"Home.png"];
     UIImage *phoneImage = [UIImage imageNamed:@"Phone.png"];
     
     // ikonek pro jednotlivé tabbary
     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
     [[[self.tabBarController.viewControllers objectAtIndex:0] tabBarItem] setImage:homeImage];
     [[[self.tabBarController.viewControllers objectAtIndex:1] tabBarItem] setImage:homeImage];
     [[[self.tabBarController.viewControllers objectAtIndex:2] tabBarItem] setImage:phoneImage];
     
     } else {
     [[[self.tabBarController.viewControllers objectAtIndex:0] tabBarItem] setImage:homeImage];
     [[[self.tabBarController.viewControllers objectAtIndex:1] tabBarItem] setImage:homeImage];
     [[[self.tabBarController.viewControllers objectAtIndex:2] tabBarItem] setImage:phoneImage];
     
     }
     
     self.window.rootViewController = self.tabBarController;
     */
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    if (call == NULL)
        return;
    
    /* save call context */
    LinphoneManager* instance = [LinphoneManager instance];
    instance->currentCallContextBeforeGoingBackground.call = call;
    instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);
    
    const LinphoneCallParams* params = linphone_call_get_current_params(call);
    if (linphone_call_params_video_enabled(params)) {
        linphone_call_enable_camera(call, false);
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    
    if (![[LinphoneManager instance] enterBackgroundMode]) {
        // destroying eventHandler if app cannot go in background.
        // Otherwise if a GSM call happen and Linphone is resumed,
        // the handler will be called before LinphoneCore is built.
        // Then handler will be restored in appDidBecomeActive cb
        callCenter.callEventHandler = nil;
        callCenter = nil;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
        [self synchronizeDefaults];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground
        && [[NSUserDefaults standardUserDefaults] boolForKey:@"disable_autoboot_preference"]) {
		// autoboot disabled, doing nothing
        return;
    } else if ([LinphoneManager instance] == nil) {
        [self startSIPApplication];
    }
    
	[[LinphoneManager instance] becomeActive];
    
    if (callCenter == nil) {
        callCenter = [[CTCallCenter alloc] init];
        callCenter.callEventHandler = ^(CTCall* call) {
            // post on main thread
            [self performSelectorOnMainThread:@selector(handleGSMCallInteration:)
                                   withObject:callCenter
                                waitUntilDone:YES];
        };
    }
    // check call state at startup
    [self handleGSMCallInteration:callCenter];
    
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    if (call == NULL)
        return;
    
    LinphoneManager* instance = [LinphoneManager instance];
    if (call == instance->currentCallContextBeforeGoingBackground.call) {
        const LinphoneCallParams* params = linphone_call_get_current_params(call);
        if (linphone_call_params_video_enabled(params)) {
            linphone_call_enable_camera(
                                        call,
                                        instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
        }
        instance->currentCallContextBeforeGoingBackground.call = 0;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    LinphoneCall* call;
	[(NSData*)([notification.userInfo objectForKey:@"call"])  getBytes:&call];
    if (!call) {
        ms_warning("Local notification received with nil call");
        return;
    }
	linphone_core_accept_call([LinphoneManager getLc], call);
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

-(void)synchronizeDefaults{
   NSLog(@"Test ImHome: %@", [[NSUserDefaults standardUserDefaults] boolForKey:@"ImHome"] == YES ? @"YES": @"NO");
   [self registerDefaultsFromSettingsBundle];
   NSLog(@"Test HomeUrl: %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"HomeUrl"]);
}
    
- (void)registerDefaultsFromSettingsBundle
{
    NSLog(@"Registering default values from Settings.bundle");
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    [defs synchronize];
    
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    
    if(!settingsBundle)
    {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    
    for (NSDictionary *prefSpecification in preferences)
    {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key)
        {
          // check if value readable in userDefaults
          id currentObject = [defs objectForKey:key];
          if (currentObject == nil)
          {
              // not readable: set value from Settings.bundle
              id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
              [defaultsToRegister setObject:objectToSet forKey:key];
              NSLog(@"Setting object %@ for key %@", objectToSet, key);
          }
          else
          {
            // already readable: don't touch
            NSLog(@"Key %@ is readable (value: %@), nothing written to defaults.", key, currentObject);
          }
        }
    }
    
    //nakonec ještě přidáme registraci položky animace
    //prozatím byla vyhozena z bundle setting, dokud nebudeme mít HW nebo SW, který je umí rozumně zobrazit
    [defaultsToRegister setObject:[NSNumber numberWithBool:NO] forKey:@"Animations"];
    
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"NO", @"enable_first_login_view_preference", //
#ifdef HAVE_AMR
                                 @"YES",@"amr_8k_preference", // enable amr by default if compiled with
#endif
#ifdef HAVE_G729
                                 @"YES",@"g729_preference", // enable amr by default if compiled with
#endif
								 //@"+33",@"countrycode_preference",
                                 nil];
    [defaultsToRegister addEntriesFromDictionary:appDefaults];

     
    [defs registerDefaults:defaultsToRegister];
    BOOL mSavedData = [defs synchronize];
    NSLog (@"Uložena data registrace: %@", mSavedData == YES ? @"true" : @"false");
}


#pragma mark - Implementation SIP methods
-(void) startSIPApplication {
    /* explicitely instanciate LinphoneManager */
    LinphoneManager* lm = [[LinphoneManager alloc] init];
    assert(lm == [LinphoneManager instance]);
    
	[[LinphoneManager instance]	startLibLinphone];
    
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound];
    
    [self setupGSMInteraction];
    
    //[[LinphoneManager instance] setCallDelegate:myPhoneViewController];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

}

-(void) setupGSMInteraction {
	callCenter = [[CTCallCenter alloc] init];
    __unsafe_unretained CTCallCenter *mRefCallCenter = callCenter;
    callCenter.callEventHandler = ^(CTCall* call) {
        // post on main thread
        [self performSelectorOnMainThread:@selector(handleGSMCallInteration:)
                               withObject:mRefCallCenter
                            waitUntilDone:YES];
    };
}

-(void) handleGSMCallInteration: (id) cCenter {
    CTCallCenter* ct = (CTCallCenter*) cCenter;
    
    int callCount = [ct.currentCalls count];
    if (!callCount) {
        NSLog(@"No GSM call -> enabling SIP calls");
        linphone_core_set_max_calls([LinphoneManager getLc], 3);
    } else {
        NSLog(@"%d GSM call(s) -> disabling SIP calls", callCount);
        /* pause current call, if any */
        LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
        if (call) {
            NSLog(@"Pausing SIP call");
            linphone_core_pause_call([LinphoneManager getLc], call);
        }
        linphone_core_set_max_calls([LinphoneManager getLc], 0);
    }
}

@end
