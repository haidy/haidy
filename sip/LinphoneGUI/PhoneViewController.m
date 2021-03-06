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

#import "PhoneViewController.h"
#import "IncallViewController.h"
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import "LinphoneManager.h"
#include "FirstLoginViewController.h"
#include "VideoPreviewController.h"
#include "linphonecore.h"
#include "private.h"
#include "WebViewController.h"
#include "ContactTableViewController.h"
#include "ExUtils.h"
#include "JsonService.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@implementation PhoneViewController
@synthesize  dialerView ;
@synthesize  address, imageView ;
@synthesize  callShort;
@synthesize  callLarge;
@synthesize status;
@synthesize erase;
@synthesize scenes;

@synthesize statusViewHolder;

//Zakomentováno do doby, dokud nebudeme chtít zase používat TabBarController
//@synthesize myTabBarController;
@synthesize fVideoPreviewController, fViewForContact, fContacTableViewController;
@synthesize backToCallView;
@synthesize switchCamera;

-(void) updateStatusSubView {
    LinphoneCore* lc = 0;
    @try {
        lc = [LinphoneManager getLc];
    } @catch (NSException* exc) {
        return;
    }
    
    if (!lc)
        return;
    
    BOOL enableCallButtons;
    LinphoneProxyConfig* config;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    
    LinphoneRegistrationState mRegistrationState;
    NSString* m = nil;
    
    if (config == NULL) {
        mRegistrationState = LinphoneRegistrationNone;
        m = linphone_core_is_network_reachable([LinphoneManager getLc]) ? NSLocalizedString(@"No SIP account configured", nil) : NSLocalizedString(@"Network down", nil);
    } else {
        mRegistrationState = linphone_proxy_config_get_state(config);
    
        switch (mRegistrationState) {
            case LinphoneRegistrationOk: m =  NSLocalizedString(@"Registered", nil); break;
            case LinphoneRegistrationNone: 
			case LinphoneRegistrationCleared:
				m= NSLocalizedString(@"Not registered", nil); break;
            case LinphoneRegistrationFailed: m = NSLocalizedString(@"Registration failed", nil); break;
            case LinphoneRegistrationProgress: m = @"Registration in progress"; break;
            //case LinphoneRegistrationCleared: m= @"No SIP account"; break;
            default: break;
        }
    }
    
    enableCallButtons = [statusSubViewController updateWithRegistrationState:mRegistrationState message:m];
    
    [callLarge setEnabled:enableCallButtons];
    [callShort setEnabled:enableCallButtons];   
    [backToCallView setEnabled:enableCallButtons];
}

-(void) updateCallAndBackButtons {
    @try {
        bool zeroCall = (linphone_core_get_calls_nb([LinphoneManager getLc]) == 0);
        
        [LinphoneManager set:callLarge hidden:!zeroCall withName:"CALL_LARGE button" andReason:__FUNCTION__];
        [LinphoneManager set:switchCamera hidden:!zeroCall withName:"SWITCH_CAM button" andReason:__FUNCTION__];
        [LinphoneManager set:callShort hidden:zeroCall withName:"CALL_SHORT button" andReason:__FUNCTION__];
        [LinphoneManager set:backToCallView hidden:zeroCall withName:"BACK button" andReason:__FUNCTION__];
        
        if (zeroCall)
            [address setPlaceholder:NSLocalizedString(@"Call number", nil)];
        else
            if ([UICallButton transforModeEnabled])
            {
                [address setPlaceholder:NSLocalizedString(@"Transfer call", nil)];
                [callShort setImage:fCallTransferImage forState:UIControlStateNormal];
            }
            else
            {
                [address setPlaceholder:NSLocalizedString(@"Add call", nil)];
                [callShort setImage:fCallAddImage forState:UIControlStateNormal];
            }
        
        if (!callShort.hidden)
            [callShort setEnabled:!linphone_core_sound_resources_locked([LinphoneManager getLc])];
    } @catch (NSException* exc) {
        // R.A.S: linphone core si simply not ready...
        ms_warning("Catched exception %s: %s", 
                   [exc.name cStringUsingEncoding:[NSString defaultCStringEncoding]], 
                   [exc.reason cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    
    [self updateStatusSubView];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable_first_login_view_preference"] == true) {
		fFirstLoginViewController = [[FirstLoginViewController alloc]  initWithNibName:@"FirstLoginViewController" 
																				 bundle:[NSBundle mainBundle]];
		[self presentViewController:fFirstLoginViewController animated:true completion:nil];
	}
    [[LinphoneManager instance] setRegistrationDelegate:self];
    [[LinphoneManager instance] setContactDelegate:fContacTableViewController];
    [[LinphoneManager instance] setActionDelefate:self];
    
    [fVideoPreviewController showPreview:YES];
    [self updateCallAndBackButtons];
    [self loadScenesButtons];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib : may be called twice
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //oříznutí pozadí o okraje pro iPhone
    if (![ExUtils runningOnIpad])
    {
        UIImage *mResourceImage = [UIImage imageNamed:@"Background.png"];
        CGRect mRect = CGRectMake(15, 15, mResourceImage.size.width-30, mResourceImage.size.height-30);
        CGImageRef mCroptedImage = CGImageCreateWithImageInRect([mResourceImage CGImage], mRect);

        imageView.image= [UIImage imageWithCGImage:mCroptedImage];
        CGImageRelease(mCroptedImage);
    }
    
    fCallAddImage = [UIImage imageNamed:@"StartCallAddHighlight.png"];
    fCallTransferImage = [UIImage imageNamed:@"TransferCallHighlight.png"];
    
    [self setTitle:NSLocalizedString(@"SIP", @"Popisek sipu")];
    
	[callShort initWithAddress:address];
	[callLarge initWithAddress:address];
	[erase initWithAddressField:address];
    [backToCallView addTarget:self action:@selector(backToCallViewPressed) forControlEvents:UIControlEventTouchUpInside];
    [scenes addTarget:self action:@selector(displayScenes) forControlEvents:UIControlEventTouchUpInside];
    
    [fContacTableViewController setAdressField:address];
    
    if (mIncallViewController == NULL)
        mIncallViewController = [[IncallViewController alloc]  initWithNibName:[LinphoneManager runningOnIpad]?@"InCallViewController-ipad":@"IncallViewController" 
																	bundle:[NSBundle mainBundle]];
    
    if (statusSubViewController == NULL) {
        statusSubViewController = [[StatusSubViewController alloc]  initWithNibName:@"StatusSubViewController" 
                                                                         bundle:[NSBundle mainBundle]];
        [statusViewHolder addSubview:statusSubViewController.view];
    }
    
    [self updateCallAndBackButtons];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == address) {
        [address resignFirstResponder];
		[callLarge touchUp:callLarge];
    } 
    return YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [self updateCallAndBackButtons];
    [self.fContacTableViewController viewWillAppear:animated];
    [super viewWillAppear:animated];
}

-(void) backToCallViewPressed {
    [UICallButton enableTransforMode:NO];
    [self presentViewController:(UIViewController*)mIncallViewController animated:true completion:nil];
    
    LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
    
    if (!call || !linphone_call_params_video_enabled(linphone_call_get_current_params(call)) || linphone_call_get_state(call) != LinphoneCallStreamsRunning) {
        [self	displayInCall: call
                     FromUI:nil
                    forUser:nil
            withDisplayName:nil];
    } else {
        [self displayVideoCall:call FromUI:nil forUser:nil withDisplayName:nil];
    }
}

#pragma mark - Implementation LinphoneUICallDelegate

-(void) displayDialer:(UIViewController*) viewCtrl {	
    [self updateCallAndBackButtons];
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstlogindone_preference" ] == true) {
		//first login case, dismmis first login view
		[self dismissViewControllerAnimated:true completion:nil];
	};
    
	[mIncallViewController displayDialer:viewCtrl];
    [fVideoPreviewController showPreview:YES];
}

-(void) callEnd:(UIViewController *)viewCtrl
{
	if (fIncomingCallActionSheet) {
			[fIncomingCallActionSheet dismissWithClickedButtonIndex:1 animated:true];
			fIncomingCallActionSheet=nil;
    }
    
    [self updateCallAndBackButtons];
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstlogindone_preference" ] == true) {
		//first login case, dismmis first login view
		[self dismissViewControllerAnimated:true completion:nil];
	};
    
	[mIncallViewController callEnd:viewCtrl];
    [fVideoPreviewController showPreview:YES];
}

-(void) displayIncomingCall:(LinphoneCall*) call NotificationFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {

	[fVideoPreviewController showPreview:NO];
    fCallDelegate = nil;
    fCallDelegate = [[CallDelegate alloc] init];
    fCallDelegate.eventType = CD_NEW_CALL;
    fCallDelegate.delegate = self;
    fCallDelegate.call = call;
    
    fIncomingCallActionSheet = [[UIActionSheet alloc] initWithTitle:[NSString  stringWithFormat:NSLocalizedString(@" %@ is calling you",nil),[displayName length]>0?displayName:username]
                                                           delegate:fCallDelegate 
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"Answer",nil),NSLocalizedString(@"Decline",nil), NSLocalizedString(@"Decline all",nil),nil];
    
    fIncomingCallActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    
    if ([LinphoneManager runningOnIpad]) {
        if (self.presentedViewController != nil)
            [fIncomingCallActionSheet showInView:[self.presentedViewController view]];
        else
            [fIncomingCallActionSheet showInView:self.parentViewController.view];
    } else {
        [fIncomingCallActionSheet showInView:self.parentViewController.view];
    }
}

-(void) displayCall: (LinphoneCall*) call InProgressFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [fVideoPreviewController showPreview:NO]; 
	if (self.presentedViewController != (UIViewController*)mIncallViewController) {
		[self presentViewController:(UIViewController*)mIncallViewController animated:true completion:nil];
	}
	[mIncallViewController displayCall:call InProgressFromUI:viewCtrl
							   forUser:username
					   withDisplayName:displayName];
    
    [fVideoPreviewController showPreview:NO];
	
}

-(void) displayInCall: (LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [fVideoPreviewController showPreview:NO]; 
    if (self.presentedViewController != (UIViewController*)mIncallViewController /*&& (call == 0x0 ||
																  linphone_call_get_dir(call)==LinphoneCallIncoming)*/){
		[self presentViewController:(UIViewController*)mIncallViewController animated:true completion:nil];
		
	}
    
	[mIncallViewController displayInCall:call FromUI:viewCtrl
								 forUser:username
						 withDisplayName:displayName];
    
    [LinphoneManager set:callLarge hidden:YES withName:"CALL_LARGE button" andReason:__FUNCTION__];
    [LinphoneManager set:switchCamera hidden:YES withName:"SWITCH_CAMERA button" andReason:__FUNCTION__];
    [LinphoneManager set:callShort hidden:NO withName:"CALL_SHORT button" andReason:__FUNCTION__];
    [LinphoneManager set:backToCallView hidden:NO withName:"CALL_BACK button" andReason:__FUNCTION__];
    
    [self updateCallAndBackButtons];
} 


-(void) displayVideoCall:(LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName { 
    [fVideoPreviewController showPreview:NO]; 
	[mIncallViewController  displayVideoCall:call FromUI:viewCtrl 
									 forUser:username 
							 withDisplayName:displayName];
    
    [fVideoPreviewController showPreview:NO];
    [self updateCallAndBackButtons];
}


//status reporting
-(void) displayAskToEnableVideoCall:(LinphoneCall*) call forUser:(NSString*) username withDisplayName:(NSString*) displayName {
	[mIncallViewController  displayAskToEnableVideoCall:call forUser:username withDisplayName:displayName];
}
-(void) firstVideoFrameDecoded: (LinphoneCall*) call {
    [mIncallViewController firstVideoFrameDecoded:call];
}

#pragma mark - Implementation UIActionSheetCustomDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet ofType:(enum CallDelegateType)type clickedButtonAtIndex:(NSInteger)buttonIndex withUserDatas:(void *)datas {
    if (type != CD_NEW_CALL)
        return;
    
    LinphoneCall* call = (LinphoneCall*)datas;
	if (buttonIndex == 0 ) {
		linphone_core_accept_call([LinphoneManager getLc],call);
	} else if (buttonIndex == 1) {
        linphone_core_terminate_call ([LinphoneManager getLc], call);
	}
    else
    {
        linphone_core_accept_call([LinphoneManager getLc],call);
		linphone_core_terminate_call ([LinphoneManager getLc], call);
	}

    
	fIncomingCallActionSheet = nil;
}

#pragma mark - Implementation LinphoneUIRegistrationDelegate

-(void) displayRegisteredFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName onDomain:(NSString*)domain {    
    if (fFirstLoginViewController != nil && self.presentedViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayRegisteredFromUI:viewCtrl forUser:username withDisplayName:displayName onDomain:domain];
    }
    [self updateStatusSubView];
}
-(void) displayRegisteringFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName onDomain:(NSString*)domain {
    if (fFirstLoginViewController != nil && self.presentedViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayRegisteringFromUI:viewCtrl forUser:username withDisplayName:displayName onDomain:domain];
    }
    [self updateStatusSubView];
}
-(void) displayRegistrationFailedFromUI:(UIViewController*) viewCtrl forUser:(NSString*) user withDisplayName:(NSString*) displayName onDomain:(NSString*)domain forReason:(NSString*) reason {
    if (fFirstLoginViewController != nil && self.presentedViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayRegistrationFailedFromUI:viewCtrl forUser:user withDisplayName:displayName onDomain:domain forReason:reason];
    }
    [self updateStatusSubView];
}

-(void) displayNotRegisteredFromUI:(UIViewController*) viewCtrl { 
    if (fFirstLoginViewController != nil && self.presentedViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayNotRegisteredFromUI:viewCtrl];
    }
    [self updateStatusSubView];
}

#pragma mark - Implementation LinphoneUIActionDelegate and UIActionSheetDetelegate
-(void) displayScenes{
    UIActionSheet *mActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Scenes" ,nil) delegate:self cancelButtonTitle:nil  destructiveButtonTitle:nil otherButtonTitles: nil];
    
    for (NSDictionary *mScene in fScenesButtons) {
        [mActionSheet addButtonWithTitle:[mScene valueForKey:@"DisplayName"]];
        NSLog(@"Duration: %@", [mScene valueForKey:@"SceneActivityDuration"]);
    }
    
    [mActionSheet setCancelButtonIndex:[mActionSheet addButtonWithTitle:NSLocalizedString(@"Close", nil)]];
    
    [mActionSheet setActionSheetStyle:UIActionSheetStyleDefault];
    [mActionSheet showInView:self.navigationController.visibleViewController.view ];
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex || buttonIndex < 0)
        return;
    else
    {
        NSDictionary *mButton = [fScenesButtons objectAtIndex:buttonIndex];
        //asynchronně odešleme data a neřešíme
        dispatch_async(kBgQueue, ^{
            //tato metoda nevrací žádná data, klidně můžeme zavolat a dotaz se odešle :).
            [JsonService activateSipSceneWithButton:mButton];
        });
    }
}

- (void)loadScenesButtons{
    dispatch_async(kBgQueue, ^{
        fScenesButtons = [JsonService getSipScenesButtons];
    });
}

@end
