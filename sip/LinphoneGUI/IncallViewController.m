/* IncallViewController.h
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
#import "IncallViewController.h"
#import "VideoViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AddressBook/AddressBook.h>
#import "linphonecore.h"
#include "LinphoneManager.h"
#include "private.h"
#import "ContactPickerDelegate.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#define AT __FILE__ ":" TOSTRING(__LINE__)

const NSInteger SECURE_BUTTON_TAG=5;



@implementation IncallViewController

@synthesize controlSubView;
@synthesize padSubView;
@synthesize hangUpView;
@synthesize conferenceDetail;

@synthesize endCtrl;
@synthesize close;
@synthesize mute;
@synthesize pause;
@synthesize dialer;
@synthesize speaker;
@synthesize contacts;
@synthesize callTableView;
@synthesize addCall;
@synthesize mergeCalls;
@synthesize transfer;

@synthesize one;
@synthesize two;
@synthesize three;
@synthesize four;
@synthesize five;
@synthesize six;
@synthesize seven;
@synthesize eight;
@synthesize nine;
@synthesize star;
@synthesize zero;
@synthesize hash;
@synthesize videoViewController;

@synthesize videoGroup;
@synthesize videoView;
@synthesize videoPreview;
@synthesize videoCallQuality;
@synthesize videoCameraSwitch;
@synthesize videoUpdateIndicator;
@synthesize videoWaitingForFirstImage;
#ifdef TEST_VIDEO_VIEW_CHANGE
@synthesize testVideoView;
#endif

@synthesize addVideo;


+(void) updateIndicator:(UIImageView*) indicator withCallQuality:(float) quality {
    if (quality >= 4 || quality < 0) {
        [indicator setImage:[UIImage imageNamed:@"stat_sys_signal_4.png"]];
    } else if (quality >= 3) {
        [indicator setImage:[UIImage imageNamed:@"stat_sys_signal_3.png"]];
    } else if (quality >= 2) {
        [indicator setImage:[UIImage imageNamed:@"stat_sys_signal_2.png"]];
    } else if (quality >= 1) {
        [indicator setImage:[UIImage imageNamed:@"stat_sys_signal_1.png"]];
    } else {
        [indicator setImage:[UIImage imageNamed:@"stat_sys_signal_0.png"]];
    }
}

bool isInConference(LinphoneCall* call);
bool isInConference(LinphoneCall* call) {
    if (!call)
        return false;
    return linphone_call_get_current_params(call)->in_conference;
}

int callCount(LinphoneCore* lc);
int callCount(LinphoneCore* lc) {
    int count = 0;
    const MSList* calls = linphone_core_get_calls(lc);
    
    while (calls != 0) {
        if (!isInConference((LinphoneCall*)calls->data)) {
            count++;
        }
        calls = calls->next;
    }
    return count;
}


void addAnimationFadeTransition(UIView* view, float duration);
void addAnimationFadeTransition(UIView* view, float duration) {
    CATransition* animation = [CATransition animation];
    animation.type = kCATransitionFromBottom; // kCATransitionFade;
    animation.duration = duration;
    [view.layer addAnimation:animation forKey:nil];
}

-(void) showControls:(id)sender {
    if (hideControlsTimer) {
        [hideControlsTimer invalidate];
        hideControlsTimer = nil;
    }
    // show controls    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [controlSubView setAlpha:1.0];
    [hangUpView setAlpha:1.0];
    if ([LinphoneManager instance].frontCamId !=nil ) {
        // only show camera switch button if we have more than 1 camera
        [videoCameraSwitch setAlpha:1.0];
    }
    [UIView commitAnimations];
    
    // hide controls in 5 sec
    hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideControls:) userInfo:nil repeats:NO];
}

-(void) hideControls:(id)sender {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [controlSubView setAlpha:0.0];
    [hangUpView setAlpha:0.0];
    [videoCameraSwitch setAlpha:0.0];
    [UIView commitAnimations];
    
    hideControlsTimer = nil;
}


#ifdef TEST_VIDEO_VIEW_CHANGE
// Define TEST_VIDEO_VIEW_CHANGE in IncallViewController.h to enable video view switching testing
-(void) _debugChangeVideoView {
    static bool normalView = false;
    if (normalView) {
        linphone_core_set_native_video_window_id([LinphoneManager getLc], (unsigned long)videoView);
    } else {
        linphone_core_set_native_video_window_id([LinphoneManager getLc], (unsigned long)testVideoView);
    }
    normalView = !normalView;
}
#endif

-(void) enableVideoDisplay {
    [self orientationChanged:nil];
    
    [videoZoomHandler resetZoom];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [videoGroup setAlpha:1.0];
    [controlSubView setAlpha:0.0];
    [hangUpView setAlpha:0.0];
    [callTableView setAlpha:0.0];
    [UIView commitAnimations];
    
    videoView.alpha = 1.0;
    videoView.hidden = FALSE;
    
    linphone_core_set_native_video_window_id([LinphoneManager getLc],(unsigned long)videoView);	
    linphone_core_set_native_preview_window_id([LinphoneManager getLc],(unsigned long)videoPreview);
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
#ifdef TEST_VIDEO_VIEW_CHANGE
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_debugChangeVideoView) userInfo:nil repeats:YES];
#endif
    [self batteryLevelChanged:nil];
}

-(void) disableVideoDisplay {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [videoGroup setAlpha:0.0];
    [controlSubView setAlpha:1.0];
    [hangUpView setAlpha:1.0];
    [callTableView setAlpha:1.0];
    [videoCameraSwitch setAlpha:0.0];
    [UIView commitAnimations];
    
    if (hideControlsTimer != nil) {
        [hideControlsTimer invalidate];
        hideControlsTimer = nil;
    }

    /* restore buttons orientation
    endCtrl.imageView.transform = CGAffineTransformIdentity;
    mute.imageView.transform = CGAffineTransformIdentity;
    speaker.imageView.transform = CGAffineTransformIdentity;
    pause.imageView.transform = CGAffineTransformIdentity;
    contacts.imageView.transform = CGAffineTransformIdentity;
    addCall.imageView.transform = CGAffineTransformIdentity;
    dialer.imageView.transform = CGAffineTransformIdentity;
    videoCallQuality.transform = CGAffineTransformIdentity;  */
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone]; 
}

/* Update in call view buttons (visibility, state, ...) and call duration text.
 This is called periodically. The fullUpdate boolean is set when called after an event (call state change for instance) */
-(void) updateUIFromLinphoneState:(BOOL) fullUpdate {
    activeCallCell = nil;

    // check LinphoneCore is initialized
    LinphoneCore* lc = nil;
    @try {
        lc = [LinphoneManager getLc];
    } @catch (NSException* exc) {
        return;
    }
    // 1 call: show pause button, otherwise show merge btn
    [LinphoneManager set:pause hidden:(callCount(lc) > 1) withName:"PAUSE button" andReason:"call count"];
    [LinphoneManager set:mergeCalls hidden:!pause.hidden withName:"MERGE button" andReason:"call count"];
    // reload table (glow update + call duration)
    [callTableView reloadData];       

    LinphoneCall* currentCall = linphone_core_get_current_call([LinphoneManager getLc]);
    int callsCount = linphone_core_get_calls_nb(lc);

    // hide pause/resume if in conference    
    if (currentCall) {
        [mute reset];
        if (linphone_core_is_in_conference(lc)) {
            [LinphoneManager set:pause hidden:YES withName:"PAUSE button" andReason:"is in conference"];
        }
        else if (callCount(lc) == callsCount && callsCount == 1) {
            [LinphoneManager set:pause hidden:NO withName:"PAUSE button" andReason:"call count == 1"];
            pause.selected = NO;
        } else {
            [LinphoneManager set:pause hidden:YES withName:"PAUSE button" andReason:AT];
        }
        
        if (fullUpdate) {
            videoUpdateIndicator.hidden = YES;
            LinphoneCallState state = linphone_call_get_state(currentCall);
            if (state == LinphoneCallStreamsRunning || state == LinphoneCallUpdating || state == LinphoneCallUpdatedByRemote) {
                if (linphone_call_params_video_enabled(linphone_call_get_current_params(currentCall))) {
                    [addVideo setTitle:NSLocalizedString(@"-video", nil) forState:UIControlStateNormal];
                    [IncallViewController updateIndicator: videoCallQuality withCallQuality:linphone_call_get_average_quality(currentCall)];
                } else {
                    [addVideo setTitle:NSLocalizedString(@"+video", nil) forState:UIControlStateNormal];
                }
                [addVideo setEnabled:YES];
            } else {
                [addVideo setEnabled:NO];
                [videoCallQuality setImage:nil];
            }
        }
    } else {
        if (callsCount == 1) {
            LinphoneCall* c = (LinphoneCall*)linphone_core_get_calls(lc)->data;
            if (linphone_call_get_state(c) == LinphoneCallPaused ||
                linphone_call_get_state(c) == LinphoneCallPausing) {
                pause.selected = YES;                
            }
            [LinphoneManager set:pause hidden:NO withName:"PAUSE button" andReason:AT];
        } else {
            [LinphoneManager set:pause hidden:YES withName:"PAUSE button" andReason:AT];
        }
        [addVideo setEnabled:NO];
    }
    [LinphoneManager set:mergeCalls hidden:!pause.hidden withName:"MERGE button" andReason:AT];
    
    // update conference details view if displayed
    if (self.presentedViewController == conferenceDetail) {
        if (!linphone_core_is_in_conference(lc))
            [self dismissViewControllerAnimated:YES completion:nil];
        else
            [conferenceDetail.table reloadData];
    }
}

-(void) transferPressed {
    /* allow only if call is active */
    if (!linphone_core_get_current_call([LinphoneManager getLc]))
        return;
    
    /* build UIActionSheet */
    if (visibleActionSheet != nil) {
        [visibleActionSheet dismissWithClickedButtonIndex:visibleActionSheet.cancelButtonIndex animated:TRUE];
    }
    
    CallDelegate* cd = [[CallDelegate alloc] init];
    cd.eventType = CD_TRANSFER_CALL;
    cd.delegate = self;
    cd.call = linphone_core_get_current_call([LinphoneManager getLc]);
    NSString* title = NSLocalizedString(@"Transfer to ...",nil);
    visibleActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                     delegate:cd 
                                            cancelButtonTitle:nil  
                                       destructiveButtonTitle:nil // NSLocalizedString(@"Other...",nil)
                                            otherButtonTitles:nil];
    
    // add button for each trasnfer-to valid call
    const MSList* calls = linphone_core_get_calls([LinphoneManager getLc]);
    while (calls) {
        LinphoneCall* call = (LinphoneCall*) calls->data;
        LinphoneCallAppData* data = ((LinphoneCallAppData*)linphone_call_get_user_pointer(call));
        if (call != cd.call && !linphone_call_get_current_params(call)->in_conference) {
            const LinphoneAddress* addr = linphone_call_get_remote_address(call);
            NSString* btnTitle = [NSString stringWithFormat : NSLocalizedString(@"%s",nil), (linphone_address_get_display_name(addr) ?linphone_address_get_display_name(addr):linphone_address_get_username(addr))];
            data->transferButtonIndex = [visibleActionSheet addButtonWithTitle:btnTitle];
        } else {
            data->transferButtonIndex = -1;
        }
        calls = calls->next;
    }
    
    if (visibleActionSheet.numberOfButtons == 0) {
        visibleActionSheet = nil;
        
        [UICallButton enableTransforMode:YES];
        [[LinphoneManager instance] displayDialer];
    } else {
        // add 'Other' option
        [visibleActionSheet addButtonWithTitle:NSLocalizedString(@"Other...",nil)];
        
        // add cancel button on iphone
        if (![LinphoneManager runningOnIpad]) {
            [visibleActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
        }

        visibleActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        if ([LinphoneManager runningOnIpad])
            [visibleActionSheet showFromRect:transfer.bounds inView:transfer animated:NO];
        else
            [visibleActionSheet showInView:self.view];
    }
}

-(void) addCallPressed {
    [LinphoneManager logUIElementPressed:"CALL button"];
    [[LinphoneManager instance] displayDialer];
}


-(void) mergeCallsPressed {
    [LinphoneManager logUIElementPressed:"MERGE button"];
    LinphoneCore* lc = [LinphoneManager getLc];
    linphone_core_add_all_to_conference(lc);
}

-(void) pauseCallPressed {
    [LinphoneManager logUIElementPressed:"PAUSE button"];
    LinphoneCore* lc = [LinphoneManager getLc];
    
    LinphoneCall* currentCall = linphone_core_get_current_call(lc);
	if (currentCall) {
        if (linphone_call_get_state(currentCall) == LinphoneCallStreamsRunning) {
            [pause setSelected:NO];
            linphone_core_pause_call(lc, currentCall);
            
            // hide video view
            [self disableVideoDisplay];
        }
    } else {
        if (linphone_core_get_calls_nb(lc) == 1) {
            LinphoneCall* c = (LinphoneCall*) linphone_core_get_calls(lc)->data;
            if (linphone_call_get_state(c) == LinphoneCallPaused) {
                linphone_core_resume_call(lc, c);
                [pause setSelected:YES];
                
                const LinphoneCallParams* p = linphone_call_get_current_params(c);
                if (linphone_call_params_video_enabled(p)) {
                    [self enableVideoDisplay];
                }
            }
        }
    }
}


-(void)updateCallsDurations {
    [self updateUIFromLinphoneState: NO]; 
}

-(void) awakeFromNib
{
   
}

-(void) displayStatus:(NSString*) message; {

}

-(void) displayPad:(bool) enable {
    if (videoView.hidden)
        [LinphoneManager set:callTableView hidden:enable withName:"CALL_TABLE view" andReason:AT];
    [LinphoneManager set:hangUpView hidden:enable withName:"HANG_UP view" andReason:AT];
    [LinphoneManager set:controlSubView hidden:enable withName:"CONTROL view" andReason:AT];
    [LinphoneManager set:padSubView hidden:!enable withName:"PAD view" andReason:AT];
}
-(void) displayCall:(LinphoneCall*) call InProgressFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
	//restore view
	[self displayPad:false];
	dismissed = false;
	UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
	//if ([speaker isOn]) 
	//	[speaker toggle];
    [self updateUIFromLinphoneState: YES]; 
}

-(void) displayIncomingCall:(LinphoneCall *)call NotificationFromUI:(UIViewController *)viewCtrl forUser:(NSString *)username withDisplayName:(NSString *)displayName {
    
}

-(void) displayInCall:(LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    dismissed = false;
	UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
	if (call !=nil  && linphone_call_get_dir(call)==LinphoneCallIncoming) {
		//if ([speaker isOn]) [speaker toggle];
	}
    [self updateUIFromLinphoneState: YES];
    
    [self disableVideoDisplay];
}
-(void) displayDialerFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    [self disableVideoDisplay];
	UIViewController* modalVC = self.presentedViewController;
	UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    dismissed = true;
    if (modalVC != nil) {
        mVideoIsPending=FALSE;
        // clear previous native window ids
        if (modalVC == mVideoViewController) {
            mVideoShown=FALSE;
            linphone_core_set_native_video_window_id([LinphoneManager getLc],0);	
            linphone_core_set_native_preview_window_id([LinphoneManager getLc],0);
        }
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone]; 
		[self dismissViewControllerAnimated:FALSE completion:nil];//just in case
    }

	[self dismissViewControllerAnimated:FALSE completion:nil]; //disable animation to avoid blanc bar just below status bar*/
    [self updateUIFromLinphoneState: YES]; 
}

static void hideSpinner(LinphoneCall* lc, void* user_data);

-(void) hideSpinnerIndicator: (LinphoneCall*)call {
    if (!videoWaitingForFirstImage.hidden) {
        videoWaitingForFirstImage.hidden = TRUE;
    } /*else {
        linphone_call_set_next_video_frame_decoded_callback(call, hideSpinner, self);
    }*/
}

static void hideSpinner(LinphoneCall* call, void* user_data) {
    IncallViewController* thiz = (__bridge IncallViewController*) user_data;
    [thiz hideSpinnerIndicator:call];
}

-(void) displayVideoCall:(LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName { 
    
    [self enableVideoDisplay];

    [self updateUIFromLinphoneState: YES];
    videoWaitingForFirstImage.hidden = NO;
    [videoWaitingForFirstImage startAnimating];
    
    if (call->videostream) {
        linphone_call_set_next_video_frame_decoded_callback(call, hideSpinner, (__bridge void *)(self));
    }
    return;
    
	if (mIncallViewIsReady) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        mVideoShown=TRUE;
        if (self.presentedViewController != mVideoViewController)
            [self presentViewController:mVideoViewController animated:true completion:nil];
        else
            ms_message("Do not present again videoViewController");
	} else {
		//postpone presentation
		mVideoIsPending=TRUE;
	}
}

-(void) dismissActionSheet: (id)o {
    if (visibleActionSheet != nil) {
        [visibleActionSheet dismissWithClickedButtonIndex:visibleActionSheet.cancelButtonIndex animated:TRUE];
        visibleActionSheet = nil;
    }
}

-(void) displayAskToEnableVideoCall:(LinphoneCall*) call forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    if (linphone_core_get_video_policy([LinphoneManager getLc])->automatically_accept)
        return;
    
    // ask the user if he agrees
    CallDelegate* cd = [[CallDelegate alloc] init];
    cd.eventType = CD_VIDEO_UPDATE;
    cd.delegate = self;
    cd.call = call;
    
    if (visibleActionSheet != nil) {
        [visibleActionSheet dismissWithClickedButtonIndex:visibleActionSheet.cancelButtonIndex animated:TRUE];
    }
    NSString* title = [NSString stringWithFormat : NSLocalizedString(@"'%@' would like to enable video",nil), ([displayName length] > 0) ?displayName:username];
    visibleActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                    delegate:cd 
                                           cancelButtonTitle:NSLocalizedString(@"Decline",nil) 
                                      destructiveButtonTitle:NSLocalizedString(@"Accept",nil) 
                                           otherButtonTitles:nil];
    
    visibleActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [visibleActionSheet showInView:self.view];
    
    /* start cancel timer */
    cd.timeout = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(dismissActionSheet:) userInfo:nil repeats:NO];
}

-(void) firstVideoFrameDecoded: (LinphoneCall*) call {
    // hide video in progress view indicator
    videoWaitingForFirstImage.hidden = TRUE;
}

- (IBAction)doAction:(id)sender {
	
	if (sender == dialer) {
		[self displayPad:true];
		
	} else if (sender == contacts) {
		// start people picker
		myPeoplePickerController = [[ABPeoplePickerNavigationController alloc] init];
		[myPeoplePickerController setPeoplePickerDelegate:[[ContactPickerDelegate alloc] init] ];
		
		[self presentViewController: myPeoplePickerController animated:true completion:nil];
	} else if (sender == close) {
		[self displayPad:false];
	} 	
}


+(LinphoneCall*) retrieveCallAtIndex: (NSInteger) index inConference:(bool) conf{
    const MSList* calls = linphone_core_get_calls([LinphoneManager getLc]);
    
    if (!conf && linphone_core_get_conference_size([LinphoneManager getLc]))
        index--;
    
    while (calls != 0) {
        if (isInConference((LinphoneCall*)calls->data) == conf) {
            if (index == 0)
                break;
            index--;
        }
        calls = calls->next;
    }
    
    if (calls == 0) {
        ms_error("Cannot find call with index %d (in conf: %d)", index, conf);
        return nil;
    } else {
        return (LinphoneCall*)calls->data;
    }
}

-(void) updateActive:(bool_t)active cell:(UITableViewCell*) cell {
    if (!active) {
        
        cell.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.2];
        
        UIColor* c = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [cell.textLabel setTextColor:c];
        [cell.detailTextLabel setTextColor:c];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:(0.7+sin(2*glow)*0.3)];
        [cell.textLabel setTextColor:[UIColor whiteColor]];  
        [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    } 
    [cell.textLabel setBackgroundColor:[UIColor clearColor]];
    [cell.detailTextLabel setBackgroundColor:[UIColor clearColor]];
}

-(void) updateGlow {
    if (!activeCallCell)
        return;
    
    glow += 0.1;

    [self updateActive:YES cell:activeCallCell];
    [activeCallCell.backgroundView setNeedsDisplay];
    [activeCallCell setNeedsDisplay];
    [callTableView setNeedsDisplay];
}

+ (void) updateCellImageView:(UIImageView*)imageView Label:(UILabel*)label DetailLabel:(UILabel*)detailLabel AndAccessoryView:(UIView*)accessoryView withCall:(LinphoneCall*) call {
    if (call == NULL) {
        ms_warning("UpdateCell called with null call");
        [label setText:@""];
        return;
    }
    const LinphoneAddress* addr = linphone_call_get_remote_address(call);
    
    label.adjustsFontSizeToFitWidth = YES;
    
    if (addr) {
		const char* lUserNameChars=linphone_address_get_username(addr);
		NSString* lUserName = lUserNameChars?[[NSString alloc] initWithUTF8String:lUserNameChars]:NSLocalizedString(@"Unknown",nil);
        NSMutableString* mss = [[NSMutableString alloc] init];
        /* contact name */
        const char* n = linphone_address_get_display_name(addr);
        if (n) 
            [mss appendFormat:@"%s", n, nil];
        else
            [mss appendFormat:@"%@",lUserName , nil];
        
        if ([mss compare:label.text] != 0 || imageView.image == nil) {
            [label setText:mss];
        
            imageView.image = [[LinphoneManager instance] getImageFromAddressBook:lUserName];
        }
    } else {
        [label setText:@"plop"];
        imageView.image = nil;
    }
    
    if (detailLabel != nil) {
        NSMutableString* ms = [[NSMutableString alloc] init ];
        if (linphone_call_get_state(call) == LinphoneCallStreamsRunning) {
            int duration = linphone_call_get_duration(call);
            if (duration >= 60)
                [ms appendFormat:@"%02i:%02i", (duration/60), duration - 60*(duration/60), nil];
            else
                [ms appendFormat:@"%02i sec", duration, nil];
        } else {
            switch (linphone_call_get_state(call)) {
                case LinphoneCallPaused:
                    if(!linphone_core_sound_resources_locked(linphone_call_get_core(call))) {
                        [ms appendFormat:@"%@", NSLocalizedString(@"Paused (tap to resume)", nil), nil];
                    } else {
                        [ms appendFormat:@"%@", NSLocalizedString(@"Paused", nil), nil];
                    }
                    break;
                case LinphoneCallOutgoingInit:
                case LinphoneCallOutgoingProgress:
                    [ms appendFormat:@"%@...", NSLocalizedString(@"In progress", nil), nil];
                    break;
                case LinphoneCallOutgoingRinging:
                    [ms appendFormat:@"%@...", NSLocalizedString(@"Ringing...", nil), nil];
                    break;
                case LinphoneCallPausedByRemote:
                {
                    switch (linphone_call_get_transfer_state(call)) {
                        case LinphoneCallOutgoingInit:
                        case LinphoneCallOutgoingProgress:
                            [ms appendFormat:@"%@...", NSLocalizedString(@"Transfer in progress", nil), nil];
                            break;
                        case LinphoneCallConnected:
                            [ms appendFormat:@"%@", NSLocalizedString(@"Transfer successful", nil), nil];
                            break;
                        case LinphoneCallError:
                            [ms appendFormat:@"%@", NSLocalizedString(@"Transfer failed", nil), nil];
                            break;
                        case LinphoneCallIdle:
                        default:
                            [ms appendFormat:@"%@...", NSLocalizedString(@"Paused by remote", nil), nil];
                            break;
                    }
                    break;
                default:
                    break;
                }
            }
        }
        [detailLabel setText:ms];
    }
}


-(void) updateConferenceCell:(UITableViewCell*) cell at:(NSIndexPath*)indexPath {
    LinphoneCore* lc = [LinphoneManager getLc];
    
    NSString* t= [NSString stringWithFormat:
                  NSLocalizedString(@"Conference", nil), 
                  linphone_core_get_conference_size(lc) - linphone_core_is_in_conference(lc)];
    [cell.textLabel setText:t];
    
    [self updateActive:NO cell:cell];
    cell.selected = NO;
    
    [callTableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (!linphone_core_is_in_conference(lc)) {
        [cell.detailTextLabel setText:NSLocalizedString(@"(tap to enter conference)", nil)];
    } else {
        [cell.detailTextLabel setText:
         [NSString stringWithFormat:NSLocalizedString(@"(me + %d participants)", nil), linphone_core_get_conference_size(lc) - linphone_core_is_in_conference(lc)]];
    }	
    cell.imageView.image = nil;
}
       
// UITableViewDataSource (required)
- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [callTableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.font = [UIFont systemFontOfSize:40];
        cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    
    LinphoneCore* lc = [LinphoneManager getLc];
	
	if (indexPath.row == 0 && linphone_core_get_conference_size(lc) > 0) {
        [self updateConferenceCell:cell at:indexPath];
        if (linphone_core_is_in_conference(lc))
            activeCallCell = cell;
		cell.accessoryView = nil;
        if (linphone_core_is_in_conference(lc))
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        LinphoneCall* call = [IncallViewController retrieveCallAtIndex:indexPath.row inConference:NO];
		if (call == nil)
            return cell; // return dummy cell
		LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
        if (cell.accessoryView == nil) {
			UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
			cell.accessoryView = containerView;
		}
		else {
			for (UIView *view in cell.accessoryView.subviews) {
				[view removeFromSuperview];
			}
		}
        [IncallViewController updateCellImageView:cell.imageView Label:cell.textLabel DetailLabel:cell.detailTextLabel AndAccessoryView:(UIView*)cell.accessoryView withCall:call];
        if (linphone_core_get_current_call(lc) == call)
            activeCallCell = cell;
        cell.accessoryType = UITableViewCellAccessoryNone;
		
		// Call Quality Indicator
		UIImageView* callquality = [UIImageView new];
		[callquality setFrame:CGRectMake(0, 0, 28, 28)];
		if (call->state == LinphoneCallStreamsRunning) 
		{
            [IncallViewController   updateIndicator: callquality withCallQuality:linphone_call_get_average_quality(call)];
		}
		else {
			[callquality setImage:nil];
		}
		
        if (enc != LinphoneMediaEncryptionNone) {
            cell.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 28)];
            UIButton* accessoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [accessoryBtn setFrame:CGRectMake(30, 0, 28, 28)];
            [accessoryBtn setImage:nil forState:UIControlStateNormal];
            [accessoryBtn setTag:SECURE_BUTTON_TAG];
            accessoryBtn.backgroundColor = [UIColor clearColor];
            accessoryBtn.userInteractionEnabled = YES;
			
            if (enc == LinphoneMediaEncryptionSRTP || linphone_call_get_authentication_token_verified(call)) {
                [accessoryBtn setImage: verified forState:UIControlStateNormal];
            } else {
                [accessoryBtn setImage: unverified forState:UIControlStateNormal];
            }
			[cell.accessoryView addSubview:accessoryBtn];
			
			if (((UIButton*)accessoryBtn).imageView.image != nil && linphone_call_params_get_media_encryption(linphone_call_get_current_params(call)) == LinphoneMediaEncryptionZRTP) {
				[((UIButton*)accessoryBtn) addTarget:self action:@selector(secureIconPressed:withEvent:) forControlEvents:UIControlEventTouchUpInside];
			}
        } 
		
		[cell.accessoryView addSubview:callquality];
    }
    
    cell.userInteractionEnabled = YES; 
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
} 

-(void) secureIconPressed:(UIControl*) button withEvent: (UIEvent*) evt {
    NSSet* touches = [evt allTouches];
    UITouch* touch = [touches anyObject];
    CGPoint currentTouchPos = [touch locationInView:self.callTableView];
    NSIndexPath *path = [self.callTableView indexPathForRowAtPoint:currentTouchPos];
    if (path) {
        LinphoneCall* call = [IncallViewController retrieveCallAtIndex:path.row inConference:NO];
        // start action sheet to validate/unvalidate zrtp code
        CallDelegate* cd = [[CallDelegate alloc] init];
        cd.eventType = CD_ZRTP;
        cd.delegate = self;
        cd.call = call;
        UIView* container=(UIView*)[callTableView cellForRowAtIndexPath:path].accessoryView;
        UIButton *button=(UIButton*)[container viewWithTag:SECURE_BUTTON_TAG];
        [button setImage:nil forState:UIControlStateNormal];
            
        if (visibleActionSheet != nil) {
            [visibleActionSheet dismissWithClickedButtonIndex:visibleActionSheet.cancelButtonIndex animated:TRUE];
        }
		visibleActionSheet = [[UIActionSheet alloc] initWithTitle:[NSString  stringWithFormat:NSLocalizedString(@" Mark auth token '%s' as:",nil),linphone_call_get_authentication_token(call)]
                                                    delegate:cd 
                                                    cancelButtonTitle:NSLocalizedString(@"Unverified",nil) 
                                                    destructiveButtonTitle:NSLocalizedString(@"Verified",nil) 
                                                    otherButtonTitles:nil];
        
		visibleActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[visibleActionSheet showInView:self.view];
    }
}

-(void) actionSheet:(UIActionSheet *)actionSheet ofType:(enum CallDelegateType)type clickedButtonAtIndex:(NSInteger)buttonIndex withUserDatas:(void *)datas {
    LinphoneCall* call = (LinphoneCall*)datas;
    // maybe we could verify call validity

    switch (type) {
        case CD_ZRTP: {
            if (buttonIndex == 0)
                linphone_call_set_authentication_token_verified(call, YES);
            else if (buttonIndex == 1)
                linphone_call_set_authentication_token_verified(call, NO);
            visibleActionSheet = nil;
            break;
        }
        case CD_VIDEO_UPDATE: {
            LinphoneCall* call = (LinphoneCall*)datas;
            LinphoneCallParams* paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(call));
            if ([visibleActionSheet destructiveButtonIndex] == buttonIndex) {
                // accept video
                linphone_call_params_enable_video(paramsCopy, TRUE);
                linphone_core_accept_call_update([LinphoneManager getLc], call, paramsCopy);
            } else {
                // decline video
                ms_message("User declined video proposal");
                linphone_core_accept_call_update([LinphoneManager getLc], call, NULL);
            }
            linphone_call_params_destroy(paramsCopy);
            visibleActionSheet = nil;
            break;
        }
        case CD_STOP_VIDEO_ON_LOW_BATTERY: {
            LinphoneCall* call = (LinphoneCall*)datas;
            LinphoneCallParams* paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(call));
            if ([visibleActionSheet destructiveButtonIndex] == buttonIndex) {
                // stop video
                linphone_call_params_enable_video(paramsCopy, FALSE);
                linphone_core_update_call([LinphoneManager getLc], call, paramsCopy);
            }
            break;
        }
        case CD_TRANSFER_CALL: {
            LinphoneCall* call = (LinphoneCall*)datas;
            // browse existing call and trasnfer to the one matching the btn id
            const MSList* calls = linphone_core_get_calls([LinphoneManager getLc]);
            while (calls) {
                LinphoneCall* call2 = (LinphoneCall*) calls->data;
                LinphoneCallAppData* data = ((LinphoneCallAppData*)linphone_call_get_user_pointer(call2));
                if (data->transferButtonIndex == buttonIndex) {
                    linphone_core_transfer_call_to_another([LinphoneManager getLc], call, call2);
                    return;
                }
                data->transferButtonIndex = -1;
                calls = calls->next;
            }
            if (![LinphoneManager runningOnIpad] && buttonIndex == (actionSheet.numberOfButtons - 1)) {
                // cancel button
                return;
            }
            // user must jhave pressed 'other...' button as we did not find a call
            // with the correct indice
            [UICallButton enableTransforMode:YES];
            [[LinphoneManager instance] displayDialer];
            break;
        }
        default:
            ms_error("Unhandled CallDelegate event of type: %d received - ignoring", type);
    }
}

#pragma mark - UIView
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	//Controls
	[mute initWithOnImage:[UIImage imageNamed:@"micro_inverse.png"]  offImage:[UIImage imageNamed:@"micro.png"] debugName:"MUTE button"];
    [speaker initWithOnImage:[UIImage imageNamed:@"HP_inverse.png"]  offImage:[UIImage imageNamed:@"HP.png"] debugName:"SPEAKER button"];
    
    verified = [UIImage imageNamed:@"secured.png"];
    unverified = [UIImage imageNamed:@"unverified.png"];
    
	//Dialer init
	[zero initWithNumber:'0'];
	[one initWithNumber:'1'];
	[two initWithNumber:'2'];
	[three initWithNumber:'3'];
	[four initWithNumber:'4'];
	[five initWithNumber:'5'];
	[six initWithNumber:'6'];
	[seven initWithNumber:'7'];
	[eight initWithNumber:'8'];
	[nine initWithNumber:'9'];
	[star initWithNumber:'*'];
	[hash initWithNumber:'#'];
    
    [addCall addTarget:self action:@selector(addCallPressed) forControlEvents:UIControlEventTouchUpInside];
    [mergeCalls addTarget:self action:@selector(mergeCallsPressed) forControlEvents:UIControlEventTouchUpInside];
    [pause addTarget:self action:@selector(pauseCallPressed) forControlEvents:UIControlEventTouchUpInside];
    [LinphoneManager set:mergeCalls hidden:YES withName:"MERGE button" andReason:"initialisation"];
    
    if ([LinphoneManager runningOnIpad]) {
        ms_message("Running on iPad");
        mVideoViewController =  [[VideoViewController alloc]  initWithNibName:@"VideoViewController-ipad"
                                                                       bundle:[NSBundle mainBundle]];
        conferenceDetail = [[ConferenceCallDetailView alloc]  initWithNibName:@"ConferenceCallDetailView-ipad"
                                                                       bundle:[NSBundle mainBundle]];
        
    } else {
        mVideoViewController =  [[VideoViewController alloc]  initWithNibName:@"VideoViewController"
                                                                       bundle:[NSBundle mainBundle]];
        conferenceDetail = [[ConferenceCallDetailView alloc]  initWithNibName:@"ConferenceCallDetailView"
                                                                       bundle:[NSBundle mainBundle]];
        
    }
    
    UITapGestureRecognizer* singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControls:)];
    [singleFingerTap setNumberOfTapsRequired:1];
    [videoGroup addGestureRecognizer:singleFingerTap];
    
    videoZoomHandler = [[VideoZoomHandler alloc] init];
    [videoZoomHandler setup:videoGroup];
    videoGroup.alpha = 0;
    
    mVideoShown=FALSE;
	mIncallViewIsReady=FALSE;
	mVideoIsPending=FALSE;
    //selectedCall = nil;
    
    callTableView.rowHeight = 80;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelChanged:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    
    
    [videoCameraSwitch setPreview:videoPreview];
    addVideo.videoUpdateIndicator = videoUpdateIndicator;
    
    [transfer addTarget:self action:@selector(transferPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidUnload{
    //uklidíme po sobě
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceBatteryLevelDidChangeNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [super viewDidAppear:animated];
	if (dismissed) {
        [self dismissViewControllerAnimated:true completion:nil];
    } else {
        [self updateCallsDurations];
        durationRefreasher = [NSTimer	scheduledTimerWithTimeInterval:1
                                                              target:self
                                                            selector:@selector(updateCallsDurations)
                                                            userInfo:nil
                                                             repeats:YES];
        glowingTimer = [NSTimer	scheduledTimerWithTimeInterval:0.1
                                                        target:self
                                                      selector:@selector(updateGlow)
                                                      userInfo:nil
                                                       repeats:YES];
        glow = 0;
		mIncallViewIsReady=TRUE;
		if (mVideoIsPending) {
			mVideoIsPending=FALSE;
			[self displayVideoCall:nil FromUI:self
						   forUser:nil
				   withDisplayName:nil];
			
		}
        
		
		UIDevice* device = [UIDevice currentDevice];
		if ([device respondsToSelector:@selector(isMultitaskingSupported)]
			&& [device isMultitaskingSupported]) {
			bool enableVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_video_preference"];
            
            [LinphoneManager set:contacts hidden:enableVideo withName:"CONTACT button" andReason:AT];
            [LinphoneManager set:addVideo hidden:!contacts.hidden withName:"ADD_VIDEO button" andReason:AT];
		}
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    if (visibleActionSheet != nil) {
        [visibleActionSheet dismissWithClickedButtonIndex:visibleActionSheet.cancelButtonIndex animated:NO];
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    if (durationRefreasher != nil) {
        [durationRefreasher invalidate];
        durationRefreasher=nil;
        [glowingTimer invalidate];
        glowingTimer = nil;
    }
	if (!mVideoShown) [[UIApplication sharedApplication] setIdleTimerDisabled:false];
	mIncallViewIsReady=FALSE;
    dismissed = false;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait
    || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight
    || toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft;
}

#pragma mark - Handle people picker behavior

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	return true;
	
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
								property:(ABPropertyID)property
							  identifier:(ABMultiValueIdentifier)identifier {
	
	return false;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
	[self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - UITableViewDataSource

// UITableViewDataSource (required)
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    LinphoneCore* lc = [LinphoneManager getLc];
    
    return callCount(lc) + (int)(linphone_core_get_conference_size(lc) > 0);
    
    if (section == 0 && linphone_core_get_conference_size(lc) > 0)
        return linphone_core_get_conference_size(lc) - linphone_core_is_in_conference(lc);
    
    return callCount(lc);
}

// UITableViewDataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
    LinphoneCore* lc = [LinphoneManager getLc];
    int count = 0;
    
    if (callCount(lc) > 0)
        count++;
    
    if (linphone_core_get_conference_size([LinphoneManager getLc]) > 0)
        count ++;
    
    return count;
}

// UITableViewDataSource
- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

// UITableViewDataSource
- (NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    LinphoneCore* lc = [LinphoneManager getLc];

    bool inConf = (indexPath.row == 0 && linphone_core_get_conference_size(lc) > 0);
    
    LinphoneCall* selectedCall = [IncallViewController retrieveCallAtIndex:indexPath.row inConference:inConf];
    
    if (inConf) {
        if (linphone_core_is_in_conference(lc))
            return;
        LinphoneCall* current = linphone_core_get_current_call(lc);
        if (current)
            linphone_core_pause_call(lc, current);
        linphone_core_enter_conference([LinphoneManager getLc]);
    } else if (selectedCall) {
        if (linphone_core_is_in_conference(lc)) {
            linphone_core_leave_conference(lc);
        }
        if(!linphone_core_sound_resources_locked(lc)) {
            linphone_core_resume_call([LinphoneManager getLc], selectedCall);
        }
    }
    
    [self updateUIFromLinphoneState: YES];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateActive:(cell == activeCallCell) cell:cell];
}

-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // show conference detail view
    [self presentViewController:conferenceDetail animated:true completion:nil];
    
}

#pragma mark - Observing implementation

-(void) orientationChanged: (NSNotification*) notif {
    int oldLinphoneOrientation = linphone_core_get_device_rotation([LinphoneManager getLc]);
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    int newRotation = 0;
    switch (orientation) {
        case UIInterfaceOrientationLandscapeRight:
            newRotation = 270;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            newRotation = 90;
            break;
        default:
            newRotation = 0;
    }
    if (oldLinphoneOrientation != newRotation) {
        linphone_core_set_device_rotation([LinphoneManager getLc], newRotation);
        linphone_core_set_native_video_window_id([LinphoneManager getLc],(unsigned long)videoView);
        
        LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
        if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
            //Orientation has changed, must call update call
            linphone_core_update_call([LinphoneManager getLc], call, NULL);
            
            
            /* animate button images rotation 
#define degreesToRadians(x) (M_PI * x / 180.0)
            CGAffineTransform transform = CGAffineTransformIdentity;
            switch (orientation) {
                case UIInterfaceOrientationLandscapeRight:
                    transform = CGAffineTransformMakeRotation(degreesToRadians(90));
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    transform = CGAffineTransformMakeRotation(degreesToRadians(-90));
                    break;
                default:
                    transform = CGAffineTransformIdentity;
                    break;
            }
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2f];
            endCtrl.imageView.transform = transform;
            mute.imageView.transform = transform;
            speaker.imageView.transform = transform;
            pause.imageView.transform = transform;
            contacts.imageView.transform = transform;
            addCall.imageView.transform = transform;
            addVideo.imageView.transform = transform;
            dialer.imageView.transform = transform;
            videoCallQuality.transform = transform;
            [UIView commitAnimations];*/
        }
    }
}

-(void) batteryLevelChanged: (NSNotification*) notif {
    LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
    if (!call || !linphone_call_params_video_enabled(linphone_call_get_current_params(call)))
        return;
    LinphoneCallAppData* appData = (LinphoneCallAppData*) linphone_call_get_user_pointer(call);
    if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged) {
        float level = [UIDevice currentDevice].batteryLevel;
        ms_message("Video call is running. Battery level: %.2f", level);
        if (level < 0.1 && !appData->batteryWarningShown) {
            // notify user
            CallDelegate* cd = [[CallDelegate alloc] init];
            cd.eventType = CD_STOP_VIDEO_ON_LOW_BATTERY;
            cd.delegate = self;
            cd.call = call;
            
            if (visibleActionSheet != nil) {
                [visibleActionSheet dismissWithClickedButtonIndex:visibleActionSheet.cancelButtonIndex animated:TRUE];
            }
            NSString* title = NSLocalizedString(@"Battery is running low. Stop video ?",nil);
            visibleActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:cd
                                                    cancelButtonTitle:NSLocalizedString(@"Continue video",nil)
                                               destructiveButtonTitle:NSLocalizedString(@"Stop video",nil)
                                                    otherButtonTitles:nil];
            
            visibleActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
            [visibleActionSheet showInView:self.view];
            appData->batteryWarningShown = TRUE;
        }
    }
}



@end
