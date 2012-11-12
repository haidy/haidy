//
//  PopupViewController.m
//  Haidy-House
//
//  Created by Jan Koranda on 8/6/12.
//
//


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#import "PopupViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ExNavigationData.h"
#import "NavigationRoomViewController.h"
#import "ExUtils.h"


@interface PopupViewController ()

-(void)parseJsonArray:(NSArray*)aJsonArray destinationArray:(NSMutableArray*)aDestinationArray;

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
    
    fNavigationArray = [NSMutableArray arrayWithCapacity:2];
    //nejprve přidáme první sekci
    [fNavigationArray addObject:[NSArray arrayWithObjects:[[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"PopupView Section 0 Row 0", @"Základní položky") Url:@"default.aspx" Childs:nil], [[ExNavigationData alloc] initWithTitle:NSLocalizedString(@"PopupView Section 0 Row 1", @"Ovládání hudby") Url:@"multiroomaudio.aspx" Childs:nil], nil ]];
    [fNavigationArray addObject:[NSMutableArray arrayWithObjects:nil ]];
    //pak přidáme druhou sekci, která bude zatím prázdná
    
    self.navigationRoomController = [[NavigationRoomViewController alloc] initWithStyle:UITableViewStylePlain];
    self.navigationRoomController.delegate = self;
    self.navigationRoomController.title = NSLocalizedString(@"Rooms", @"Titulek pro seznam místnosí");
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.navigationRoomController];
        self.popoverController.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
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

- (void)viewDidDisappear:(BOOL)animated{
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)loadJSONData{
    dispatch_async(kBgQueue, ^{
        NSError* error = nil;
        //jednodušší varianta, ale nejde ji parametrizovat
        //NSData* data = [NSData dataWithContentsOfURL:
                        //[NSURL URLWithString:@"http://sharpdev.asp2.cz/haidy/JSONDataExample.aspx"] options:NSDataReadingMappedIfSafe error:&error];
                        //[NSURL URLWithString:@"http://192.168.40.91/HaidySmartClient/MujDum/GetInformationForMobile.aspx"]]; //options:NSDataReadingUncached error:&error];
        
        //varianta přes NSURLConnection, se synchroním dotazem, protože jsme již v asynchroním makru
        //můžeme přidat hlavičky dotazu apod.
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[ExUtils constructUrlFromPage:@"GetInformationForMobile.aspx"]];
        [ExUtils setRequiredCookies:request];
        
        NSURLResponse *response = nil;
        NSMutableData *data = nil;
        data = (NSMutableData*)[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //ignorujeme chybu, kdy nedorazí data. Data nemusí dorazit kvůli neprovedené autentizaci
        if (error != nil)
            NSLog(@"Error loading data: %@", error);
        
        [self performSelectorOnMainThread:@selector(fetchedJSONData:) withObject:data waitUntilDone:YES];
    });
}

- (void)fetchedJSONData:(NSData*)responseData{
    NSLog(@"Response JSON data: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
    
    //připravíme si pole pro načtení dat a smažeme data stará
    NSMutableArray *mArrayFloors = (NSMutableArray*)[fNavigationArray objectAtIndex:1];
    [mArrayFloors removeAllObjects];
    
    //parse out the json data
    if (responseData.length == 0 ){
        NSLog(@"Nepřišla data k navigaci po podlažích");
        return;
    }
    
    NSError* error = nil;
    NSArray* mJsonArray = [NSJSONSerialization
                          JSONObjectWithData:responseData //1
                          
                          options:kNilOptions
                          error:&error];

    if (error != nil){
        NSLog(@"Error: %@", error);
        return;
    }
    
    [self parseJsonArray:mJsonArray destinationArray:mArrayFloors];
             
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [fNavigationArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [(NSMutableArray*)[fNavigationArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //získáme pole sekce
    NSMutableArray *mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
    //získáme třídu, ze které si vytáhneme potřebné informace
    ExNavigationData *mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [mControlClass title];
    
    if (mControlClass.childs.count > 0 ) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *mLocalizedStringKey = [NSString stringWithFormat:@"PopupView Section %i", section];
    return NSLocalizedString(mLocalizedStringKey, @"Název sekce");
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[DetailViewController alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    //získáme pole sekce
    NSMutableArray *mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
    //získáme třídu, ze které si vytáhneme potřebné informace
    ExNavigationData *mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
    NSLog(@"Selected url Popuview: %@", mControlClass.url);

    //uživatel si vybral co chce zobrazit a tak nastavíme URL a skryjeme popup
    [delegate selectWebPage:mControlClass.url];
    [delegate hidePopupView];
    
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{    
    //získáme pole sekce
    NSMutableArray *mSectionArray = [fNavigationArray objectAtIndex:indexPath.section];
    //získáme třídu, ze které si vytáhneme potřebné informace
    ExNavigationData *mControlClass = (ExNavigationData*)[mSectionArray objectAtIndex:indexPath.row];
    
    [navigationRoomController setNavigationArray:mControlClass.childs];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){         
        CGRect mCellRect = [self.tableView rectForRowAtIndexPath:indexPath];
        CGRect mPopoverRect = CGRectMake(mCellRect.origin.x, mCellRect.origin.y, mCellRect.size.width, 10);
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
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        [popoverController dismissPopoverAnimated:YES];
        
    }
    //else pro iPhone se zavolá jen hidePopupView a ten se postará o skrytí všeho. V hidePopupView se volá popup do rootového view
    [delegate hidePopupView];
   
}


@end
