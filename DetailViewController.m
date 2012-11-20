//
//  DetailViewController.m
//  Haidy House
//
//  Created by Jan Koranda on 6/18/12.
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

#import "DetailViewController.h"
#import "ExUtils.h"
#import "WaitingViewController.h"

@interface DetailViewController ()
{
    WaitingViewController* fWaitingViewController;
}
- (void)closeDetailWithError:(NSNumber*)aError;

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
    [fWebView loadRequest:[NSURLRequest requestWithURL:urlRequest.URL  cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1.0]];
}

//Metoda zajistí zavření detailu, a předá informaci o tom, zda došlo k chybě
//aError: indentifikuje, zda došlo k chybě. Aby bylo možné informaci předat přes performselector withDelay, je nutné, aby byl BOOL převeden na NSNumber a zde zpět.
-(void)closeDetailWithError:(NSNumber*)aError
{
    [fWebView loadRequest:[NSURLRequest requestWithURL:[ExUtils blankPage]]];
    [delegate detailViewControllerDidFinish:self andError:[aError boolValue]];
}

#pragma mark - WebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // Ignore NSURLErrorDomain error -999.
    if (error.code == NSURLErrorCancelled) return;
    
    // Ignore "Fame Load Interrupted" errors. Seen after app store links.
    // Remarks: Nastane i v případě, že se stane redirect stránky, třeba z důvodu jiné velikosti písma v názvu url např. /HaidySmartClient/ a /HAIdySmartClient
    else if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]){
        [ExUtils handlingErrorCode102WithWebKitErrorDomain:webView.request.URL.absoluteString];
        return;
    }
    //else: není potřeba, jde o zbytek kódu
    [fWaitingViewController stopWaiting];
    [self closeDetailWithError:[NSNumber numberWithBool:NO]];
    
    UIAlertView *allert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server url", @"") message:NSLocalizedString(@"Bad connect", @"Nepodařilo se připojit") delegate:self cancelButtonTitle:NSLocalizedString(@"Button Home", @"")
                                           otherButtonTitles:NSLocalizedString(@"Button Remotely", @""), NSLocalizedString(@"Button Cancel", nil), nil ];
    [allert show];
    
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
    NSLog(@"Title: %@", mTitle);
    if ([mTitle caseInsensitiveCompare:@"Error"] == NSOrderedSame )
        [self performSelector:@selector(closeDetailWithError:) withObject:[NSNumber numberWithBool:YES] afterDelay:3.0];
    else if ([mTitle caseInsensitiveCompare:@"Server Connecting"] == NSOrderedSame )
        [self performSelector:@selector(closeDetailWithError:) withObject:[NSNumber numberWithBool:NO] afterDelay:3.0];
    //else - vše je v pořádku, nic se neděje
        
    
    [fWaitingViewController stopWaiting];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType{
        
    //otestujeme, zda nejde o požadavek události na zavření detailu
    if ( [[[aRequest URL] absoluteString] hasPrefix:@"close:"] ) {
        //.. parse arguments
        [self closeDetailWithError:[NSNumber numberWithBool:NO]];
        return NO;
    }
    
    //do všech requestů potřebujeme přidat povinné cokies
    [ExUtils setRequiredCookies:aRequest];

    [fWaitingViewController startWaiting];
    
    return YES;
}



@end
