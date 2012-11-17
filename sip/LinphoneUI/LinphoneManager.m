/* LinphoneManager.h
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
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


#import "LinphoneManager.h"
#include "linphonecore_utils.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FastAddressBook.h"
#include <sys/sysctl.h>
#include <SystemConfiguration/SystemConfiguration.h>

static LinphoneCore* theLinphoneCore=nil;
static LinphoneManager* theLinphoneManager=nil;

extern void libmsilbc_init();
#ifdef HAVE_AMR
extern void libmsamr_init();
#endif

#ifdef HAVE_X264
extern void libmsx264_init();
#endif
#define FRONT_CAM_NAME "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1" /*"AV Capture: Front Camera"*/
#define BACK_CAM_NAME "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:0" /*"AV Capture: Back Camera"*/
#define DEFAULT_EXPIRES 600
#if defined (HAVE_SILK)
extern void libmssilk_init(); 
#endif

#if HAVE_G729
extern  void libmsbcg729_init();
#endif


/*  Implementace managera. Třída zpracovává vše okolo příchozích/odchozích hovorů.
    Zařizuje registraci uživatele na SIP serveru. Zařizuje přijetí/odmítnutí hovorů.
    Volá metody delegátů z LinphoneUIDelegates.
 
    Manager se vytváří/zaniká v AppDelegátu. Při inicializaci Manageru v AppDelegatu se nastavuje
    callDelegát, který následně nastavuje i registrationDelegáta.
*/
@implementation LinphoneManager


@synthesize callDelegate;
@synthesize registrationDelegate;
@synthesize connectivity;
@synthesize frontCamId;
@synthesize backCamId;

//Inicializace managera
-(id) init {
    assert (!theLinphoneManager);
    if ((self= [super init])) {
        mFastAddressBook = [[FastAddressBook alloc] init];
        theLinphoneManager = self;
    }
    return self;
}

//Vrátí instanci managera, která se vytvořila při initu
+(LinphoneManager*) instance {
	return theLinphoneManager;
}

//Ukončí aktuální instanci managera. Nejprve ukončí LinphoneCore a pak nastaví instanci sebe sama na nil.
+(void) destroyInstance {
    [[self instance] destroyLibLinphone];
    theLinphoneManager = nil;    
}

-(NSString*) getDisplayNameFromAddressBook:(NSString*) number andUpdateCallLog:(LinphoneCallLog*)log {
    //1 normalize
    NSString* lNormalizedNumber = [FastAddressBook normalizePhoneNumber:number];
    Contact* lContact = [mFastAddressBook getMatchingRecord:lNormalizedNumber];
    if (lContact) {
        CFStringRef lDisplayName = ABRecordCopyCompositeName(lContact.record);
        
        if (log) {
            //add phone type
            char ltmpString[256];
            CFStringRef lFormatedString = CFStringCreateWithFormat(NULL,NULL,CFSTR("phone_type:%@;"),lContact.numberType);
            CFStringGetCString(lFormatedString, ltmpString,sizeof(ltmpString), kCFStringEncodingUTF8);
            linphone_call_log_set_ref_key(log, ltmpString);
            CFRelease(lFormatedString);
        }
        return (__bridge NSString*)lDisplayName;   
    }
    //[number release];
 
    return nil;
}

-(UIImage*) getImageFromAddressBook:(NSString *)number {
    NSString* lNormalizedNumber = [FastAddressBook normalizePhoneNumber:number];
    Contact* lContact = [mFastAddressBook getMatchingRecord:lNormalizedNumber];
    if (lContact) {
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(mFastAddressBook.addressBook, ABRecordGetRecordID(lContact.record));            
        if (ABPersonHasImageData(person)) {
            NSData* d;
            // ios 4.1+
            if ( &ABPersonCopyImageDataWithFormat != nil) {
                d = (__bridge NSData*)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
            } else {
                d = (__bridge NSData*)ABPersonCopyImageData(person);
            }
            return [UIImage imageWithData:d];
        }
    }
    /* return default image */
    return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"contact_vide" ofType:@"png"]];
    //return nil;
}

-(void) updateCallWithAddressBookData:(LinphoneCall*) call {
    //1 copy adress book
    LinphoneCallLog* lLog = linphone_call_get_call_log(call);
    LinphoneAddress* lAddress;
    if (lLog->dir == LinphoneCallIncoming) {
        lAddress=lLog->from;
    } else {
        lAddress=lLog->to;
    }
    const char* lUserName = linphone_address_get_username(lAddress); 
    if (!lUserName) {
        //just return
        return;
    }
    
    NSString* lE164Number = [[NSString alloc] initWithCString:lUserName encoding:[NSString defaultCStringEncoding]];
    NSString* lDisplayName = [self getDisplayNameFromAddressBook:lE164Number andUpdateCallLog:lLog];
    
    if(lDisplayName) {        
        linphone_address_set_display_name(lAddress, [lDisplayName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else {
        ms_message("No contact entry found for  [%s] in address book",lUserName);
    }
    
    return;
}

-(void) onCall:(LinphoneCall*) call StateChanged: (LinphoneCallState) new_state withMessage: (const char *)  message {
    if(new_state == LinphoneCallReleased) {
        if(linphone_call_get_user_pointer(call) != NULL) {
            free (linphone_call_get_user_pointer(call));
            linphone_call_set_user_pointer(call, NULL);
        }
        return;
    }
    
    const char* lUserNameChars=linphone_address_get_username(linphone_call_get_remote_address(call));
    NSString* lUserName = lUserNameChars?[[NSString alloc] initWithUTF8String:lUserNameChars]:NSLocalizedString(@"Unknown",nil);
    if (new_state == LinphoneCallIncomingReceived) {
       [self updateCallWithAddressBookData:call]; // display name is updated 
    }
    const char* lDisplayNameChars =  linphone_address_get_display_name(linphone_call_get_remote_address(call));
    
    NSString* lDisplayName = lDisplayNameChars ? [[NSString alloc] initWithUTF8String:lDisplayNameChars] :@"" ;
    
    bool canHideInCallView = (linphone_core_get_calls([LinphoneManager getLc]) == NULL);
	
    if (!linphone_call_get_user_pointer(call)) {
        LinphoneCallAppData* data = (LinphoneCallAppData*) malloc(sizeof(LinphoneCallAppData));
        data->batteryWarningShown = FALSE;
        linphone_call_set_user_pointer(call, data);
    }
    
	switch (new_state) {					
		case LinphoneCallIncomingReceived:
            /*first step is to re-enable ctcall center*/
			[self setupGSMInteraction];
			
			/*should we reject this call ?*/
			if ([callCenter currentCalls]!=nil) {
				ms_message("Mobile call ongoing... rejecting call from [%s]",linphone_address_get_username(linphone_call_get_call_log(call)->from));
				linphone_core_decline_call([LinphoneManager getLc], call, LinphoneReasonBusy);
				return;
			}

            
			[callDelegate	displayIncomingCall:call 
                           NotificationFromUI:mCurrentViewController
														forUser:lUserName 
                                                    withDisplayName:lDisplayName];
			break;
			
		case LinphoneCallOutgoingInit: 
			[callDelegate		displayCall:call 
                      InProgressFromUI:mCurrentViewController
											   forUser:lUserName 
									   withDisplayName:lDisplayName];
			break;
        case LinphoneCallPaused:
        case LinphoneCallPausing:
        case LinphoneCallPausedByRemote:
		case LinphoneCallConnected:
			[callDelegate	displayInCall: call 
                                 FromUI:mCurrentViewController
									  forUser:lUserName 
							  withDisplayName:lDisplayName];
			break;
        case LinphoneCallUpdatedByRemote:
        {
            const LinphoneCallParams* current = linphone_call_get_current_params(call);
            const LinphoneCallParams* remote = linphone_call_get_remote_params(call);

            /* remote wants to add video */
            if (!linphone_call_params_video_enabled(current) && linphone_call_params_video_enabled(remote) && !linphone_core_get_video_policy(theLinphoneCore)->automatically_accept) {
                linphone_core_defer_call_update(theLinphoneCore, call);
                [callDelegate displayAskToEnableVideoCall:call forUser:lUserName withDisplayName:lDisplayName];
            } else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
                [callDelegate displayInCall:call FromUI:mCurrentViewController forUser:lUserName withDisplayName:lDisplayName];
            }
            break;
        }
        case LinphoneCallUpdating:
        {
            const LinphoneCallParams* current = linphone_call_get_current_params(call);
            if (linphone_call_params_video_enabled(current)) {
                [callDelegate displayVideoCall:call FromUI:mCurrentViewController forUser:lUserName withDisplayName:lDisplayName];
            } else {
                [callDelegate displayInCall:call FromUI:mCurrentViewController forUser:lUserName withDisplayName:lDisplayName];
            }
            break;
            
        }
		case LinphoneCallError: { 
			/*
			 NSString* lTitle= state->message!=nil?[NSString stringWithCString:state->message length:strlen(state->message)]: @"Error";
			 NSString* lMessage=lTitle;
			 */
			NSString* lMessage;
			NSString* lTitle;
			LinphoneProxyConfig* proxyCfg;	
			//get default proxy
			linphone_core_get_default_proxy([LinphoneManager getLc],&proxyCfg);
			if (proxyCfg == nil) {
				lMessage=NSLocalizedString(@"Please make sure your device is connected to the internet and double check your SIP account configuration in the settings.",nil);
			} else {
				lMessage=[NSString stringWithFormat : NSLocalizedString(@"Cannot call %@",nil),lUserName];
			}
			
            if (linphone_call_get_reason(call) == LinphoneReasonNotFound) {
                lMessage=[NSString stringWithFormat : NSLocalizedString(@"'%@' not registered to Service",nil), lUserName];
            } else {
                if (message!=nil){
                    lMessage=[NSString stringWithFormat : NSLocalizedString(@"%@\nReason was: %s",nil),lMessage, message];
                }
            }
			lTitle=NSLocalizedString(@"Call failed",nil);
			
			UIAlertView* error = [[UIAlertView alloc] initWithTitle:lTitle
															message:lMessage 
														   delegate:nil 
												  cancelButtonTitle:NSLocalizedString(@"Dismiss",nil) 
												  otherButtonTitles:nil];
			[error show];
            if (canHideInCallView) {
                [callDelegate	displayDialerFromUI:mCurrentViewController
									  forUser:@"" 
							  withDisplayName:@""];
            } else {
                call = linphone_core_get_current_call([LinphoneManager getLc]);
                if(call) {
                    const LinphoneCallParams* current = linphone_call_get_current_params(call);
                    if (linphone_call_params_video_enabled(current)) {
                        [callDelegate	displayVideoCall:call FromUI:mCurrentViewController
                                               forUser:lUserName 
                                       withDisplayName:lDisplayName];
                    } else {
                        [callDelegate displayInCall:call 
                                             FromUI:mCurrentViewController
                                            forUser:lUserName 
                                    withDisplayName:lDisplayName];
                    }
                }
			}
			break;
		}
		case LinphoneCallEnd:
            if (canHideInCallView) {
                [callDelegate	displayDialerFromUI:mCurrentViewController
									  forUser:@"" 
							  withDisplayName:@""];
            } else {
                //asi kdyby končil jeden hovor a ihned 
                call = linphone_core_get_current_call([LinphoneManager getLc]);
                if(call) {
                    const LinphoneCallParams* current = linphone_call_get_current_params(call);
                    if (linphone_call_params_video_enabled(current)) {
                        [callDelegate	displayVideoCall:call FromUI:mCurrentViewController
                                                forUser:lUserName 
                                       withDisplayName:lDisplayName];
                    } else {
                        [callDelegate displayInCall:call 
                                             FromUI:mCurrentViewController
                                            forUser:lUserName 
                                    withDisplayName:lDisplayName];
                    }
                }
			}
			break;
		case LinphoneCallStreamsRunning:
			//check video
			if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
				[callDelegate	displayVideoCall:call FromUI:mCurrentViewController
                                       forUser:lUserName 
                               withDisplayName:lDisplayName];
			} else {
                [callDelegate displayInCall:call FromUI:mCurrentViewController forUser:lUserName withDisplayName:lDisplayName];
            }
			break;
        default:
            break;
	}
	
}

-(void) displayDialer {
    [callDelegate	displayDialerFromUI:mCurrentViewController
                              forUser:@"" 
                      withDisplayName:@""];
}

+(LinphoneCore*) getLc {
	if (theLinphoneCore==nil) {
		@throw([NSException exceptionWithName:@"LinphoneCoreException" reason:@"Linphone core not initialized yet" userInfo:nil]);
	}
	return theLinphoneCore;
}

-(void) addLog:(NSString*) log {
	[mLogView addLog:log];
}
-(void)displayStatus:(NSString*) message {
	[callDelegate displayStatus:message];
}
//generic log handler for debug version
static void linphone_iphone_log_handler(int lev, const char *fmt, va_list args){
	NSString* format = [[NSString alloc] initWithCString:fmt encoding:[NSString defaultCStringEncoding]];
	NSLogv(format,args);
	NSString* formatedString = [[NSString alloc] initWithFormat:format arguments:args];
	[[LinphoneManager instance] addLog:formatedString];
}

//Error/warning log handler 
static void linphone_iphone_log(struct _LinphoneCore * lc, const char * message) {
	NSString* log = [NSString stringWithCString:message encoding:[NSString defaultCStringEncoding]]; 
	NSLog(log,NULL);
	[[LinphoneManager instance]addLog:log];
}
//status 
static void linphone_iphone_display_status(struct _LinphoneCore * lc, const char * message) {
    NSString* status = [[NSString alloc] initWithCString:message encoding:[NSString defaultCStringEncoding]];
	[(__bridge LinphoneManager*)linphone_core_get_user_data(lc)  displayStatus:status];
}

static void linphone_iphone_call_state(LinphoneCore *lc, LinphoneCall* call, LinphoneCallState state,const char* message) {
	/*LinphoneCallIdle,
	 LinphoneCallIncomingReceived,
	 LinphoneCallOutgoingInit,
	 LinphoneCallOutgoingProgress,
	 LinphoneCallOutgoingRinging,
	 LinphoneCallOutgoingEarlyMedia,
	 LinphoneCallConnected,
	 LinphoneCallStreamsRunning,
	 LinphoneCallPausing,
	 LinphoneCallPaused,
	 LinphoneCallResuming,
	 LinphoneCallRefered,
	 LinphoneCallError,
	 LinphoneCallEnd,
	 LinphoneCallPausedByRemote
	 */
	[(__bridge LinphoneManager*)linphone_core_get_user_data(lc) onCall:call StateChanged: state withMessage:  message];
}

static void linphone_iphone_transfer_state_changed(LinphoneCore* lc, LinphoneCall* call, LinphoneCallState state) {
    /*
     LinhoneCallOutgoingProgress -> SalReferTrying
     LinphoneCallConnected -> SalReferSuccess
     LinphoneCallError -> SalReferFailed | *
     */
}

-(void) onRegister:(LinphoneCore *)lc cfg:(LinphoneProxyConfig*) cfg state:(LinphoneRegistrationState) state message:(const char*) message {
    ms_warning("NEW REGISTRATION STATE: '%s' (message: '%s')", linphone_registration_state_to_string(state), message);
    
	LinphoneAddress* lAddress = linphone_address_new(linphone_proxy_config_get_identity(cfg));
	NSString* lUserName = linphone_address_get_username(lAddress)? [[NSString alloc] initWithUTF8String:linphone_address_get_username(lAddress) ]:@"";
	NSString* lDisplayName = linphone_address_get_display_name(lAddress)? [[NSString alloc] initWithUTF8String:linphone_address_get_display_name(lAddress) ]:@"";
	NSString* lDomain = [[NSString alloc] initWithUTF8String:linphone_address_get_domain(lAddress)];
	linphone_address_destroy(lAddress);
	
	if (state == LinphoneRegistrationOk) {
		[[(__bridge LinphoneManager*)linphone_core_get_user_data(lc) registrationDelegate] displayRegisteredFromUI:nil
											  forUser:lUserName
									  withDisplayName:lDisplayName
											 onDomain:lDomain ];
	} else if (state == LinphoneRegistrationProgress) {
		[registrationDelegate displayRegisteringFromUI:mCurrentViewController
											  forUser:lUserName
									  withDisplayName:lDisplayName
											 onDomain:lDomain ];
		
	} else if (state == LinphoneRegistrationCleared || state == LinphoneRegistrationNone) {
		[registrationDelegate displayNotRegisteredFromUI:mCurrentViewController];
	} else 	if (state == LinphoneRegistrationFailed ) {
		NSString* lErrorMessage=nil;
		if (linphone_proxy_config_get_error(cfg) == LinphoneReasonBadCredentials) {
			lErrorMessage = NSLocalizedString(@"Bad credentials, check your account settings",nil);
		} else if (linphone_proxy_config_get_error(cfg) == LinphoneReasonNoResponse) {
			lErrorMessage = NSLocalizedString(@"SIP server unreachable",nil);
		} 
		[registrationDelegate displayRegistrationFailedFromUI:mCurrentViewController
											   forUser:lUserName
									   withDisplayName:lDisplayName
											  onDomain:lDomain
												forReason:lErrorMessage];
		
		if (lErrorMessage != nil 
			&& linphone_proxy_config_get_error(cfg) != LinphoneReasonNoResponse) { //do not report network connection issue on registration
			//default behavior if no registration delegates
			UIApplicationState s = [UIApplication sharedApplication].applicationState;
            
            // do not stack error message when going to backgroud
            if (s != UIApplicationStateBackground) {
                UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Registration failure",nil)
															message:lErrorMessage
														   delegate:nil 
												  cancelButtonTitle:NSLocalizedString(@"Continue",nil) 
												  otherButtonTitles:nil ,nil];
                [error show];
            }
		}
		
	}
}
static void linphone_iphone_registration_state(LinphoneCore *lc, LinphoneProxyConfig* cfg, LinphoneRegistrationState state,const char* message) {
	[(__bridge LinphoneManager*)linphone_core_get_user_data(lc) onRegister:lc cfg:cfg state:state message:message];
}

static LinphoneCoreVTable linphonec_vtable = {
	.show =NULL,
	.call_state_changed =(LinphoneCallStateCb)linphone_iphone_call_state,
	.registration_state_changed = linphone_iphone_registration_state,
	.notify_recv = NULL,
	.new_subscription_request = NULL,
	.auth_info_requested = NULL,
	.display_status = linphone_iphone_display_status,
	.display_message=linphone_iphone_log,
	.display_warning=linphone_iphone_log,
	.display_url=NULL,
	.text_received=NULL,
	.dtmf_received=NULL,
    .transfer_state_changed=linphone_iphone_transfer_state_changed
};


-(void) configurePayloadType:(const char*) type fromPrefKey: (NSString*)key withRate:(int)rate  {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:key]) { 		
		PayloadType* pt;
		if((pt = linphone_core_find_payload_type(theLinphoneCore,type,rate, 1))) {
			linphone_core_enable_payload_type(theLinphoneCore,pt, TRUE);
		}
	} 
}
-(void) kickOffNetworkConnection {
	/*start a new thread to avoid blocking the main ui in case of peer host failure*/
	[NSThread detachNewThreadSelector:@selector(runNetworkConnection) toTarget:self withObject:nil];
}
-(void) runNetworkConnection {
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"192.168.0.200"/*"linphone.org"*/, 15000, nil, &writeStream);
	CFWriteStreamOpen (writeStream);
	const char* buff="hello";
	CFWriteStreamWrite (writeStream,(const UInt8*)buff,strlen(buff));
	CFWriteStreamClose (writeStream);
}	

static void showNetworkFlags(SCNetworkReachabilityFlags flags){
	ms_message("Network connection flags:");
	if (flags==0) ms_message("no flags.");
	if (flags & kSCNetworkReachabilityFlagsTransientConnection)
		ms_message("kSCNetworkReachabilityFlagsTransientConnection");
	if (flags & kSCNetworkReachabilityFlagsReachable)
		ms_message("kSCNetworkReachabilityFlagsReachable");
	if (flags & kSCNetworkReachabilityFlagsConnectionRequired)
		ms_message("kSCNetworkReachabilityFlagsConnectionRequired");
	if (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)
		ms_message("kSCNetworkReachabilityFlagsConnectionOnTraffic");
	if (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)
		ms_message("kSCNetworkReachabilityFlagsConnectionOnDemand");
	if (flags & kSCNetworkReachabilityFlagsIsLocalAddress)
		ms_message("kSCNetworkReachabilityFlagsIsLocalAddress");
	if (flags & kSCNetworkReachabilityFlagsIsDirect)
		ms_message("kSCNetworkReachabilityFlagsIsDirect");
	if (flags & kSCNetworkReachabilityFlagsIsWWAN)
		ms_message("kSCNetworkReachabilityFlagsIsWWAN");
}

void networkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* nilCtx);
void networkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* nilCtx){
	showNetworkFlags(flags);
	LinphoneManager* lLinphoneMgr = [LinphoneManager instance];
	SCNetworkReachabilityFlags networkDownFlags=kSCNetworkReachabilityFlagsConnectionRequired |kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand;

	if ([LinphoneManager getLc] != nil) {
		LinphoneProxyConfig* proxy;
		linphone_core_get_default_proxy([LinphoneManager getLc], &proxy);

        struct NetworkReachabilityContext* ctx = nilCtx ? ((struct NetworkReachabilityContext*)nilCtx) : 0;
		if ((flags == 0) || (flags & networkDownFlags)) {
			linphone_core_set_network_reachable([LinphoneManager getLc],false);
			lLinphoneMgr.connectivity = none;
			[[LinphoneManager instance] kickOffNetworkConnection];
		} else {
			Connectivity  newConnectivity;
			BOOL isWifiOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"wifi_only_preference"];
            if (!ctx || ctx->testWWan)
                newConnectivity = flags & kSCNetworkReachabilityFlagsIsWWAN ? wwan:wifi;
            else
                newConnectivity = wifi;

			if (newConnectivity == wwan 
				&& proxy 
				&& isWifiOnly 
				&& (lLinphoneMgr.connectivity == newConnectivity || lLinphoneMgr.connectivity == none)) {
				linphone_proxy_config_expires(proxy, 0);
			} else if (proxy){
				linphone_proxy_config_expires(proxy, DEFAULT_EXPIRES); //might be better to save the previous value
			}
			
			if (lLinphoneMgr.connectivity == none) {
				linphone_core_set_network_reachable([LinphoneManager getLc],true);
				
			} else if (lLinphoneMgr.connectivity != newConnectivity) {
				// connectivity has changed
				linphone_core_set_network_reachable([LinphoneManager getLc],false);
				if (newConnectivity == wwan && proxy && isWifiOnly) {
					linphone_proxy_config_expires(proxy, 0);
				} 
				linphone_core_set_network_reachable([LinphoneManager getLc],true);
				ms_message("Network connectivity changed to type [%s]",(newConnectivity==wifi?"wifi":"wwan"));
			}
			lLinphoneMgr.connectivity=newConnectivity;
		}
		if (ctx && ctx->networkStateChanged) {
            (*ctx->networkStateChanged)(lLinphoneMgr.connectivity);
        }
	}
}

-(BOOL) reconfigureLinphoneIfNeeded:(NSDictionary *)settings {
	if (theLinphoneCore==nil) {
		ms_warning("cannot configure linphone because not initialized yet");
		return NO;
	}
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSDictionary* newSettings = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    if (settings != nil) {
        /* reconfigure only if newSettings != settings */
        if ([newSettings isEqualToDictionary:settings]) {
            ms_message("Same settings: no need to reconfigure linphone");
            return NO;
        }
    }
    NSLog(@"Configuring Linphone (new settings)");
    
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debugenable_preference"]) {
		//redirect all traces to the iphone log framework
		linphone_core_enable_logs_with_cb((OrtpLogFunc)linphone_iphone_log_handler);
	}
	else {
		linphone_core_disable_logs();
	}
    
    NSBundle* myBundle = [NSBundle mainBundle];
    
    /* unregister before modifying any settings */
    {
        LinphoneProxyConfig* proxyCfg;
        linphone_core_get_default_proxy(theLinphoneCore, &proxyCfg);
        
        if (proxyCfg) {
            // this will force unregister WITHOUT destorying the proxyCfg object
            linphone_proxy_config_edit(proxyCfg);
            
            int i=0;
            while (linphone_proxy_config_get_state(proxyCfg)!=LinphoneRegistrationNone &&
                   linphone_proxy_config_get_state(proxyCfg)!=LinphoneRegistrationCleared && 
                    linphone_proxy_config_get_state(proxyCfg)!=LinphoneRegistrationFailed && 
                   i++<40 ) {
                linphone_core_iterate(theLinphoneCore);
                usleep(100000);
            }
        }
    }
    
    const char* lRootCa = [[myBundle pathForResource:@"rootca"ofType:@"pem"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
    linphone_core_set_root_ca(theLinphoneCore, lRootCa);
    
	NSString* transport = [[NSUserDefaults standardUserDefaults] stringForKey:@"transport_preference"];
		
	LCSipTransports transportValue;
	if (transport!=nil) {
		if (linphone_core_get_sip_transports(theLinphoneCore, &transportValue)) {
			ms_error("cannot get current transport");	
		}
		// Only one port can be set at one time, the others's value is 0
		if ([transport isEqualToString:@"tcp"]) {
			if (transportValue.tcp_port == 0) transportValue.tcp_port=transportValue.udp_port + transportValue.tls_port;
			transportValue.udp_port=0;
            transportValue.tls_port=0;
		} else if ([transport isEqualToString:@"udp"]){
			if (transportValue.udp_port == 0) transportValue.udp_port=transportValue.tcp_port + transportValue.tls_port;
			transportValue.tcp_port=0;
            transportValue.tls_port=0;
		} else if ([transport isEqualToString:@"tls"]){
			if (transportValue.tls_port == 0) transportValue.tls_port=transportValue.udp_port + transportValue.tcp_port;
			transportValue.tcp_port=0;
            transportValue.udp_port=0;
		} else {
			ms_error("unexpected transport [%s]",[transport cStringUsingEncoding:[NSString defaultCStringEncoding]]);
		}
		if (linphone_core_set_sip_transports(theLinphoneCore, &transportValue)) {
			ms_error("cannot set transport");	
		}
	}
	


	// Set audio assets
	const char*  lRing = [[myBundle pathForResource:@"oldphone-mono"ofType:@"wav"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
	linphone_core_set_ring(theLinphoneCore, lRing );
	const char*  lRingBack = [[myBundle pathForResource:@"ringback"ofType:@"wav"] cStringUsingEncoding:[NSString defaultCStringEncoding]];
	linphone_core_set_ringback(theLinphoneCore, lRingBack);

	
	
	//configure sip account
	
	//madatory parameters
	
	NSString* username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username_preference"];
	NSString* domain = [[NSUserDefaults standardUserDefaults] stringForKey:@"domain_preference"];
	NSString* accountPassword = [[NSUserDefaults standardUserDefaults] stringForKey:@"password_preference"];
	bool configCheckDisable = [[NSUserDefaults standardUserDefaults] boolForKey:@"check_config_disable_preference"];
	bool isOutboundProxy= [[NSUserDefaults standardUserDefaults] boolForKey:@"outbound_proxy_preference"];
	
	
	//clear auth info list
	linphone_core_clear_all_auth_info(theLinphoneCore);
    //clear existing proxy config
    linphone_core_clear_proxy_config(theLinphoneCore);
	if (username && [username length] >0 && domain && [domain length]>0) {
		const char* identity = [[NSString stringWithFormat:@"sip:%@@%@",username,domain] cStringUsingEncoding:[NSString defaultCStringEncoding]];
		const char* password = [accountPassword cStringUsingEncoding:[NSString defaultCStringEncoding]];
		
		NSString* proxyAddress = [[NSUserDefaults standardUserDefaults] stringForKey:@"proxy_preference"];
		if ((!proxyAddress || [proxyAddress length] <1 ) && domain) {
			proxyAddress = [NSString stringWithFormat:@"sip:%@",domain] ;
		} else {
			proxyAddress = [NSString stringWithFormat:@"sip:%@",proxyAddress] ;
		}
		
		const char* proxy = [proxyAddress cStringUsingEncoding:[NSString defaultCStringEncoding]];
		
		NSString* prefix = [[NSUserDefaults standardUserDefaults] stringForKey:@"prefix_preference"];
        bool substitute_plus_by_00 = [[NSUserDefaults standardUserDefaults] boolForKey:@"substitute_+_by_00_preference"];
		//possible valid config detected
		LinphoneProxyConfig* proxyCfg;	
		proxyCfg = linphone_proxy_config_new();
        
		// add username password
		LinphoneAddress *from = linphone_address_new(identity);
		LinphoneAuthInfo *info;
		if (from !=0){
			info=linphone_auth_info_new(linphone_address_get_username(from),NULL,password,NULL,NULL);
			linphone_core_add_auth_info(theLinphoneCore,info);
		}
		linphone_address_destroy(from);
		
		// configure proxy entries
		linphone_proxy_config_set_identity(proxyCfg,identity);
		linphone_proxy_config_set_server_addr(proxyCfg,proxy);
		linphone_proxy_config_enable_register(proxyCfg,true);
		BOOL isWifiOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"wifi_only_preference"];
		LinphoneManager* lLinphoneMgr = [LinphoneManager instance];
		if (isWifiOnly && lLinphoneMgr.connectivity == wwan) {
			linphone_proxy_config_expires(proxyCfg, 0);
		} else {
			linphone_proxy_config_expires(proxyCfg, DEFAULT_EXPIRES);
		}
		
		if (isOutboundProxy)
			linphone_proxy_config_set_route(proxyCfg,proxy);
		
		if ([prefix length]>0) {
			linphone_proxy_config_set_dial_prefix(proxyCfg, [prefix cStringUsingEncoding:[NSString defaultCStringEncoding]]);
		}
		linphone_proxy_config_set_dial_escape_plus(proxyCfg,substitute_plus_by_00);
		
		linphone_core_add_proxy_config(theLinphoneCore,proxyCfg);
		//set to default proxy
		linphone_core_set_default_proxy(theLinphoneCore,proxyCfg);
		
	} else {
		if (configCheckDisable == false ) {
			UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Warning",nil)
															message:NSLocalizedString(@"It seems you have not configured any proxy server from settings",nil) 
														   delegate:self
												  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
												  otherButtonTitles:NSLocalizedString(@"Never remind",nil),nil];
			[error show];
		}
	}		
	
	//Configure Codecs
	
	PayloadType *pt;
	//get codecs from linphonerc	
	const MSList *audioCodecs=linphone_core_get_audio_codecs(theLinphoneCore);
	const MSList *elem;
	//disable all codecs
	for (elem=audioCodecs;elem!=NULL;elem=elem->next){
		pt=(PayloadType*)elem->data;
		linphone_core_enable_payload_type(theLinphoneCore,pt,FALSE);
	}
	
	//read codecs from setting  bundle and enable them one by one
    if ([self isNotIphone3G]) {
		[self configurePayloadType:"SILK" fromPrefKey:@"silk_24k_preference" withRate:24000];
    }
    else {
        ms_message("SILK 24khz codec deactivated");
    }
	[self configurePayloadType:"speex" fromPrefKey:@"speex_16k_preference" withRate:16000];
	[self configurePayloadType:"speex" fromPrefKey:@"speex_8k_preference" withRate:8000];
	[self configurePayloadType:"SILK" fromPrefKey:@"silk_16k_preference" withRate:16000];
    [self configurePayloadType:"AMR" fromPrefKey:@"amr_8k_preference" withRate:8000];
	[self configurePayloadType:"GSM" fromPrefKey:@"gsm_8k_preference" withRate:8000];
	[self configurePayloadType:"iLBC" fromPrefKey:@"ilbc_preference" withRate:8000];
	[self configurePayloadType:"PCMU" fromPrefKey:@"pcmu_preference" withRate:8000];
	[self configurePayloadType:"PCMA" fromPrefKey:@"pcma_preference" withRate:8000];
	[self configurePayloadType:"G722" fromPrefKey:@"g722_preference" withRate:8000];
	[self configurePayloadType:"G729" fromPrefKey:@"g729_preference" withRate:8000];
	
	//get video codecs from linphonerc
	const MSList *videoCodecs=linphone_core_get_video_codecs(theLinphoneCore);
	//disable video all codecs
	for (elem=videoCodecs;elem!=NULL;elem=elem->next){
		pt=(PayloadType*)elem->data;
		linphone_core_enable_payload_type(theLinphoneCore,pt,FALSE);
	}
	[self configurePayloadType:"MP4V-ES" fromPrefKey:@"mp4v-es_preference" withRate:90000];
	[self configurePayloadType:"H264" fromPrefKey:@"h264_preference" withRate:90000];
    [self configurePayloadType:"VP8" fromPrefKey:@"vp8_preference" withRate:90000];
	
	if ([self isNotIphone3G]) {
		bool enableVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_video_preference"];
		linphone_core_enable_video(theLinphoneCore, enableVideo, enableVideo);
	} else {
		linphone_core_enable_video(theLinphoneCore, FALSE, FALSE);
		ms_warning("Disable video for phones prior to iPhone 3GS");
	}
	bool enableSrtp = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_srtp_preference"];
	linphone_core_set_media_encryption(theLinphoneCore, enableSrtp?LinphoneMediaEncryptionSRTP:LinphoneMediaEncryptionZRTP);

    NSString* stun_server = [[NSUserDefaults standardUserDefaults] stringForKey:@"stun_preference"];
    if ([stun_server length]>0){
        linphone_core_set_stun_server(theLinphoneCore,[stun_server cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        linphone_core_set_firewall_policy(theLinphoneCore, LinphonePolicyUseStun);
    }else{
        linphone_core_set_stun_server(theLinphoneCore, NULL);
        linphone_core_set_firewall_policy(theLinphoneCore, LinphonePolicyNoFirewall);
    }
	
    LinphoneVideoPolicy policy;
    policy.automatically_accept = [[NSUserDefaults standardUserDefaults] boolForKey:@"start_video_preference"];;
    policy.automatically_initiate = [[NSUserDefaults standardUserDefaults] boolForKey:@"start_video_preference"];
    linphone_core_set_video_policy(theLinphoneCore, &policy);
    
	UIDevice* device = [UIDevice currentDevice];
	bool backgroundSupported = false;
	if ([device respondsToSelector:@selector(isMultitaskingSupported)])
		backgroundSupported = [device isMultitaskingSupported];
	
	if (backgroundSupported) {
		isbackgroundModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"backgroundmode_preference"];
	} else {
		isbackgroundModeEnabled=false;
	}

    currentSettings = newSettings;
    
    return YES;
}
- (BOOL)isNotIphone3G
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [[NSString alloc ] initWithUTF8String:machine];
    free(machine);
    
    BOOL result = ![platform isEqualToString:@"iPhone1,2"];
    
    return result;
}

// no proxy configured alert 
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[[NSUserDefaults standardUserDefaults] setBool:true forKey:@"check_config_disable_preference"];
	}
}
-(void) destroyLibLinphone {
	[mIterateTimer invalidate];
    
    [mIterateTimer invalidate];
	
	// destroying eventHandler if app cannot go in background.
	// Otherwise if a GSM call happen and Linphone is resumed,
	// the handler will be called before LinphoneCore is built.
	// Then handler will be restored in becomeActive cb
	callCenter.callEventHandler = nil;
	callCenter = nil;
	
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	[audioSession setDelegate:nil];
	if (theLinphoneCore != nil) { //just in case application terminate before linphone core initialization
        NSLog(@"Destroy linphonecore");
		linphone_core_destroy(theLinphoneCore);
		theLinphoneCore = nil;
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        if (proxyReachability)
            CFRelease(proxyReachability);
        proxyReachability=nil;
        
    }
    
}

//**********************BG mode management*************************///////////
-(BOOL) enterBackgroundMode {
	LinphoneProxyConfig* proxyCfg;
	linphone_core_get_default_proxy(theLinphoneCore, &proxyCfg);	
	linphone_core_stop_dtmf_stream(theLinphoneCore);
	
	if (isbackgroundModeEnabled && proxyCfg) {
		//For registration register
		linphone_core_refresh_registers(theLinphoneCore);
		
		
		//wait for registration answer
		int i=0;
		while (!linphone_proxy_config_is_registered(proxyCfg) && i++<40 ) {
			linphone_core_iterate(theLinphoneCore);
			usleep(100000);
		}
		//register keepalive
		if ([[UIApplication sharedApplication] setKeepAliveTimeout:600/*(NSTimeInterval)linphone_proxy_config_get_expires(proxyCfg)*/ 
														   handler:^{
															   ms_warning("keepalive handler");
															   if (theLinphoneCore == nil) {
																   ms_warning("It seems that Linphone BG mode was deactivated, just skipping");
																   return;
															   }
															   //kick up network cnx, just in case
															   [self kickOffNetworkConnection];
                                                               
															   [self setupGSMInteraction];
															   //to make sure presence status is correct
															   if ([callCenter currentCalls]==nil)
																   linphone_core_set_presence_info(theLinphoneCore, 0, nil, LinphoneStatusAltService);
															   

															   [self refreshRegisters];
															   linphone_core_iterate(theLinphoneCore);
														   }
			 ]) {
			
			
			ms_message("keepalive handler succesfully registered"); 
		} else {
			ms_warning("keepalive handler cannot be registered");
		}
		LCSipTransports transportValue;
		if (linphone_core_get_sip_transports(theLinphoneCore, &transportValue)) {
			ms_error("cannot get current transport");	
		}
		return YES;
	}
	else {
		ms_message("Entering lite bg mode");
		[self destroyLibLinphone];
        return NO;
	}
}


//scheduling loop
-(void) iterate {
	linphone_core_iterate(theLinphoneCore);
}

-(void) setupNetworkReachabilityCallback {
	SCNetworkReachabilityContext *ctx=NULL;
	const char *nodeName="linphone.org";
	
    if (proxyReachability) {
        ms_message("Cancelling old network reachability");
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(proxyReachability);
        proxyReachability = nil;
    }
    
    proxyReachability = SCNetworkReachabilityCreateWithName(nil, nodeName);
    
	//initial state is network off should be done as soon as possible
	SCNetworkReachabilityFlags flags;
	if (!SCNetworkReachabilityGetFlags(proxyReachability, &flags)) {
		ms_error("Cannot get reachability flags: %s", SCErrorString(SCError()));
		return;
	}
	networkReachabilityCallBack(proxyReachability, flags, ctx ? ctx->info : 0);

	if (!SCNetworkReachabilitySetCallback(proxyReachability, (SCNetworkReachabilityCallBack)networkReachabilityCallBack, ctx)){
		ms_error("Cannot register reachability cb: %s", SCErrorString(SCError()));
		return;
	}
	if(!SCNetworkReachabilityScheduleWithRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)){
		ms_error("Cannot register schedule reachability cb: %s", SCErrorString(SCError()));
		return;
	}
}


/*************
 *lib linphone init method
 */
-(void)startLibLinphone  {
	
	//get default config from bundle
	NSBundle* myBundle = [NSBundle mainBundle];
	NSString* factoryConfig = [myBundle pathForResource:[LinphoneManager runningOnIpad]?@"linphonerc-ipad":@"linphonerc" ofType:nil] ;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *confiFileName = [[paths objectAtIndex:0] stringByAppendingString:@"/.linphonerc"];
	NSString *zrtpSecretsFileName = [[paths objectAtIndex:0] stringByAppendingString:@"/zrtp_secrets"];
	connectivity=none;
	signal(SIGPIPE, SIG_IGN);
	//log management	
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debugenable_preference"]) {
		//redirect all traces to the iphone log framework
		linphone_core_enable_logs_with_cb((OrtpLogFunc)linphone_iphone_log_handler);
	}
	else {
		linphone_core_disable_logs();
	}
	
	libmsilbc_init();
#if defined (HAVE_SILK)
    libmssilk_init(); 
#endif	
#ifdef HAVE_AMR
    libmsamr_init(); //load amr plugin if present from the liblinphone sdk
#endif	
#ifdef HAVE_X264
	libmsx264_init(); //load x264 plugin if present from the liblinphone sdk
#endif

#if HAVE_G729
	libmsbcg729_init(); // load g729 plugin
#endif
    
    /* Initialize GSM Interaction */
    [self setupGSMInteraction];
    
	/* Initialize linphone core*/
	
    NSLog(@"Create linphonecore");
	theLinphoneCore = linphone_core_new (&linphonec_vtable
										 , [confiFileName cStringUsingEncoding:[NSString defaultCStringEncoding]]
										 , [factoryConfig cStringUsingEncoding:[NSString defaultCStringEncoding]]
										 ,(__bridge void *)(self));
	
	[[NSUserDefaults standardUserDefaults] synchronize];//sync before loading config 

	linphone_core_set_zrtp_secrets_file(theLinphoneCore, [zrtpSecretsFileName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [self setupNetworkReachabilityCallback];

	[self reconfigureLinphoneIfNeeded:nil];
	
	// start scheduler
	mIterateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 
													 target:self 
												   selector:@selector(iterate) 
												   userInfo:nil 
													repeats:YES];
	//init audio session
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	BOOL bAudioInputAvailable= [audioSession inputIsAvailable];
    [audioSession setDelegate:self];
	
	NSError* err;
	[audioSession setActive:NO error: &err]; 
	if(!bAudioInputAvailable){
		UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"No microphone",nil)
														message:NSLocalizedString(@"You need to plug a microphone to your device to use this application.",nil) 
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Ok",nil) 
											  otherButtonTitles:nil ,nil];
		[error show];
	}
    
    NSString* path = [myBundle pathForResource:@"nowebcamCIF" ofType:@"jpg"];
    if (path) {
        const char* imagePath = [path cStringUsingEncoding:[NSString defaultCStringEncoding]];
        ms_message("Using '%s' as source image for no webcam", imagePath);
        linphone_core_set_static_picture(theLinphoneCore, imagePath);
    }
    
	/*DETECT cameras*/
	frontCamId= backCamId=nil;
	char** camlist = (char**)linphone_core_get_video_devices(theLinphoneCore);
		for (char* cam = *camlist;*camlist!=NULL;cam=*++camlist) {
			if (strcmp(FRONT_CAM_NAME, cam)==0) {
				frontCamId = cam;
				//great set default cam to front
				linphone_core_set_video_device(theLinphoneCore, cam);
			}
			if (strcmp(BACK_CAM_NAME, cam)==0) {
				backCamId = cam;
			}
			
		}

	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] 
		&& [UIApplication sharedApplication].applicationState ==  UIApplicationStateBackground) {
		//go directly to bg mode
		[self enterBackgroundMode];
	}
    
    if ([LinphoneManager runningOnIpad])
        ms_set_cpu_count(2);
    else
        ms_set_cpu_count(1);
    
    ms_warning("Linphone [%s]  started on [%s]"
               ,linphone_core_get_version()
               ,[[UIDevice currentDevice].model cStringUsingEncoding:[NSString defaultCStringEncoding]] );
	
}

-(void) refreshRegisters{
	/*first check if network is available*/
	if (proxyReachability){
		SCNetworkReachabilityFlags flags=0;
		if (!SCNetworkReachabilityGetFlags(proxyReachability, &flags)) {
			ms_error("Cannot get reachability flags, re-creating reachability context.");
			[self setupNetworkReachabilityCallback];
		}else{
			networkReachabilityCallBack(proxyReachability, flags, 0);
			if (flags==0){
				/*workaround iOS bug: reachability API cease to work after some time.*/
				/*when flags==0, either we have no network, or the reachability object lies. To workaround, create a new one*/
				[self setupNetworkReachabilityCallback];
			}
		}
	}else ms_error("No proxy reachability context created !");
	linphone_core_refresh_registers(theLinphoneCore);//just to make sure REGISTRATION is up to date
}

-(void) becomeActive {
    if (theLinphoneCore == nil) {
		//back from standby and background mode is disabled
		[self	startLibLinphone];
	} else {
        if (![self reconfigureLinphoneIfNeeded:currentSettings]) {
            ms_message("becoming active with no config modification, make sure we are registered");
			[self refreshRegisters];
        }
	}
	/*IOS specific*/
	linphone_core_start_dtmf_stream(theLinphoneCore);
    
    
	//call center is unrelialable on the long run, so we change it each time the application is resumed. To avoid zombie GSM call
	[self setupGSMInteraction];
	
	//to make sure presence status is correct
	if ([callCenter currentCalls]==nil)
		linphone_core_set_presence_info(theLinphoneCore, 0, nil, LinphoneStatusAltService);
    
}
-(void) registerLogView:(id<LogView>) view {
	mLogView = view;
}

-(void) beginInterruption {
    LinphoneCall* c = linphone_core_get_current_call(theLinphoneCore);
    ms_message("Sound interruption detected!");
    if (c) {
        linphone_core_pause_call(theLinphoneCore, c);
    }
}

-(void) endInterruption {
    ms_message("Sound interruption ended!");
    //let the user resume the call manually.
}
+(BOOL) runningOnIpad {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    return NO;
}

+(void) set:(UIView*)view hidden: (BOOL) hidden withName:(const char*)name andReason:(const char*) reason{
    if (view.hidden != hidden) {
        ms_message("UI - '%s' is now '%s' ('%s')", name, hidden ? "HIDDEN" : "SHOWN", reason);
        [view setHidden:hidden];
    }
}

+(void) logUIElementPressed:(const char*) name {
    ms_message("UI - '%s' pressed", name);
}

#pragma GSM management

-(void) setupGSMInteraction {
	if (callCenter != nil)
    {
        callCenter.callEventHandler=NULL;
        callCenter = nil;
	}
	callCenter = [[CTCallCenter alloc] init];
	callCenter.callEventHandler = ^(CTCall* call) {
        // post on main thread
		[self performSelectorOnMainThread:@selector(handleGSMCallInteration:)
							   withObject:callCenter
							waitUntilDone:YES];
	};
}

-(void) handleGSMCallInteration: (id) cCenter {
	CTCallCenter* ct = (CTCallCenter*) cCenter;
	/* pause current call, if any */
	LinphoneCall* call = linphone_core_get_current_call(theLinphoneCore);
	if ([ct currentCalls]!=nil) {
		if (call) {
			NSLog(@"Pausing SIP call");
			linphone_core_pause_call(theLinphoneCore, call);
		}
		//set current status to busy
		linphone_core_set_presence_info(theLinphoneCore, 0, nil, LinphoneStatusBusy);
	} else
		linphone_core_set_presence_info(theLinphoneCore, 0, nil, LinphoneStatusAltService);
}


@end
