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
#import "PhoneViewController.h"

#define DIALER_TAB_INDEX 1

@interface WebViewController : UIViewController<UIWebViewDelegate, UIAlertViewDelegate, DetailViewControllerDelegate, PopupViewControllerDelegate, LinphoneUICallDelegate >
{
    DetailViewController *fDetailViewController;
    PopupViewController *fPopupViewController;

    UIView *fPopupView;
    //Zda je zobrazený popupview
    BOOL fIsPopupVisible;
    //Zda je zobrazený SIP kvůli příchozímu hovoru, ale okno se sipem, ještě nebylo zobrazen
    BOOL fIsVisibleSipForIncommingCall;
    @private BOOL fLoadedErrorPage;
    @private PhoneViewController *fPhoneViewController;
}

@property (strong, nonatomic) IBOutlet UIWebView *fWebView;
@property (strong, nonatomic) IBOutlet UIImageView *fImageView;
@property (retain, nonatomic, readonly) PhoneViewController *fPhoneViewController;

- (IBAction) handleSwipeRight:(UISwipeGestureRecognizer*)sender;
- (IBAction) handleSwipeLeft:(UISwipeGestureRecognizer*)sender;

- (void) showPopupView;
- (void) hidePopupView;
- (void) showDetailView:(NSURLRequest*)request;

@end
