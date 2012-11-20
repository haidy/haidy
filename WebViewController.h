//
//  FirstViewController.h
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
