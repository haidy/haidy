//
//  FirstViewController.m
//  Haidy House
//
//  Created by Jan Koranda on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WebViewController.h"
#import "DetailViewController.h"
#import "PopupViewController.h"
#import "ExUtils.h"
#import "WaitingViewController.h"

@interface WebViewController()
{
    WaitingViewController* fWaitingViewController;
}
- (void)configureView:(BOOL)reload;    
@end

@implementation WebViewController

@synthesize fWebView, fImageView;

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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        fPopupView = fPopupViewController.view;
        [fPopupView setFrame:CGRectMake(0,0, 250, self.view.bounds.size.height)];
        [fPopupView setCenter:CGPointMake(-1*fPopupView.frame.size.width/2, self.view.frame.size.height /2)];
        [self.view addSubview:fPopupView];
        [self.view bringSubviewToFront:fPopupView];
        fIsPopupVisible = false;
    }
    
    ///Inicializace waiting dialogu
    fWaitingViewController = [WaitingViewController createWithParentView:self.view];
    
    /// Nastavení webview a načtení první stránky
    fWebView.delegate = self;
    //nakonec načteme prázdnou stránku
    [fWebView loadRequest:[NSURLRequest requestWithURL:[ExUtils blankPage]]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //ať jsme, kde jsme, tak schováme navigation bar, pokud je zobrazený
    if (self.navigationController.navigationBarHidden == NO)
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
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

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    //pokud uživatel rotuje se zařízením, tak skryjeme popup
    [self hidePopupView];
}
        
- (void) configureView:(BOOL)reload
{
    //pokud máme nastavený URL request, tak nic neděláme
    if (fWebView.request != nil && reload == NO)
        return;
    
    NSString *mPageToLoad = @"http://sharpdev.asp2.cz/haidy/RequestParams.aspx";
    
    //NSString *mPageToLoad = @"default.aspx";
    
    
    //Vytvoříme URL, které přijde tak jako tak, eventuelně půjde o prázdnou stránku.
    NSURL *mUrl = [ExUtils constructUrlFromPage:mPageToLoad];
    
    
    NSLog(@"Constructed URL in configureView: %@", mUrl.absoluteString);
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:mUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    //Load the request in the UIWebView.
    [fWebView loadRequest:requestObj];
}

-(void)showPopupView{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        if (fIsPopupVisible)
            return;
        //else je zbytek kódu
        
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
    if ([request.URL.absoluteString rangeOfString:@"ConsumptionMeterDetail" options:NSCaseInsensitiveSearch].location == NSNotFound && [request.URL.absoluteString rangeOfString:@"OnOffCameraDetail" options:NSCaseInsensitiveSearch].location == NSNotFound  )
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && fDetailViewController.modalPresentationStyle == UIModalPresentationFormSheet) {
        [self presentViewController:fDetailViewController animated:NO completion:handler];

    }
    else
        [self presentViewController:fDetailViewController animated:NO completion:nil];
}

#pragma mark - WebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Chyba při načítání: %@", error);
    
    // Ignore NSURLErrorDomain error -999.
    if (error.code == NSURLErrorCancelled) return;
    
    // Ignore "Fame Load Interrupted" errors. Seen after app store links.
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) return;
    
    // Normal error handling…
    UIAlertView *allert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server url", @"") message:NSLocalizedString(@"Bad connect", @"Nepodařilo se připojit") delegate:self cancelButtonTitle:NSLocalizedString(@"Button Home", @"") 
        otherButtonTitles:NSLocalizedString(@"Button Remotely", @""), NSLocalizedString(@"Button Cancel", nil), nil ];
    [allert show];
    NSLog(NSLocalizedString(@"Button Remotely", @""));
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType
{
    //jako první otestujeme, zda nejde o touch událost
    if ( [[[aRequest URL] absoluteString] hasPrefix:@"touch:"] ) {
        //.. parse arguments
        [self hidePopupView];
        return NO;
    }
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [self showDetailView:aRequest];
        return NO;
    }
    
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

- (void)webViewDidFinishLoad:(UIWebView *)webViewLocal
{
    [fWaitingViewController stopWaiting];
    
    //nejprve ze stránky odebereme defaultní navigaci
    NSString *jsCommand = [NSString stringWithFormat:@"removeNavFloors();"];
    [webViewLocal stringByEvaluatingJavaScriptFromString:jsCommand];
    
    //následně do stránky přidáme javascript hlídající touch gesta
    //je potřeba, abychom mohli eventuelně schovat popupview
    jsCommand = [NSString stringWithFormat:@"document.addEventListener('touchstart', function(event) { window.location.replace('touch://www.haidy.cz'); }, false);"];
    [webViewLocal stringByEvaluatingJavaScriptFromString:jsCommand];

}
     
#pragma mark - UIAllertViewDelegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0)
    {
        NSLog(@"Potvrzeno jsem doma");
        [ExUtils setInHome:YES];
    }
    else if (buttonIndex == 1)
    {
        NSLog(@"Nastaveno jsem vzdáleně");
        [ExUtils setInHome:NO];
    }
    else 
        return;
    
    [self configureView:YES];
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
-(void) detailViewControllerDidFinish:(id)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Implement PopupViewControllerDelegate
-(void) selectWebPage:(NSString *)aPage{

    NSURL *mUrl = [ExUtils constructUrlFromPage:aPage];
    
    NSLog(@"Constructed URL in selectWebPage: %@", mUrl.absoluteString);
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:mUrl];
    //Load the request in the UIWebView.
    [fWebView loadRequest:requestObj];
}

@end
