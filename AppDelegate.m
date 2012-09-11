//
//  AppDelegate.m
//  Haidy House
//
//  Created by Jan Koranda on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "WebViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    // Override point for customization after application launch.
    UIViewController *mRootViewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        mRootViewController = [[WebViewController alloc] initWithNibName:@"WebViewController_iPhone" bundle:nil];
    } else {
        mRootViewController = [[WebViewController alloc] initWithNibName:@"WebViewController_iPad" bundle:nil];
    }
    /*
    UIViewController *viewController1, *viewController2, *viewController3;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewController1 = [[WebViewController alloc] initWithNibName:@"WebViewController_iPhone" bundle:nil];
        viewController2 = [[SIPViewController alloc] initWithNibName:@"SIPViewController_iPhone" bundle:nil];
        viewController3 = [[WebViewControllerMap alloc] initWithNibName:@"WebViewControllerMap_iPhone" bundle:nil];
    } else {
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
    
    UINavigationController *mNavigatonController = [[UINavigationController alloc] initWithRootViewController:mRootViewController];
    self.window.rootViewController = mNavigatonController;
    [self.window makeKeyAndVisible];
    
    [self synchronizeDefaults];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
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
         
        [defs registerDefaults:defaultsToRegister];
        BOOL mSavedData = [defs synchronize];
        NSLog (@"Uložena data registrace: %@", mSavedData == YES ? @"true" : @"false");
    }

@end
