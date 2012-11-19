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
#import "ExUtils.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface ContactTableViewController ()
- (void)loadJSONData;
- (void)fetchedJSONData:(NSArray*)aSipArray;
@end



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


-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.view.layer setCornerRadius:0.0f];
    [self.view.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.view.layer setBorderWidth:2.0f];

    CGRect mRectViewForContact = fPhoneViewController.fViewForContact.frame;
    [self.view setFrame:CGRectMake(0, 0, mRectViewForContact.size.width, mRectViewForContact.size.height)];
    [fPhoneViewController.fViewForContact addSubview:self.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self loadJSONData];
}

- (void)setAdressField:(UITextField*)aAdressField {
    fAdressField = aAdressField;
}

static NSString* fPageForSipData = @"GetInformationForMobile.aspx?Method=GetSipInformation";

- (void)loadJSONData{
    dispatch_async(kBgQueue, ^{
        
        //očekáváme, že přijde pole, proto proměnná typu array
        NSArray* mJsonArray = [ExUtils getJsonDataWithPage:fPageForSipData];
        
        [self performSelectorOnMainThread:@selector(fetchedJSONData:) withObject:mJsonArray waitUntilDone:YES];
    });
}

- (void)fetchedJSONData:(NSArray*)aSipArray{
    if (aSipArray == nil)
        return; //nemáme data, není co dělat
                //else není potřeba, jde o zbytek kódu
    
    fSipContactsArray = [NSMutableArray arrayWithArray:aSipArray];
    //[fSipContactsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Testovací Haidy1", @"Name", @"haidy1", @"PhoneNumber", nil]];
    //[fSipContactsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys: @"Testovací Haidy2", @"Name", @"haidy2",@"PhoneNumber", nil]];
    
    
    NSString* localPhoneNumber = [[NSUserDefaults standardUserDefaults] stringForKey:@"username_preference"];
    
    if (localPhoneNumber != nil)
    {
        NSDictionary* mLocalDict = nil;
        for (NSDictionary* mSipContact in fSipContactsArray) {
            NSString* mSipContactPhoneNumber = [mSipContact objectForKey:@"PhoneNumber"];
            if ([localPhoneNumber caseInsensitiveCompare:mSipContactPhoneNumber] == NSOrderedSame )
            {
                mLocalDict = mSipContact;
                break;
            }
            //else není potřeba, hledáme konkrétní prvek
        }
        if (mLocalDict != nil)
            [fSipContactsArray removeObject:mLocalDict];
        //else - není co mazat
    }

    
    [self.tableView reloadData];
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (fSipContactsArray != nil)
        return fSipContactsArray.count;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* mContact = fSipContactsArray[indexPath.row];
    
    static NSString *CellIdentifier = @"CellIndetifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [mContact objectForKey:@"Name"];
    
    
    return cell;
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary* mContact = fSipContactsArray[indexPath.row];
    
    [fAdressField setText:[mContact objectForKey:@"PhoneNumber"]];
}

#pragma mark - Implement LinphoneUIContactDelegate
-(NSString *)getDisplayName:(NSString *)aNumber{
    for (NSDictionary* mSipContact in fSipContactsArray) {
        NSString* mSipContactPhoneNumber = [mSipContact objectForKey:@"PhoneNumber"];
        if ([mSipContactPhoneNumber caseInsensitiveCompare:aNumber] == NSOrderedSame )
            return [mSipContact objectForKey:@"Name"];
        //else není potřeba, hledáme konkrétní prvek
    }
    
    return nil;
}


@end
