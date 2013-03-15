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
#import "JsonService.h"
#import "ExUtils.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface ContactTableViewController ()
- (void)loadContacts;
- (void)fetchedContacts:(NSArray*)aSipArray;
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

    CGRect mRectViewForContact = fPhoneViewController.fViewForContact.frame;
    if ([ExUtils runningOnIpad])
        [self.view setFrame:CGRectMake(20, 20, mRectViewForContact.size.width-40, mRectViewForContact.size.height-40)];
    else
        [self.view setFrame:CGRectMake(0, 0, mRectViewForContact.size.width, mRectViewForContact.size.height)];
    [fPhoneViewController.fViewForContact addSubview:self.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self loadContacts];
}

- (void)setAdressField:(UITextField*)aAdressField {
    fAdressField = aAdressField;
}

- (void)loadContacts{
    dispatch_async(kBgQueue, ^{
        
        //očekáváme, že přijde pole, proto proměnná typu array
        NSArray* mJsonArray = [JsonService getSipContacts];
        
        [self performSelectorOnMainThread:@selector(fetchedContacts:) withObject:mJsonArray waitUntilDone:YES];
    });
}

- (void)fetchedContacts:(NSArray*)aSipArray{
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
    
    [fSipContactsArray sortUsingComparator:^NSComparisonResult(id aLeft, id aRight) {
        NSString *mNameLeft = [(NSDictionary*)aLeft objectForKey:@"Name"];
        NSString *mNameRight = [(NSDictionary*)aRight objectForKey:@"Name"];
        
        return (NSComparisonResult)[mNameLeft localizedCaseInsensitiveCompare:mNameRight];
    }];
    
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
    cell.textLabel.textColor = [UIColor whiteColor];
    
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
