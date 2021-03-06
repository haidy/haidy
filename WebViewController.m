//
//  FirstViewController.m
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


#define timeToTick 15

#import "WebViewController.h"
#import "DetailViewController.h"
#import "PopupViewController.h"
#import "ExUtils.h"
#import "WaitingViewController.h"
#import "AboutViewController.h"
#import "LinphoneManager.h"
#import "JsonService.h"
#include <AudioToolbox/AudioToolbox.h>

@interface WebViewController()
{
    WaitingViewController* fWaitingViewController;
}
- (void)configureView:(BOOL)reload;
- (void)showSipController:(BOOL)withCall;
- (void)hideSipController;
@end

/* Třída je call i registračním delegátem pro Linphon managera. Informace předává dále přímo třídě řešící ovládání SIPu - Linphon. Tato třída slouží pro Linphone jako proxy a aby bylo možné v případě potřeby zobrazit okno pro ovládání SIPu nebo ho skrýt a předat mu potřebné informace. O proti standardnímu Linphonu pro iPhon, se nezobrazuje TabBarController s Historií, Kontakty apod, ale zobrazuje se jen upravení PhoneViewController.
 */

@implementation WebViewController

@synthesize fWebView, fImageView, fPhoneViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"House", @"House");
        //self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    
    return self;
}

							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    fIsVisibleSipForIncommingCall = NO;
    
    /// Inicializace detailů stránek
    fDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    fDetailViewController.delegate = self;
    [fDetailViewController loadView];
    [fDetailViewController viewDidLoad];
    [fDetailViewController setModalPresentationStyle: UIModalTransitionStyleCoverVertical];
    
    /// Inicializace ovládání - popupu
    fPopupViewController = [[PopupViewController alloc] initWithNibName:@"PopupViewController" bundle:nil];
    fPopupViewController.delegate = self;
    
    //jako subview bude jen pro iPad, na iPhonu bude view vidět přes navigation controller
    if ([ExUtils runningOnIpad]){
        fPopupView = fPopupViewController.view;
        [fPopupView setFrame:CGRectMake(0,0, 250, self.view.bounds.size.height)];
        [fPopupView setCenter:CGPointMake(-1*fPopupView.frame.size.width/2, self.view.frame.size.height /2)];
        [self.view addSubview:fPopupView];
        [self.view bringSubviewToFront:fPopupView];
        fIsPopupVisible = false;
    }
    
    ///Inicializace waiting dialogu
    fWaitingViewController = [WaitingViewController createWithParentView:self.view];
    
    fWebView.delegate = self;
    
    fOldDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    
    //zaregistrování sebe sama do notoficationcentra pro změny nastavení, zda je uživatel doma.
    //zde přijde zpráva po nastvení hodnoty v settings i při aplikaci v pozadí
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    fNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:timeToTick target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //ať jsme, kde jsme, tak schováme navigation bar, pokud je zobrazený
    if (self.navigationController.navigationBarHidden == NO)
    {
        if ([ExUtils runningOnIpad])
            [self.navigationController setNavigationBarHidden:YES];
        else 
            [self.navigationController setNavigationBarHidden:YES animated:YES];

        
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    [self configureView:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aNewInterfaceOrientation
{
    return aNewInterfaceOrientation == UIInterfaceOrientationPortrait
    || aNewInterfaceOrientation == UIInterfaceOrientationLandscapeRight
    || aNewInterfaceOrientation == UIInterfaceOrientationLandscapeLeft;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    //pokud uživatel rotuje se zařízením, tak skryjeme popup
    [self hidePopupView];
}
        
-(void)showPopupView{
    if ([ExUtils runningOnIpad]){
        if (fIsPopupVisible)
            return;
        //else je zbytek kódu
        
        //test nastavení velikosti navigation controlleru
        //CGRect mRect = self.navigationController.view.frame;
        //[self.navigationController.view setFrame:CGRectMake(mRect.origin.x, mRect.origin.y ,mRect.size.width-50, mRect.size.height)];
        
        [fPopupViewController viewDidAppear:YES];
        fPopupView.center = CGPointMake(-1*fPopupView.frame.size.width/2, self.view.bounds.size.height /2);
        [self.view bringSubviewToFront:fPopupView];
    
        [UIView animateWithDuration:0.2 animations:^{ fPopupView.center= CGPointMake(fPopupView.bounds.size.width / 2, self.view.bounds.size.height /2); }];
        fIsPopupVisible =YES;
    }
    else
    {
        [self.navigationController pushViewController:fPopupViewController animated:NO];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
     
    
        
}

-(void)hidePopupView{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if (fIsPopupVisible == NO)
            return;
        //else je zbytek kódu
    
        [fPopupViewController viewDidDisappear:YES];
        [UIView animateWithDuration:0.2 animations:^{ fPopupView.center= CGPointMake(-1*fPopupView.bounds.size.width/2, self.view.bounds.size.height /2); }];
    
        fIsPopupVisible = NO;
    }
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)showDetailView:(NSURLRequest*)request{
    
    [fDetailViewController loadPage:request];
    [fDetailViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    
    //pokud se nejedná o vybraný detail, tak otevřeme jen FormSheet o vybrané velikosti, jinak otvíráme okno přes FullScreen
    if ([request.URL.absoluteString rangeOfString:@"MeterDetail" options:NSCaseInsensitiveSearch].location == NSNotFound && [request.URL.absoluteString rangeOfString:@"OnOffCameraDetail" options:NSCaseInsensitiveSearch].location == NSNotFound  )
        fDetailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    else
        fDetailViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    
    void (^handler)(void) = ^(void) {
        CGRect mActualFrame = fDetailViewController.view.bounds;
        if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])){
            [fDetailViewController.view.superview setFrame:CGRectMake(mActualFrame.origin.x, mActualFrame.origin.y, 350, mActualFrame.size.width )];
            [fDetailViewController.view.superview setCenter:CGPointMake(self.view.center.y, self.view.center.x)];
        }
        else
        {
            [fDetailViewController.view.superview setFrame:CGRectMake(mActualFrame.origin.x, mActualFrame.origin.y, mActualFrame.size.width, 350)];
            [fDetailViewController.view.superview setCenter:self.view.center];
        }
    };

    //pro iPad upravíme velikost okna, pokud má být zobrazen jako FormSheet
    if ([ExUtils runningOnIpad] && fDetailViewController.modalPresentationStyle == UIModalPresentationFormSheet) {
        [self.navigationController presentViewController:fDetailViewController animated:NO completion:handler];

    }
    else
        [self.navigationController presentViewController:fDetailViewController animated:NO completion:nil];
}

//Getter fPhoneViewControlleru, který zajištuje incializaci dle zařízení
//implementace dle http://www.bdunagan.com/2009/12/22/uitabbarcontroller-from-a-xib/
- (PhoneViewController *)fPhoneViewController{
    if (fPhoneViewController == nil){
        //inicializace SIP PhoneViewControlleru
        if ([ExUtils runningOnIpad] == YES)
            fPhoneViewController = [[PhoneViewController alloc] initWithNibName:@"PhoneViewController-ipad" bundle:nil];
        else
            fPhoneViewController = [[PhoneViewController alloc] initWithNibName:@"PhoneViewController" bundle:nil];
        
    }
    
    return fPhoneViewController;
}

#pragma mark - Implememnt private methods

- (void) configureView:(BOOL)reload
{
    //pokud máme nastavený URL request, tak nic neděláme
    if (fWebView.request != nil && reload == NO)
        return;
    
    //NSString *mPageToLoad = @"http://sharpdev.asp2.cz/haidy/RequestParams.aspx";
    
    NSString *mPageToLoad = @"default.aspx";
    
    
    //Vytvoříme URL, které přijde tak jako tak, eventuelně půjde o prázdnou stránku.
    NSURL *mUrl = [ExUtils constructUrlFromPage:mPageToLoad];
    
    
    NSLog(@"Constructed URL in configureView: %@", mUrl.absoluteString);
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:mUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    //Load the request in the UIWebView.
    [fWebView loadRequest:requestObj];
}

- (void)showSipController:(BOOL)withCall{    
    if ([self.navigationController.viewControllers containsObject:self.fPhoneViewController] == NO)
    {
        if(withCall)
        {
            fIsVisibleSipForIncommingCall = YES;
            [self.navigationController pushViewController:self.fPhoneViewController animated:NO];
        }
        else
           [self.navigationController pushViewController:self.fPhoneViewController animated:YES];
        [self.navigationController setNavigationBarHidden:NO];
    }
    //else není potřeba, fPhoneViewController je již zobrazen
}

- (void)hideSipController{
    fIsVisibleSipForIncommingCall = false;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:YES];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WebViewDelegate

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Chyba při načítání: %@", error);
    
    // Ignore NSURLErrorDomain error -999.
    if (error.code == NSURLErrorCancelled) return;
    
    // Ignore "Fame Load Interrupted" errors. Seen after app store links.
    // Remarks: Nastane i v případě, že se stane redirect stránky, třeba z důvodu jiné velikosti písma v názvu url např. /HaidySmartClient/ a /HAIdySmartClient
    else if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]){
        [ExUtils handlingErrorCode102WithWebKitErrorDomain:aWebView.request.URL.absoluteString];
        return;
    }
    //else: není potřeba, jde o zbytek kódu
    
    // Normal error handling…
    UIAlertView *mAllertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Bad connect", @"Nepodařilo se připojit") message:NSLocalizedString(@"Connect request", @"Chcete se připojit vzdáleně nebo jste doma?") delegate:self cancelButtonTitle:NSLocalizedString(@"Button Home", @"")
        otherButtonTitles:NSLocalizedString(@"Button Remotely", @""), NSLocalizedString(@"Button Cancel", nil), nil ];
    [mAllertView setTag:0];
    [mAllertView show];
}

-(void) imHomeAllertView:(UIAlertView*)aAllertView clickedButtonAtIndex:(NSInteger)aButtonIndex{
    // the user clicked one of the OK/Cancel buttons
    if (aButtonIndex == 0)
    {
        NSLog(@"Potvrzeno jsem doma");
        [ExUtils setInHome:YES];
    }
    else if (aButtonIndex == 1)
    {
        NSLog(@"Nastaveno jsem vzdáleně");
        [ExUtils setInHome:NO];
    }
    else
        return;
    
    [self configureView:YES];
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType
{
    //jako první otestujeme, zda nejde o touch událost
    if ( [[[aRequest URL] absoluteString] hasPrefix:@"touch:"] ) {
        //.. parse arguments
        [self hidePopupView];
        return NO;
    }
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked && fLoadedErrorPage == NO) {
        [self showDetailView:aRequest];
        return NO;
    }
    
    //pokud je načtená Error stránka, tak nyní request projde, a my jen zrušíme příznak
    if (fLoadedErrorPage == YES)
        fLoadedErrorPage = NO;
    
    //do všech requestů potřebujeme přidat povinné cokies
    [ExUtils setRequiredCookies:aRequest];
    
    //do všech requestů potřebujeme přidat povinné parametry
    //pokud dotaz parametry neobsahuje, je modifikován a je potřeba zavolat nový request
    BOOL mLoadCurrentRequest = [ExUtils setRequiredRequestParams:aRequest];
    if (mLoadCurrentRequest == NO)
    {
        [webView loadRequest:aRequest];
        return NO;
    }
    
    [fWaitingViewController startWaiting];
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    //Prevence proti handlingErrorCode102WithWebKitErrorDomain, nevím proč, ale pokud je uživatel již přihlášen a spusti se aplikačka, tak nedojde k chybě a tato metoda se nezavolá
    [ExUtils handlingErrorCode102WithWebKitErrorDomain:aWebView.request.URL.absoluteString];
    
    //nejprve ze stránky odebereme defaultní navigaci
    NSString *jsCommand = [NSString stringWithFormat:@"removeNavFloors();"];
    [aWebView stringByEvaluatingJavaScriptFromString:jsCommand];
    
    //následně do stránky přidáme javascript hlídající touch gesta
    //je potřeba, abychom mohli eventuelně schovat popupview
    jsCommand = [NSString stringWithFormat:@"document.addEventListener('touchstart', function(event) { window.location.replace('touch://www.haidy.cz'); }, false);"];
    [aWebView stringByEvaluatingJavaScriptFromString:jsCommand];
    
    NSString *mTitle = [aWebView stringByEvaluatingJavaScriptFromString:@"getTitle()"];
    if ([mTitle rangeOfString:@"Error" options:NSCaseInsensitiveSearch].location == NSNotFound )
        fLoadedErrorPage = NO;
    else
        fLoadedErrorPage = YES;

    [fWaitingViewController stopWaiting];
}
     
#pragma mark - UIAllertViewDelegate
- (void)alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)aButtonIndex {
    
    if (aAlertView.tag == 0)
        [self imHomeAllertView:aAlertView clickedButtonAtIndex:aButtonIndex];
    else if (aAlertView.tag == 1)
        [self notificationAllertView:aAlertView clickedButtonAtIndex:aButtonIndex];
    //else - pokud přijde něco co neznáme, tak to má smůlu
}

#pragma mark - Swipe Gesture

- (IBAction) handleSwipeRight:(UISwipeGestureRecognizer*)sender
{
    [self showPopupView];
    [fPopupViewController loadJSONData];
}

- (IBAction) handleSwipeLeft:(UISwipeGestureRecognizer*)sender;
{
    [self hidePopupView];
}

#pragma mark - Implement SubViewControllerDelegate
-(void) detailViewControllerDidFinish:(id)controller andError:(BOOL)mError
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (mError == YES)
        [self configureView:YES];
    //else není potřeba, je pro všechny případy stejné viz první řádek
}

#pragma mark - Implement PopupViewControllerDelegate
-(void) selectWebPage:(NSString *)aPage{

    NSURL *mUrl = [ExUtils constructUrlFromPage:aPage];
    
    NSLog(@"Constructed URL in selectWebPage: %@", mUrl.absoluteString);
    
    //URL Requst Object
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:mUrl];
    (void)[ExUtils setRequiredRequestParams:mRequest];
    //Load the request in the UIWebView.
    [fWebView loadRequest:mRequest];
    
    [self hidePopupView];
}

-(void) selectSip{
    [self showSipController:NO];
}

-(void) selectAbout{
    AboutViewController *mAboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    [self.navigationController pushViewController:mAboutViewController animated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

#pragma mark - Implement LinphoneUICallDelegate - most methods only recal to fPhoneViewController

-(void) displayDialer:(UIViewController*) viewCtrl {
	[self.fPhoneViewController displayDialer:viewCtrl];
}

-(void) callEnd:(UIViewController *)viewCtrl{
    [self.fPhoneViewController callEnd:viewCtrl];
    
    //tohle tu je kvůli tomu, aby se po ukončení hovoru schoval SIP, pokud předtím nebyl zobrazen
    if (fIsVisibleSipForIncommingCall)
        [self hideSipController];
    //else - pokud je zobrazený SIP kvůli příchozímu hovoru, tak ho zavřeme. Pokud by tomu tak nebylo, tak se zobrazí záložka Dialer a my zde v else nemusíme nic dělat.
}

-(void) displayIncomingCall:(LinphoneCall*) call NotificationFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [self showSipController:YES];
    [self.fPhoneViewController displayIncomingCall:call NotificationFromUI:viewCtrl forUser:username withDisplayName:displayName];

}
-(void) displayCall: (LinphoneCall*) call InProgressFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [self showSipController:YES];
    [self.fPhoneViewController displayCall:call InProgressFromUI:viewCtrl forUser:username withDisplayName:displayName];
}

-(void) displayInCall: (LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [self showSipController:YES];
    [self.fPhoneViewController displayInCall:call FromUI:viewCtrl forUser:username withDisplayName:displayName];
}

-(void) displayVideoCall:(LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [self showSipController:YES];
    [self.fPhoneViewController displayVideoCall:call FromUI:viewCtrl forUser:username withDisplayName:displayName];
}

//status reporting
-(void) displayAskToEnableVideoCall:(LinphoneCall*) call forUser:(NSString*) username withDisplayName:(NSString*) displayName {
	[self.fPhoneViewController  displayAskToEnableVideoCall:call forUser:username withDisplayName:displayName];
}

-(void) firstVideoFrameDecoded: (LinphoneCall*) call {
    [self.fPhoneViewController firstVideoFrameDecoded:call];
}

#pragma mark - Implement Notification from HAIDY webserver

-(void)timerTick:(NSTimer*)aTimer{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //očekáváme, že přijde pole, proto proměnná typu array
        NSArray* mNotifications = [JsonService getNotifications];
        
        while ([LinphoneManager instance] != nil && [LinphoneManager isLcReady] && [[LinphoneManager instance] existCall]) {
            //pokud přichází hovor, nebo je vytočený, tak zde počkáme a notifikujeme až po hovoru
            sleep(10);
        }
        
        if (mNotifications != nil && mNotifications.count != 0)
            [self performSelectorOnMainThread:@selector(fetchedNofitications:) withObject:mNotifications waitUntilDone:NO];
    });
}

-(void) fetchedNofitications:(NSArray*)aNotifications
{
    int o = 0;
    for (NSDictionary *mNotification in aNotifications) {
        NSString *mNotificationText = [mNotification objectForKey:@"Text"];
        if (o == 2)
            mNotificationText = [NSString stringWithFormat:NSLocalizedString(@"ExistCountNotification",@"Šablona pro text"), [aNotifications count] ];
        //else existují ještě další nevyzvednuté notifikace, ale ty nás již nezajímají na konci foru bude cyklus ukončen
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
            && [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground)
        {
            //nejsme v aktivním stavu a tak vyhodíme lokální notifikaci
            UILocalNotification *mLocalNotification = [[UILocalNotification alloc] init];
            if (mLocalNotification != nil)
            {
                mLocalNotification.repeatInterval = 0;
                mLocalNotification.alertBody = mNotificationText ;
                mLocalNotification.alertAction = NSLocalizedString(@"Show", nil);
                mLocalNotification.soundName = UILocalNotificationDefaultSoundName;
                mLocalNotification.userInfo = [NSDictionary dictionaryWithObject:@"haidy" forKey:@"haidyNotification"];
                [[UIApplication sharedApplication]  presentLocalNotificationNow:mLocalNotification];
            }
        }
        else
        {
            if (fNotificationAllertView != nil)
                [fNotificationAllertView dismissWithClickedButtonIndex:fNotificationAllertView.cancelButtonIndex animated:NO];
            // jsme v aktivním stavu a tak vyhodíme alertview
            fNotificationAllertView = [[UIAlertView alloc] initWithTitle:[mNotification objectForKey:@"Kind"] message:mNotificationText delegate:self cancelButtonTitle:NSLocalizedString(@"Ignore", "Ignorovat notifikaci") otherButtonTitles:NSLocalizedString(@"Show", nil), nil];
            [fNotificationAllertView setTag:1];
                [fNotificationAllertView show];
            
            //sound efetekt udělat podle toho co přijde v notifickaci
            SystemSoundID audioEffect;
            NSString* path = [[NSBundle mainBundle]
                              pathForResource:@"HaidyNotification" ofType:@"wav"];
            NSURL *pathURL = [NSURL fileURLWithPath : path];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &audioEffect);
            AudioServicesPlaySystemSound(audioEffect);
        }
        
        if (o < 2)
            o += 1;
        else
            break;
    }
}

-(void) notificationAllertView:(UIAlertView*)aAllertView clickedButtonAtIndex:(NSInteger)aButtonIndex{
   if (aButtonIndex == aAllertView.cancelButtonIndex)
       return;
    // else není potřeba, pokračujeme dále
    
    //zobrazíme stránku s notifikacemi
    NSMutableURLRequest *mNotificationRequest = [NSMutableURLRequest requestWithURL:[ExUtils constructUrlFromPage:@"default.aspx"]];
    [mNotificationRequest setHTTPMethod:@"POST"];
    [mNotificationRequest setHTTPBody:[@"SelectedMenuNodeId=Notifications" dataUsingEncoding:NSUTF8StringEncoding]];
    [self.fWebView loadRequest:mNotificationRequest];
    if (self.navigationController.visibleViewController != nil && self.navigationController.visibleViewController != self)
    {
        [self.navigationController.visibleViewController dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    //else - nic schovávat nechceme
}

#pragma mark - Implememnt Notification change

static NSDictionary *fOldDefaults;

- (void)defaultsChanged:(NSNotification *)notification {
    NSDictionary *mNewDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    BOOL mNeedReload = NO;

    BOOL mOldBoolValue = [[fOldDefaults valueForKey:@"ImHome"] boolValue];
    BOOL mNewBoolValue = [[mNewDefaults valueForKey:@"ImHome"] boolValue];
    if (mOldBoolValue != mNewBoolValue)
        mNeedReload = YES;
    //else rovnají se, pokračujeme v testování
    
    NSString *mOldValue = [fOldDefaults valueForKey:@"HomeUrl"];
    NSString *mNewValue = [mNewDefaults valueForKey:@"HomeUrl"];
    if (![mNewValue isEqualToString:mOldValue] && [ExUtils inHome])
        mNeedReload = YES;
    //else rovnají se, pokračujeme v testování
    
    mOldValue = [fOldDefaults valueForKey:@"RemotelyUrl"];
    mNewValue = [mNewDefaults valueForKey:@"RemotelyUrl"];
    if (![mNewValue isEqualToString:mOldValue] && ![ExUtils inHome])
        mNeedReload = YES;
    //else rovnají se, pokračujeme v testování
    
    
    if (mNeedReload)
    {
        fOldDefaults = mNewDefaults;
        if (self.navigationController.presentedViewController != nil && [self.navigationController.presentedViewController isKindOfClass:[DetailViewController class]])
            [self.navigationController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
        //else - nic schovávat nechceme
        
        //zajistíme refres okna
        [self configureView:YES];
    }
}


@end
