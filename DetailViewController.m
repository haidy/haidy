//
//  SubWebViewController.m
//  Haidy House
//
//  Created by Jan Koranda on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "ExUtils.h"
#import "WaitingViewController.h"

@interface DetailViewController ()
{
    WaitingViewController* fWaitingViewController;
}
@end

@implementation DetailViewController

@synthesize fWebView, delegate, navigationItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Detail aktivního prvku", @"Popisek pro detail aktivního prvku");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ///Inicializace waiting dialogu
    fWaitingViewController = [WaitingViewController createWithParentView:self.view];
    
    //potlačení scrolování, nechceme na tomto detailu vidět efekt scrolování.
    //detail stránky by měl být plovoucí, aby se vešel vždy
    [fWebView.scrollView setScrollEnabled:NO];
    [fWebView loadRequest:[NSURLRequest requestWithURL:[ExUtils blankPage]]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (UIDeviceOrientationIsLandscape(interfaceOrientation))
            return YES;
        else
            return NO;
    }
    else
        return YES;
}

- (void) loadPage:(NSURLRequest*)urlRequest{
    //vytvoříme nový request, abychom mohli zajistit, že nebude dotaz vykonaný pomocí cache
    [fWebView loadRequest:[NSURLRequest requestWithURL:urlRequest.URL  cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0]];
    //[fWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.40.91/HaidySmartClient/Temp/ManualBinaryDevice2.html"]]];
}

-(void) backButtonClicked:(id)sender
{
    [fWebView loadRequest:[NSURLRequest requestWithURL:[ExUtils blankPage]]];
    [delegate detailViewControllerDidFinish:self andError:NO];
}

#pragma mark - WebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView *allert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server url", @"") message:NSLocalizedString(@"Bad connect", @"Nepodařilo se připojit") delegate:self cancelButtonTitle:NSLocalizedString(@"Button Home", @"")
                                           otherButtonTitles:NSLocalizedString(@"Button Remotely", @""), NSLocalizedString(@"Button Cancel", nil), nil ];
    [allert show];
    NSLog(NSLocalizedString(@"Button Remotely", @""));
}

- (void)webViewDidFinishLoad:(UIWebView *)webViewLocal
{    
    NSString *isMobileScroll = [webViewLocal stringByEvaluatingJavaScriptFromString:@"isMobileScroll();"];
    NSLog(@"Mobile Scroll: %@", isMobileScroll);
    if ([isMobileScroll isEqualToString:@"true"])
        [self.fWebView.scrollView setScrollEnabled:YES];
    else
        [self.fWebView.scrollView setScrollEnabled:NO];
    
    NSString *mTitle = [webViewLocal stringByEvaluatingJavaScriptFromString:@"getTitle()"];
    [navigationItem setTitle:mTitle];
    if ([mTitle rangeOfString:@"Error" options:NSCaseInsensitiveSearch].location == NSNotFound )
        fLoadedErrorPage = NO;
    else
        fLoadedErrorPage = YES;
    
    [fWaitingViewController stopWaiting];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType{
    
    //pokud je načtená Error stránka, tak request neotevřeme a pošleme info hlavnímu detailu
    if (fLoadedErrorPage == YES)
    {
        fLoadedErrorPage = NO;
        [fWebView loadRequest:[NSURLRequest requestWithURL:[ExUtils blankPage]]];
        [delegate detailViewControllerDidFinish:self andError:YES];
        return NO;
    }
    //else není potřeba, vše je v pořádku
    
    
    //otestujeme, zda nejde o požadavek události na zavření detailu
    if ( [[[aRequest URL] absoluteString] hasPrefix:@"close:"] ) {
        //.. parse arguments
        [self backButtonClicked:webView];
        return NO;
    }
    
    //do všech requestů potřebujeme přidat povinné cokies
    [ExUtils setRequiredCookies:aRequest];

    [fWaitingViewController startWaiting];
    
    return YES;
}



@end
