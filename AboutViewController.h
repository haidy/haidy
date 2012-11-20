/* AboutViewController.h
 *
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

@interface AboutViewController : UITableViewController {

	
	UITableViewCell *cellCreditLinphone;
	UITableViewCell *cellWebLinphone;
	UILabel *weburiLinphone;
    
    UITextView *creditText;
    UITableViewCell *cellCredit;
	UITableViewCell *cellWeb;
	UILabel *weburi;
    UIImageView *image;
}

@property (nonatomic, retain) IBOutlet UITableViewCell* cellWebLinphone;
@property (nonatomic, retain) IBOutlet UITableViewCell* cellCreditLinphone;
@property (nonatomic, retain) IBOutlet UILabel *weburiLinphone;

@property (nonatomic, retain) IBOutlet UITableViewCell* cellWeb;
@property (nonatomic, retain) IBOutlet UITableViewCell* cellCredit;
@property (nonatomic, retain) IBOutlet UITextView *creditText;
@property (nonatomic, retain) IBOutlet UILabel *weburi;
@property (nonatomic, retain) IBOutlet UIImageView *image;

@end
