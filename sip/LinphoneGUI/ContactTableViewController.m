/* ContactTableViewController.h
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <QuartzCore/QuartzCore.h>
#import "ContactTableViewController.h"

//Třída zajišťuje zobrazení tableview s kontakty. Po výběru kontaktu, kliknutím na řádek tabulky, se kontakt vyplní do adresního řádku a uživatel může vytočit hovor.
@implementation ContactTableViewController

@synthesize fPhoneViewController;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
 
*/

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.view.layer setCornerRadius:0.0f];
    [self.view.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.view.layer setBorderWidth:2.0f];

    CGRect mRectViewForContact = fPhoneViewController.fViewForContact.frame;
    [self.view setFrame:CGRectMake(0, 0, mRectViewForContact.size.width, mRectViewForContact.size.height)];
    [fPhoneViewController.fViewForContact addSubview:self.view];
}

- (void)setAdressField:(UITextField*)aAdressField {
    fAdressField = aAdressField;
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = @"Testovací uživatel";
    
    
    return cell;
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [fAdressField setText:@"haidy2"];
}

@end
