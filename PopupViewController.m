//
//  PopupViewController.m
//  Haidy-House
//
//  Created by Jan Koranda on 8/6/12.
//
//

#import "PopupViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ExNavigationData.h"
#import "NavigationRoomViewController.h"
#import "ExUtils.h"
#import "SwitchCell.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface PopupViewController ()

-(void)parseJsonArray:(NSArray*)aJsonArray destinationArray:(NSMutableArray*)aDestinationArray;
-(void)initDataForMenu;
@end

@implementation PopupViewController

@synthesize delegate, popoverController, navigationRoomController;


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
    
    isUseSip = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseSIP"];
    
    [self initDataForMenu];
    
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
    if (isUseSip != [[NSUserDefaults standardUserDefaults] boolForKey:@"UseSIP"])
    {
        isUseSip = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseSIP"];
        [self initDataForMenu];
        [self.tableView reloadData];
    }
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
-(void)initDataForMenu{
    fNavigationArray = nil;
    fNavigationArray = [NSMutableArray arrayWithCapacity:2];
    //nejprve vytvoříme první sekci
    NSMutableArray *mFirstSection = [NSMutableArray arrayWithObjects:[[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"PopupView Section 0 Row 0", @"Základní položky") Url:@"default.aspx" Childs:nil], [[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"PopupView Section 0 Row 1", @"Ovládání hudby") Url:@"multiroomaudio.aspx" Childs:nil], nil ];
    
    if (isUseSip)
        [mFirstSection addObject:[[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"PopupView Section 0 Row 2", @"Sip") Url:nil Childs:nil]];
    //přidáme první sekci do seznamu
    [fNavigationArray addObject:mFirstSection];
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
        return 2;
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
                    mSwitchCell.valueSwitch.selected = [ExUtils inHome];
                    [mSwitchCell.valueSwitch addTarget:self action:@selector(inHomeChanged:) forControlEvents:UIControlEventValueChanged];
                }
                    break;
                case 1:
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
    if (indexPath.section == 2 && indexPath.row == 0)
        return nil;
    else
        return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < 2)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        //získáme pole sekce
        NSMutableArray *mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
        //získáme třídu, ze které si vytáhneme potřebné informace
        ExNavigationData *mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
        NSLog(@"Selected url Popuview: %@", mControlClass.url);

        //uživatel si vybral co chce zobrazit a tak nastavíme URL a skryjeme popup
        if (mControlClass.url != nil)
            [delegate selectWebPage:mControlClass.url];
        else
            [delegate selectSip];
    }
    else if (indexPath.section == 2)
    {
        
    }
    //[delegate hidePopupView] - nyní se volá z webview, jako následek výběru stránky;
    
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
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
    [ExUtils setInHome:aSender.selected];
}

@end
