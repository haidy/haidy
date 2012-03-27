//
//  FirstViewController.m
//  Haidy House
//
//  Created by Jan Koranda on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController()
- (void)configureView:(BOOL)reload;    
@end

@implementation WebViewController

@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"House", @"House");
        //self.tabBarItem.image = [UIImage imageNamed:@"first"];
        jsemDoma = [[NSUserDefaults standardUserDefaults] valueForKey:@"ImHome"];
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
    webView.delegate = self;
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
    [self configureView:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
        
- (void) configureView:(BOOL)reload
{
    //pokud máme nastavený URL request, tak nic neděláme
    if (webView.request != nil && reload == NO)
        return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = nil;
    NSNumber *secure = nil;
    
    if ([jsemDoma boolValue] == YES)
    {
        NSLog(@"Loaded URL: %@", [defaults valueForKey:@"HomeUrl"]);
        url = [defaults stringForKey:@"HomeUrl"];
        secure = [defaults valueForKey:@"HomeSecure"];
    }
    else
    {
        url = [defaults stringForKey:@"RemotelyUrl"];
        secure = [defaults valueForKey:@"RemotelySecure"];
    }
    
    if ([url rangeOfString:@"http://"].location == NSNotFound && [secure boolValue] == NO)
        url = [NSString stringWithFormat:@"http://%@/HAIdySmartClient/", url];
    else if ([url rangeOfString:@"https://"].location == NSNotFound && [secure boolValue] == YES)
        url = [NSString stringWithFormat:@"https://%@/HAIdySmartClient/", url];
    
    //Create a URL object.
    NSURL *nsUrl = [NSURL URLWithString:url];
    if (nsUrl == nil)
    {
        UIAlertView *allert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server url", nil) message:NSLocalizedString(@"Bad URL", @"Asi špatný url.") delegate:nil cancelButtonTitle:NSLocalizedString(@"Button Close", nil) otherButtonTitles:nil, nil ];
        [allert show];
         return;
    }
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:nsUrl];
    //Load the request in the UIWebView.
    [webView loadRequest:requestObj];    
}

#pragma mark - WebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView *allert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Server url", @"") message:NSLocalizedString(@"Bad connect", @"Nepodařilo se připojit") delegate:self cancelButtonTitle:NSLocalizedString(@"Button Home", @"") 
        otherButtonTitles:NSLocalizedString(@"Button Remotely", @""), NSLocalizedString(@"Button Cancel", nil), nil ];
    [allert show];
    NSLog(NSLocalizedString(@"Button Remotely", @""));
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
}
     
#pragma mark - UIAllertViewDelegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0)
    {
        NSLog(@"Potvrzeno jsem doma");
        jsemDoma = [NSNumber numberWithBool:YES];
    }
    else if (buttonIndex == 1)
    {
        NSLog(@"Nastaveno jsem vzdáleně");
        jsemDoma = [NSNumber numberWithBool:NO];
    }
    else 
        return;
    
    [self configureView:YES];
}
@end
