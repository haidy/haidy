//
//  FirstViewController.h
//  Haidy House
//
//  Created by Jan Koranda on 3/27/12.
//  Copyright (c) 2012 __Haidy a.s.__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewController.h"
#import "PopupViewController.h"

@interface WebViewController : UIViewController<UIWebViewDelegate, UIAlertViewDelegate, DetailViewControllerDelegate, PopupViewControllerDelegate>
{
    DetailViewController *fDetailViewController;
    PopupViewController *fPopupViewController;
    UIView *fPopupView;
    BOOL fIsPopupVisible;
    @private BOOL fLoadedErrorPage;
}

@property (strong, nonatomic) IBOutlet UIWebView *fWebView;
@property (strong, nonatomic) IBOutlet UIImageView *fImageView;

- (IBAction) handleSwipeRight:(UISwipeGestureRecognizer*)sender;
- (IBAction) handleSwipeLeft:(UISwipeGestureRecognizer*)sender;

- (void) showPopupView;
- (void) hidePopupView;
- (void) showDetailView:(NSURLRequest*)request;

@end
