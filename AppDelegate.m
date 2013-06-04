//
//  AppDelegate.m
//  Haidy House
//
//  Created by Jan Koranda on 3/27/12.
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

#import "AppDelegate.h"
#import "WebViewController.h"

#import "LinphoneManager.h"
#include "linphonecore.h"
#include "ExUtils.h"
#include "JsonService.h"

///doimplementovat delegáta skončil jsem někde u applicationDidBecomeActive

@implementation AppDelegate

@synthesize window = _window;
@synthesize fNavigationController, fWebViewController;

///
/// Založit timer, po ticku zavolat asynchroně o data notifikací. Až přijdou data, tak je zpracuju a ev vyhodím lokální notifikaci (vše ve zvláštním threadu). Důležité je volat invalidate při přichodu do backgroundu . Zajistit dotazy i v backgroundu.
///



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self synchronizeDefaults];
    
    //Povolení push
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound];
    //zachytávání změny orientace zařízení
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    //notifikuje o změně stavu baterií ... můžeme na to nějak reagovat
    //asi by bylo fajn, kdyby to vyhodilo hlášku nebo by to odpojilo třeba SIP, když ně
    //nesouvisí to se tip
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    //zaregistrujeme appDelegata pro zachycení změny použití SIPu
    //jde o to, abychom mohli SIP ev. deaktivovat
    //nastavujeme observer takto, protože nás zajímají jen změny v rámci app
    //další možnost by bylo použití NotificationCenter NSUserDefaultsDidChangeNotification
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"UseSIP"
                                               options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                                               context:NULL];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        fWebViewController = [[WebViewController alloc] initWithNibName:@"WebViewController_iPhone" bundle:nil];
    } else {
        fWebViewController = [[WebViewController alloc] initWithNibName:@"WebViewController_iPad" bundle:nil];
    }
    
    fNavigationController = [[UINavigationController alloc] initWithRootViewController:fWebViewController];
    self.window.rootViewController = fNavigationController;
    [self.window makeKeyAndVisible];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground
        && [[NSUserDefaults standardUserDefaults] boolForKey:@"disable_autoboot_preference"]) {
		// autoboot disabled, doing nothing
	} else {
        [self startSipApplication];
    }

    //Načteme si ihned ze serveru dostupné RemoteServerSession, abychom je ihned mohli používat a případně vybrat aktivní session
    [ExUtils initRemoteServerSessions:[JsonService getRemoteServerSessions]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    if (ExUtils.useSip)
    {
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
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    
    BOOL registerCustomKeepAllive = false;
    if ([ExUtils useSip])
    {
        if (![[LinphoneManager instance] enterBackgroundMode]) {
            registerCustomKeepAllive = true;
        }
        //else - backgroud mód je pro SIP povolen, nepotřebuj
    }
    else //není povolený
        registerCustomKeepAllive = true;

    //není povolený sip nebo není povolený backgroud mód, zkusíme si zaregistrovat vlastní keepallive
    //register keepalive
    if ([[UIApplication sharedApplication] setKeepAliveTimeout:600
                                                       handler:^{
                                                           NSLog(@"keepalive handler");
                                                           //tělo je úmyslně prázdné, stačí vejít a Timer ve WebView hodí tick a stáhne noticikace.
                                                       }
         ]) {
        
        
        NSLog(@"keepalive handler succesfully registered");
    } else {
        NSLog(@"keepalive handler cannot be registered");
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
    
    if (ExUtils.useSip)
    {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
            && [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground
            && [[NSUserDefaults standardUserDefaults] boolForKey:@"disable_autoboot_preference"]) {
            // autoboot disabled, doing nothing
            return;
        } else if ([LinphoneManager instance] == nil) {
            [self startSipApplication];
        }
        
        [[LinphoneManager instance] becomeActive];
        
       
        LinphoneCore* lc = [LinphoneManager getLc];
        LinphoneCall* call = linphone_core_get_current_call(lc);
        if (call != NULL)
            [[LinphoneManager instance] displayCallFromBackground:call];
        //else -- nemáme aktivní hovor, tak nic neděláme
        
    }
    else
    {
        //SIP se nemá používat, ale může být použitý z dřívějška. Pokud tomu tak je, tak sip deaktivujeme
        [self endSipApplication];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"UseSIP"];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    if([notification.userInfo objectForKey:@"callId"] != nil)
        [[LinphoneManager instance] acceptCallForCallId:[notification.userInfo objectForKey:@"callId"]];

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
    
    NSMutableDictionary *rootSettings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSMutableDictionary *rootSipSettings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"RootSIP.plist"]];
	NSMutableDictionary *sipAudioSettings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"SIPAudio.plist"]];
	NSMutableDictionary *sipVideoSettings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"SIPVideo.plist"]];
    NSMutableDictionary *sipAdvancedSettings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"SIPAdvanced.plist"]];
    
    NSMutableArray *preferences = [rootSettings objectForKey:@"PreferenceSpecifiers"];
    [preferences addObjectsFromArray:[rootSipSettings objectForKey:@"PreferenceSpecifiers"]];
    [preferences addObjectsFromArray:[sipAudioSettings objectForKey:@"PreferenceSpecifiers"]];
    [preferences addObjectsFromArray:[sipVideoSettings objectForKey:@"PreferenceSpecifiers"]];
    [preferences addObjectsFromArray:[sipAdvancedSettings objectForKey:@"PreferenceSpecifiers"]];
    
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
            NSLog(@"Key %@ is read	able (value: %@), nothing written to defaults.", key, currentObject);
          }
        }
    }
    
    //nakonec ještě přidáme registraci položky animace
    //prozatím byla vyhozena z bundle setting, dokud nebudeme mít HW nebo SW, který je umí rozumně zobrazit
    [defaultsToRegister setObject:[NSNumber numberWithBool:NO] forKey:@"Animations"];
    if ([defs objectForKey:@"UrlPartOne"] == nil)
        [defaultsToRegister setObject:@"HAIdySmartClient" forKey:@"UrlPartOne"];
    //else - již je nastaveno nesahat
    if ([defs objectForKey:@"SelectedRemoteServerSession"] == nil)
        [defaultsToRegister setObject:@"startSession" forKey:@"SelectedRemoteServerSession"];
    //else - již je nastaveno nesahat
    
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

#pragma mark - Implementation observe defaults
- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context
{
    if([keyPath isEqual:@"UseSIP"])
    {
        NSLog(@"UseSIP change: %@", change);
        if (ExUtils.useSip)
            [self startSipApplication];
        else
            [self endSipApplication];
    }
}

#pragma mark - Implementation observing orientation

-(void) orientationChanged: (NSNotification*) notif {
    if (ExUtils.useSip && [LinphoneManager isLcReady])
        [[LinphoneManager instance] changeOrientation:[[UIApplication sharedApplication] statusBarOrientation] andVideoView:nil];
}

#pragma mark - Implementation SIP methods
//spustí SIP aplikaci a nastaví jí delegáta pro události
-(void) startSipApplication {
    if (ExUtils.useSip == NO || [LinphoneManager instance] != nil)
        return;
    //else je zbytek kódu
    
    /* explicitely instanciate LinphoneManager */
    LinphoneManager* lm = [[LinphoneManager alloc] init];
    assert(lm == [LinphoneManager instance]);
    
	[[LinphoneManager instance]	startLibLinphone];
    

    [[LinphoneManager instance] setCallDelegate:fWebViewController];
}

//Ukončí SIP applikaci
-(void) endSipApplication{
    if ([LinphoneManager instance] != nil)
        [LinphoneManager destroyInstance];
}

@end
