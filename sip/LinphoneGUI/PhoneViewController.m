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

@implementation PhoneViewController
@synthesize  dialerView ;
@synthesize  address ;
@synthesize  callShort;
@synthesize  callLarge;
@synthesize status;
@synthesize erase;

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
    
    LinphoneRegistrationState s;
    NSString* m = nil;
    
    if (config == NULL) {
        s = LinphoneRegistrationNone;
        m = linphone_core_is_network_reachabled([LinphoneManager getLc]) ? NSLocalizedString(@"No SIP account configured", nil) : NSLocalizedString(@"Network down", nil);
    } else {
        s = linphone_proxy_config_get_state(config);
    
        switch (s) {
            case LinphoneRegistrationOk: m = @"Registered"; break;
            case LinphoneRegistrationNone: 
			case LinphoneRegistrationCleared:
				m=@"Not registered"; break;
            case LinphoneRegistrationFailed: m = @"Registration failed"; break;
            case LinphoneRegistrationProgress: m = @"Registration in progress"; break;
            //case LinphoneRegistrationCleared: m= @"No SIP account"; break;
            default: break;
        }
    }
    
    enableCallButtons = [statusSubViewController updateWithRegistrationState:s message:m];
    
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
        
        [callShort setTitle:[UICallButton transforModeEnabled] ? @"transfer":@"call" forState:UIControlStateNormal];
        
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
		[self presentModalViewController:fFirstLoginViewController animated:true];
	}
    [[LinphoneManager instance] setRegistrationDelegate:self];
    
    [fVideoPreviewController showPreview:YES];
    [self updateCallAndBackButtons];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib : may be called twice
- (void)viewDidLoad {
    [super viewDidLoad];
        
	mDisplayName = [UILabel alloc];
	[callShort initWithAddress:address];
	[callLarge initWithAddress:address];
	[erase initWithAddressField:address];
    [backToCallView addTarget:self action:@selector(backToCallViewPressed) forControlEvents:UIControlEventTouchUpInside];
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
		[mDisplayName setText:@""]; //display name only relefvant 
		
    } 
    return YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [self updateCallAndBackButtons];
    [super viewWillAppear:animated];
}

-(void) backToCallViewPressed {
    [UICallButton enableTransforMode:NO];
    [self presentModalViewController:(UIViewController*)mIncallViewController animated:true];
    
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

-(void) displayDialerFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
	
	//cancel local notification, just in case
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground ) {
		// cancel local notif if needed
		[[UIApplication sharedApplication] cancelAllLocalNotifications];
	} else {
		if (fIncomingCallActionSheet) {
			[fIncomingCallActionSheet dismissWithClickedButtonIndex:1 animated:true];
			fIncomingCallActionSheet=nil;
		}
	}
	
	if (username) {
		[address setText:username];
	} //else keep previous
	
	[mDisplayName setText:displayName];
    
    [self updateCallAndBackButtons];
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstlogindone_preference" ] == true) {
		//first login case, dismmis first login view
		[self dismissModalViewControllerAnimated:true];
	};
	[mIncallViewController displayDialerFromUI:viewCtrl
									   forUser:username
							   withDisplayName:displayName];
	
    //Zakomentováno do doby, dokud nebudeme zase chtít používat tabBarController
	//[myTabBarController setSelectedIndex:DIALER_TAB_INDEX];
    
    [fVideoPreviewController showPreview:YES];
}

-(void) displayIncomingCall:(LinphoneCall*) call NotificationFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
	[fVideoPreviewController showPreview:NO]; 
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] 
		&& [UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
		// Create a new notification
		UILocalNotification* notif = [[UILocalNotification alloc] init];
		if (notif)
		{
			notif.repeatInterval = 0;
			notif.alertBody =[NSString  stringWithFormat:NSLocalizedString(@" %@ is calling you",nil),[displayName length]>0?displayName:username];
			notif.alertAction = @"Answer";
			notif.soundName = @"oldphone-mono-30s.caf";
            NSData *callData = [NSData dataWithBytes:&call length:sizeof(call)];
			notif.userInfo = [NSDictionary dictionaryWithObject:callData forKey:@"call"];
			
			[[UIApplication sharedApplication]  presentLocalNotificationNow:notif];
		}
	} else 	{
        fCallDelegate = nil;
        fCallDelegate = [[CallDelegate alloc] init];
        fCallDelegate.eventType = CD_NEW_CALL;
        fCallDelegate.delegate = self;
        fCallDelegate.call = call;
        
		fIncomingCallActionSheet = [[UIActionSheet alloc] initWithTitle:[NSString  stringWithFormat:NSLocalizedString(@" %@ is calling you",nil),[displayName length]>0?displayName:username]
															   delegate:fCallDelegate 
													  cancelButtonTitle:nil 
												 destructiveButtonTitle:NSLocalizedString(@"Answer",nil) 
													  otherButtonTitles:NSLocalizedString(@"Decline",nil),nil];
        
		fIncomingCallActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        if ([LinphoneManager runningOnIpad]) {
            if (self.modalViewController != nil)
                [fIncomingCallActionSheet showInView:[self.modalViewController view]];
            else
                [fIncomingCallActionSheet showInView:self.parentViewController.view];
        } else {
            [fIncomingCallActionSheet showInView:self.parentViewController.view];
        }
    }
	
    [fVideoPreviewController showPreview:NO];
}

-(void) displayCall: (LinphoneCall*) call InProgressFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [fVideoPreviewController showPreview:NO]; 
	if (self.presentedViewController != (UIViewController*)mIncallViewController) {
		[self presentModalViewController:(UIViewController*)mIncallViewController animated:true];
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
		[self presentModalViewController:(UIViewController*)mIncallViewController animated:true];
		
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
-(void) displayStatus:(NSString*) message {
	[mIncallViewController displayStatus:message];
}

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
	if (buttonIndex == actionSheet.destructiveButtonIndex ) {
		linphone_core_accept_call([LinphoneManager getLc],call);	
	} else {
		linphone_core_terminate_call ([LinphoneManager getLc], call);
	}
	fIncomingCallActionSheet = nil;
}

#pragma mark - Implementation LinphoneUIRegistrationDelegate

-(void) displayRegisteredFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName onDomain:(NSString*)domain {    
    if (fFirstLoginViewController != nil && self.modalViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayRegisteredFromUI:viewCtrl forUser:username withDisplayName:displayName onDomain:domain];
    }
    [self updateStatusSubView];
}
-(void) displayRegisteringFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName onDomain:(NSString*)domain {
    if (fFirstLoginViewController != nil && self.modalViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayRegisteringFromUI:viewCtrl forUser:username withDisplayName:displayName onDomain:domain];
    }
    [self updateStatusSubView];
}
-(void) displayRegistrationFailedFromUI:(UIViewController*) viewCtrl forUser:(NSString*) user withDisplayName:(NSString*) displayName onDomain:(NSString*)domain forReason:(NSString*) reason {
    if (fFirstLoginViewController != nil && self.modalViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayRegistrationFailedFromUI:viewCtrl forUser:user withDisplayName:displayName onDomain:domain forReason:reason];
    }
    [self updateStatusSubView];
}

-(void) displayNotRegisteredFromUI:(UIViewController*) viewCtrl { 
    if (fFirstLoginViewController != nil && self.modalViewController == fFirstLoginViewController) {
        [fFirstLoginViewController displayNotRegisteredFromUI:viewCtrl];
    }
    [self updateStatusSubView];
}

@end
