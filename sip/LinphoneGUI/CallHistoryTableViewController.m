/* CallHistoryTableViewController.m
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

#import "CallHistoryTableViewController.h"
#import "LinphoneManager.h"


@implementation CallHistoryTableViewController

@synthesize clear;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


- (void)viewDidLoad {
    [super viewDidLoad];
    
	UIBarButtonItem* clearButton = [[UIBarButtonItem alloc] 
									initWithBarButtonSystemItem:UIBarButtonSystemItemTrash 
									target:self 
									action:@selector(doAction:)]; 
	[self.navigationItem setRightBarButtonItem:clearButton];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


-(void) doAction:(id)sender {
	linphone_core_clear_call_logs([LinphoneManager getLc]);
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	const MSList * logs = linphone_core_get_call_logs([LinphoneManager getLc]);
	return ms_list_size(logs);
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		[cell.textLabel setTextColor:[UIColor colorWithRed:0.7 green:0.745 blue:0.78 alpha:1.0]];
        [cell.detailTextLabel setTextColor:cell.textLabel.textColor];
    }
    
    // Set up the cell...
	LinphoneAddress* partyToDisplay; 
	const MSList * logs = linphone_core_get_call_logs([LinphoneManager getLc]);
	LinphoneCallLog*  callLogs = ms_list_nth_data(logs,  indexPath.row) ;

	NSString *path;
	if (callLogs->dir == LinphoneCallIncoming) {
        if (callLogs->status == LinphoneCallSuccess) {
            path = [[NSBundle mainBundle] pathForResource:callLogs->video_enabled?@"in_call_video":@"in_call" ofType:@"png"];
        } else {
            //missed call
            path = [[NSBundle mainBundle] pathForResource:@"missed_call" ofType:@"png"];
        }
		partyToDisplay=callLogs->from;
		
	} else {
		path = [[NSBundle mainBundle] pathForResource:callLogs->video_enabled?@"out_call_video":@"out_call" ofType:@"png"];
		partyToDisplay=callLogs->to;
		
	}
	UIImage *image = [UIImage imageWithContentsOfFile:path];
	cell.imageView.image = image;
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	
	const char* username = linphone_address_get_username(partyToDisplay)!=0?linphone_address_get_username(partyToDisplay):"";
	const char* displayName = linphone_address_get_display_name(partyToDisplay);

	if (displayName) {
        NSString* str1 = [NSString stringWithFormat:@"%s", displayName];
		[cell.textLabel setText:str1];
        NSString* str2 = [NSString stringWithFormat:@"%s"/* [%s]"*/,username/*,callLogs->start_date*/];
		[cell.detailTextLabel setText:str2];
    } else {
        NSString* str1 = [NSString stringWithFormat:@"%s", username];
        [cell.textLabel setText:str1];
        [cell.detailTextLabel setText:nil];
    }
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	const MSList * logs = linphone_core_get_call_logs([LinphoneManager getLc]);
	LinphoneCallLog*  callLogs = ms_list_nth_data(logs,  indexPath.row) ;
	LinphoneAddress* partyToCall; 
	if (callLogs->dir == LinphoneCallIncoming) {
		partyToCall=callLogs->from;
		
	} else {
		partyToCall=callLogs->to;
		
	}
	const char* username = linphone_address_get_username(partyToCall)!=0?linphone_address_get_username(partyToCall):"";
	const char* domain = linphone_address_get_domain(partyToCall);
	
	LinphoneProxyConfig* proxyCfg;
	linphone_core_get_default_proxy([LinphoneManager getLc],&proxyCfg);
	
	NSString* phoneNumber;
	
	if (proxyCfg && (strcmp(domain, linphone_proxy_config_get_domain(proxyCfg)) == 0)) {
		phoneNumber = [[NSString alloc] initWithCString:username encoding:[NSString defaultCStringEncoding]];
	} else {
		phoneNumber = [[NSString alloc] initWithCString:linphone_address_as_string_uri_only(partyToCall) encoding:[NSString defaultCStringEncoding]];
	}
    
    LinphoneCallParams* lcallParams = linphone_core_create_default_call_parameters([LinphoneManager getLc]);

	linphone_core_invite_with_params([LinphoneManager getLc],[phoneNumber cStringUsingEncoding:[NSString defaultCStringEncoding]],lcallParams);
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



@end

