//
//  TableViewNavigationViewController.m
//  Haidy-House
//
//  Created by Jan Koranda on 8/23/12.
//
//

#import "NavigationRoomViewController.h"
#import "ExNavigationData.h"

@interface NavigationRoomViewController ()

@end

@implementation NavigationRoomViewController

@synthesize delegate, navigationArray;


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [navigationArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //získáme třídu, ze které si vytáhneme potřebné informace
    ExNavigationData *mControlClass = (ExNavigationData*)[navigationArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [mControlClass title];
    
    if (mControlClass.childs.count > 0 ) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //získáme třídu, ze které si vytáhneme potřebné informace
    ExNavigationData *mControlClass = (ExNavigationData*)[navigationArray objectAtIndex:indexPath.row];
    //oznámíme delegátovi, že jsme již vybrali hodnotu
    [delegate navigationRoomViewControllerSelectWebPage:mControlClass.url];
}

@end
