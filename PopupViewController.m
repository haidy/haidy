//
//  PopupViewController.m
//  Haidy-House
//
//  Created by Jan Koranda on 8/6/12.
/*
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

#import "PopupViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ExNavigationData.h"
#import "NavigationRoomViewController.h"
#import "ExUtils.h"
#import "SwitchCell.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface PopupViewController ()

-(void)parseJsonArray:(NSArray*)aJsonArray destinationArray:(NSMutableArray*)aDestinationArray;
-(BOOL)initDataForMenu;
@end

@implementation PopupViewController

@synthesize delegate, popoverController, navigationRoomController;

static ExNavigationData *fSipNavigationData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Control", @"Titulek pro ovládání");
        //self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    
    self.navigationRoomController = [[NavigationRoomViewController alloc] initWithStyle:UITableViewStylePlain];
    self.navigationRoomController.delegate = self;
    self.navigationRoomController.title = NSLocalizedString(@"Rooms", @"Titulek pro seznam místnosí");
    
    if ([ExUtils runningOnIpad])
    {
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.navigationRoomController];
        self.popoverController.delegate = self;
    }
    
    fSipNavigationData = [[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"SIP", @"Sip") Url:nil Childs:nil];

    (void)[self initDataForMenu];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if ([ExUtils runningOnIpad])
    {
        [self.view.layer setCornerRadius:5.0f];
        [self.view.layer setBorderColor:[UIColor blackColor].CGColor];
        [self.view.layer setBorderWidth:3.0f];
        [self.tableView setScrollEnabled:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([self initDataForMenu])
        [self.tableView reloadData];
    //else se nic neděje, 
}

- (void)viewDidDisappear:(BOOL)animated{
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

static NSString* fPageForFloorsData = @"GetInformationForMobile.aspx?Method=GetFloorsInformation";

- (void)loadJSONData{
    dispatch_async(kBgQueue, ^{
            
        //očekáváme, že přijde pole, proto proměnná typu array
        NSArray* mJsonArray = [ExUtils getJsonDataWithPage:fPageForFloorsData];
        
        [self performSelectorOnMainThread:@selector(fetchedJSONData:) withObject:mJsonArray waitUntilDone:YES];
        });
}

- (void)fetchedJSONData:(NSArray*)aFloorsArray{
    //připravíme si pole pro načtení dat a smažeme data stará
    //data smažeme, i když nic nepřijde, protože je možné, že došlo k odhlášení
    
    if (aFloorsArray == nil)
    {
        //nemáme data, pokud již byly načteny informace o patrech, tak je smažeme a zobrazíme zneplatníme data tabulky
        if ([fNavigationArray count] == 2)
            [fNavigationArray removeObjectAtIndex:1];
        //else data nebyla načtena, nic nedělám
        [self.tableView reloadData];
        return; 
    }
    //else není potřeba, jde o zbytek kódu
    
    NSMutableArray *mArrayFloors = nil;
    if ([fNavigationArray count] == 2)
    {
        //existuje pole pater, tak jen promažeme jeho obsah
        mArrayFloors = (NSMutableArray*)[fNavigationArray objectAtIndex:1];
        [mArrayFloors removeAllObjects];
    }
    else
    {
        //pole pater neexistuje, tak ho založíme
        mArrayFloors = [NSMutableArray arrayWithCapacity:0];
        [fNavigationArray addObject:mArrayFloors];
    }
    
    [self parseJsonArray:aFloorsArray destinationArray:mArrayFloors];
             
    [self.tableView reloadData];
}

-(void)parseJsonArray:(NSArray*)aJsonArray destinationArray:(NSMutableArray *)aDestinationArray{
    for(NSDictionary *mJsonDictionary in aJsonArray)
    {
        NSString *title = [mJsonDictionary objectForKey:@"Title"];
        NSString *url = [mJsonDictionary objectForKey:@"Url"];
        NSMutableArray *mChildrenArray = nil;
        if ([mJsonDictionary objectForKey:@"Children"] != [NSNull null]){
            NSLog(@"Children: %i", [[mJsonDictionary objectForKey:@"Children"] count]);

            mChildrenArray = [NSMutableArray arrayWithCapacity:1];
            [self parseJsonArray:[mJsonDictionary objectForKey:@"Children"] destinationArray:mChildrenArray];
        }
        
        
        [aDestinationArray addObject:[[ExNavigationData alloc] initWithTitle:title Url:url Childs:mChildrenArray]];
    }

}

//Inicializuje pole fNavigationArray, ze kterého se následně zkonstruje zobrazená tabulka
-(BOOL)initDataForMenu{
    BOOL mChanged = NO;
    if (fNavigationArray == nil)
    {
        fNavigationArray = [NSMutableArray arrayWithCapacity:2];
        //nejprve vytvoříme první sekci
        [fNavigationArray addObject:[NSMutableArray arrayWithObjects:[[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"PopupView Section 0 Row 0", @"Základní položky") Url:@"default.aspx" Childs:nil], [[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"PopupView Section 0 Row 1", @"Ovládání hudby") Url:@"multiroomaudio.aspx" Childs:nil], nil ]];
        mChanged = YES;
    }
    NSMutableArray *mFirstSection = [fNavigationArray objectAtIndex:0];
    
    if ([ExUtils useSip])
    {
        if (![mFirstSection containsObject:fSipNavigationData])
        {
            [mFirstSection addObject:fSipNavigationData];
            mChanged = true;
        }
        //else - objekt je nic neřešíme
    }
    else
    {
        if ([mFirstSection containsObject:fSipNavigationData])
        {
            [mFirstSection removeObject:fSipNavigationData];
            mChanged = true;
        }
        //else - objekt není nic neřešíme
    }
    
    return mChanged;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [fNavigationArray count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section < [fNavigationArray count])
        return [(NSMutableArray*)[fNavigationArray objectAtIndex:section] count];
    else //poslední sekci definujeme kompletně ručně
        return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = nil;

    NSMutableArray *mSectionArray = nil;
    ExNavigationData *mControlClass = nil;
    
    if (indexPath.section == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil){
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            //získáme pole sekce
            mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
            //získáme třídu, ze které si vytáhneme potřebné informace
            mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
            cell.textLabel.text = [mControlClass title];
        
            if (indexPath.row == 2)
            {
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
    }
    else if (indexPath.section == 1 && [fNavigationArray count] == 2)
    {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (cell == nil){
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            //získáme pole sekce
            mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
            //získáme třídu, ze které si vytáhneme potřebné informace
            mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
            cell.textLabel.text = [mControlClass title];
            
        
            if (mControlClass.childs != nil && mControlClass.childs.count > 0 ) {
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            }
    }
    else{
            switch(indexPath.row)
            {
                case 0:
                {
                    static NSString *mSwitchCellIndetifier = @"SwitchCell";
                    cell = [tableView dequeueReusableCellWithIdentifier:mSwitchCellIndetifier];
                    if (cell == nil){
                        UINib *mTmpNib = [UINib nibWithNibName:@"CellDefinitions" bundle:nil];
                        [tableView registerNib:mTmpNib forCellReuseIdentifier:mSwitchCellIndetifier];
                       cell = [tableView dequeueReusableCellWithIdentifier:mSwitchCellIndetifier];
                    }
                    SwitchCell *mSwitchCell = (SwitchCell*)cell;
                    mSwitchCell.textLabel.text = NSLocalizedString(@"I'm home",nil);
                    mSwitchCell.valueSwitch.on = [ExUtils inHome];
                    [mSwitchCell.valueSwitch addTarget:self action:@selector(inHomeChanged:) forControlEvents:UIControlEventValueChanged];
                }
                    break;
                case 1:
                {
                    static NSString *mSwitchCellIndetifier = @"SwitchCell";
                    cell = [tableView dequeueReusableCellWithIdentifier:mSwitchCellIndetifier];
                    if (cell == nil){
                        UINib *mTmpNib = [UINib nibWithNibName:@"CellDefinitions" bundle:nil];
                        [tableView registerNib:mTmpNib forCellReuseIdentifier:mSwitchCellIndetifier];
                        cell = [tableView dequeueReusableCellWithIdentifier:mSwitchCellIndetifier];
                    }
                    SwitchCell *mSwitchCell = (SwitchCell*)cell;
                    mSwitchCell.textLabel.text = NSLocalizedString(@"UseSIP",nil);
                    mSwitchCell.valueSwitch.on = [ExUtils useSip];
                    [mSwitchCell.valueSwitch addTarget:self action:@selector(useSipChanged:) forControlEvents:UIControlEventValueChanged];

                }
                    break;
                case 2:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    
                    if (cell == nil){
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                    }
                    cell.textLabel.text = NSLocalizedString(@"About", nil);
                    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                }
                    break;
            }
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)aSection {
    if ([fNavigationArray count] != 2 && aSection == 1)
        aSection = 2;
    
    NSString *mLocalizedStringKey = [NSString stringWithFormat:@"PopupView Section %i", aSection];
    return NSLocalizedString(mLocalizedStringKey, @"Název sekce");
}


#pragma mark - Table view delegate

//omezení selekce/výběru řádků
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == fNavigationArray.count && indexPath.row < 2)
        return nil;
    else
        return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 2)
        [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    else if (indexPath.section == fNavigationArray.count && indexPath.row == 2)
        [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];

    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        //získáme pole sekce
        NSMutableArray *mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
        //získáme třídu, ze které si vytáhneme potřebné informace
        ExNavigationData *mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
        NSLog(@"Selected url Popuview: %@", mControlClass.url);

        //uživatel si vybral co chce zobrazit a tak nastavíme URL a skryjeme popup
        [delegate selectWebPage:mControlClass.url];
           
        //[delegate hidePopupView] - nyní se volá z webview, jako následek výběru stránky;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 )
        [delegate selectSip];
    else if (indexPath.section == 1 && (fNavigationArray.count+1) == 3)
    {
        //získáme pole sekce
        NSMutableArray *mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
        //získáme třídu, ze které si vytáhneme potřebné informace
        ExNavigationData *mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
        
        [navigationRoomController setNavigationArray:mControlClass.childs];
        
        if ([ExUtils runningOnIpad]){
            CGRect mCellRect = [self.tableView rectForRowAtIndexPath:indexPath];
            CGRect mPopoverRect = CGRectMake(mCellRect.origin.x, mCellRect.origin.y, mCellRect.size.width, 10);
            
            CGSize size = CGSizeMake(320, [mControlClass.childs count]*44);
            [self.popoverController setPopoverContentSize:size];
            [self.popoverController presentPopoverFromRect:mPopoverRect inView:self.view.superview permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        }
        else{
            [self.navigationController pushViewController:navigationRoomController animated:YES];
        }
    }
    else
    {
        [delegate selectAbout];
    }
    
}

#pragma mark - Impement Gesture recognize
- (IBAction) handleSwipeLeft:(UISwipeGestureRecognizer*)sender
{
    //swipe left znamená skrytí popupview, zavoláme proto delegáta, aby okno skryl
    [delegate hidePopupView];
}

#pragma mark - Implement Popover delegate
//---called when the user clicks outside the popover view---
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    
    NSLog(@"popover about to be dismissed");
    return YES;
}

//---called when the popover view is dismissed---
- (void)popoverControllerDidDismissPopover:
(UIPopoverController *)popoverController {
    
    NSLog(@"popover dismissed");
}

#pragma mark - Implement NavigationViewControllerDelegate
-(void)navigationRoomViewControllerSelectWebPage:(NSString *)aWebPage{
    //uživatel vybral stránku, takže požádáme o její zobrazení
    //skryjeme popover a skryjeme i popup
    [delegate selectWebPage:aWebPage];
    if ([ExUtils runningOnIpad])
    {
        [popoverController dismissPopoverAnimated:YES];
        
    }
    //else pro iPhone se zavolá jen hidePopupView a ten se postará o skrytí všeho. V hidePopupView se volá popup do rootového view
    //[delegate hidePopupView];
   
}

#pragma Hook Events
- (void)inHomeChanged:(UISwitch*)aSender{
    [ExUtils setInHome:aSender.isOn];
    [self loadJSONData];
}

- (void)useSipChanged:(UISwitch*)aSender{
    [ExUtils setUseSip:aSender.isOn];
    if ([self initDataForMenu])
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

@end
