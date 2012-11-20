/* AboutViewController.m
 *
 * Copyright (C) 2010  Haidy a.s., Prague, Czech Republic
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

#import "AboutViewController.h"
#import "LinphoneManager.h"
#import <QuartzCore/QuartzCore.h>


@implementation AboutViewController

@synthesize cellWebLinphone, cellCreditLinphone, weburiLinphone;
@synthesize cellWeb, cellCredit, creditText ,weburi, image;

//Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"About",nil)];
    
	[creditText setText: [NSString stringWithFormat:NSLocalizedString(@"Credit text",nil),[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]];
    
    [image.layer setCornerRadius:9.0];
    [image.layer setMasksToBounds:YES];
    [image.layer setBorderColor:[UIColor whiteColor].CGColor];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return nil;
    else
        return NSLocalizedString(@"Third party software", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0)
		return 320;
    else if (indexPath.section == 1 && indexPath.row == 0)
		return 190;
    else
		return 44;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return 2;
	}
    else {
        return 2;
	}
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section)
    {
        case 0:
        {
            if (indexPath.row == 0)
                return cellCredit;
            else
                return cellWeb;
		}
            break;
        case 1:
        {
            if (indexPath.row == 0)
                return cellCreditLinphone;
            else
                return cellWebLinphone;
		}
            break;
        default:
            {
                
            }
            break;
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 1)
        return indexPath;
    else
        return nil;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {


	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
    if (indexPath.section == 0 && indexPath.row == 1){
			NSURL *url = [NSURL URLWithString:weburi.text];
			[[UIApplication sharedApplication] openURL:url];
			
    }
    else if (indexPath.section == 1 && indexPath.row == 1)
    {
        NSURL *url = [NSURL URLWithString:weburiLinphone.text];
        [[UIApplication sharedApplication] openURL:url];
        
    }
}

@end
