/* PhoneViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
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
#import <Foundation/Foundation.h>
#import "linphonecore.h"
#import "UILinphone.h"
#import "CallDelegate.h"
#import "StatusSubViewController.h"

@class ContactTableViewController;
@class VideoPreviewController;
@class IncallViewController;
@class FirstLoginViewController;


@interface PhoneViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, LinphoneUICallDelegate, UIActionSheetCustomDelegate, LinphoneUIRegistrationDelegate, LinphoneUIActionDelegate > {

@private
	//UI definition
	UIView* dialerView;
	UITextField* address;
	UILabel* mDisplayName;
	UIEraseButton* erase;
	UICallButton* callShort;
	UICallButton* callLarge;
	UIButton* scenes;
	UILabel* status;

	UIButton* backToCallView;
    UIView* statusViewHolder;
    UIImageView* imageView;
	
    //Zakomentováno do doby, dokud nebudeme chtít zase používat TabBarController
	//UITabBarController*  myTabBarController;
    
    //ActionSheet si držíme, protože může přijít od volajícího informace o položení hovoru. V takovém případě je potřeba ActionSheet zavřít.
	UIActionSheet *fIncomingCallActionSheet;
    //CallDelegate si držíme protože ARC ho jinak releasne. Předání CallDelegáta do ActionSheetu neudělá release :/. Property delegate je jen assign.
    CallDelegate* fCallDelegate;
    
	FirstLoginViewController* fFirstLoginViewController;
	IncallViewController* mIncallViewController;

    VideoPreviewController* fVideoPreviewController;
    StatusSubViewController* statusSubViewController;
    UIView* fViewForContact;
    ContactTableViewController* fContacTableViewController;
    
    UIButton* switchCamera;
    
    NSArray *fScenesButtons;
    UIImage *fCallAddImage;
    UIImage *fCallTransferImage;
}

@property (nonatomic, retain) IBOutlet UIView* dialerView;
@property (nonatomic, retain) IBOutlet UIImageView* imageView;
@property (nonatomic, retain) IBOutlet UITextField* address;
@property (nonatomic, retain) IBOutlet UIButton* callShort;
@property (nonatomic, retain) IBOutlet UIButton* callLarge;
@property (nonatomic, retain) IBOutlet UIButton* scenes;
@property (nonatomic, retain) IBOutlet UILabel* status;
@property (nonatomic, retain) IBOutlet UIEraseButton* erase;
@property (nonatomic, retain) IBOutlet UIView* statusViewHolder;
@property (nonatomic, retain) IBOutlet UIButton* backToCallView;
@property (nonatomic, retain) IBOutlet UIButton* switchCamera;
//Zakomentováno do doby, dokud nebudeme chtít zase používat TabBarController
//@property (nonatomic, retain) IBOutlet UITabBarController*  myTabBarController;
@property (nonatomic, retain) IBOutlet VideoPreviewController*  fVideoPreviewController;
@property (nonatomic, retain) IBOutlet UIView* fViewForContact;
@property (nonatomic, retain) IBOutlet ContactTableViewController* fContacTableViewController;
@end
