/* UICallButton.m
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

#import "UICallButton.h"
#import "LinphoneManager.h"
#import "CoreTelephony/CTCallCenter.h"
#import <QuartzCore/QuartzCore.h>


@implementation UICallButton

static BOOL transferMode = NO;

+(void) enableTransforMode:(BOOL) enable {
    transferMode = enable;
}

+(BOOL) transforModeEnabled {
    return transferMode;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        
    }
    return self;
}

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    
}

-(void) touchUp:(id) sender {
	if (!linphone_core_is_network_reachable([LinphoneManager getLc])) {
		UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Network Error",nil)
														message:NSLocalizedString(@"There is no network connection available, enable WIFI or WWAN prior to place a call",nil) 
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Continue",nil) 
											  otherButtonTitles:nil];
		[error show];
		return;
	}
    
    CTCallCenter* ct = [[CTCallCenter alloc] init];
    if ([ct.currentCalls count] > 0) {
        ms_error("GSM call in progress, cancelling outgoing SIP call request");
		UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Cannot make call",nil)
														message:NSLocalizedString(@"Please terminate GSM call",nil) 
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Continue",nil) 
											  otherButtonTitles:nil];
		[error show];
		return;
    }
    
	if (TRUE /*!linphone_core_in_call([LinphoneManager getLc])*/) {
		LinphoneProxyConfig* proxyCfg;	
		//get default proxy
		linphone_core_get_default_proxy([LinphoneManager getLc],&proxyCfg);
		LinphoneCallParams* lcallParams = linphone_core_create_default_call_parameters([LinphoneManager getLc]);
		
		if ([mAddress.text length] == 0) return; //just return
		if ([mAddress.text hasPrefix:@"sip:"]) {
            if (transferMode) {
                linphone_core_transfer_call([LinphoneManager getLc], linphone_core_get_current_call([LinphoneManager getLc]), [mAddress.text cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            } else {
                linphone_core_invite_with_params([LinphoneManager getLc],[mAddress.text cStringUsingEncoding:[NSString defaultCStringEncoding]],lcallParams);
            }
            [UICallButton enableTransforMode:NO];
		} else if ( proxyCfg==nil){
			UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Invalid sip address",nil)
															message:NSLocalizedString(@"Either configure a SIP proxy server from settings prior to place a call or use a valid sip address (I.E sip:john@example.net)",nil) 
														   delegate:nil 
												  cancelButtonTitle:NSLocalizedString(@"Continue",nil) 
												  otherButtonTitles:nil];
			[error show];
		} else {
			char normalizedUserName[256];
			NSString* toUserName = [NSString stringWithString:[mAddress text]];
            NSString* lDisplayName = [[LinphoneManager instance] getDisplayNameFromAddressBook:toUserName andUpdateCallLog:nil];
            
			linphone_proxy_config_normalize_number(proxyCfg,[toUserName cStringUsingEncoding:[NSString defaultCStringEncoding]],normalizedUserName,sizeof(normalizedUserName));
			LinphoneAddress* tmpAddress = linphone_address_new(linphone_core_get_identity([LinphoneManager getLc]));
			linphone_address_set_username(tmpAddress,normalizedUserName);
			linphone_address_set_display_name(tmpAddress,(lDisplayName)?[lDisplayName cStringUsingEncoding:[NSString defaultCStringEncoding]]:nil);


			if (transferMode) {
                linphone_core_transfer_call([LinphoneManager getLc], linphone_core_get_current_call([LinphoneManager getLc]), normalizedUserName);
            } else {
                linphone_core_invite_address_with_params([LinphoneManager getLc],tmpAddress,lcallParams) ;
            }
			
			linphone_address_destroy(tmpAddress);
		}
		linphone_call_params_destroy(lcallParams);
        [UICallButton enableTransforMode:NO];
	} else if (linphone_core_inc_invite_pending([LinphoneManager getLc])) {
		linphone_core_accept_call([LinphoneManager getLc],linphone_core_get_current_call([LinphoneManager getLc]));
	}
	
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code.
 }
 */
-(void) initWithAddress:(UITextField*) address{
	mAddress = address;
    transferMode = NO;
    [self addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
    
    /*
    [self setBackgroundColor:[UIColor whiteColor]];
    
    CAGradientLayer *mGradient = [CAGradientLayer layer];
    mGradient.frame = self.bounds;
    mGradient.colors = [NSArray arrayWithObjects:
                        (id)[[UIColor colorWithRed:188.0f / 255.0f green:227.0f / 255.0f blue:159.0f / 255.0f alpha:1.0f] CGColor],
                        (id)[[UIColor colorWithRed:67.0f / 255.0f green:139.0f / 255.0f blue:50.0f / 255.0f alpha:1.0f] CGColor],
                        nil];
    [self.layer insertSublayer:mGradient atIndex:0];

    
    UIImage *mImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"startcall-green" ofType:@"png"]];
    
    UIImageView *mImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0 , mImage.size.width, mImage.size.height)];
    // Image is hard coded in here for simplicity of this tutorial
    [mImageView setImage:mImage];
    [mImageView setCenter:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)];
    [self addSubview:mImageView];

    
    [self.layer setCornerRadius:9.0];
    [self.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [self.layer setBorderWidth:2.0];
    [self.layer setMasksToBounds:YES];
     */
}


@end
