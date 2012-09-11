//
//  TableViewNavigationViewController.h
//  Haidy-House
//
//  Created by Jan Koranda on 8/23/12.
//
//

#import <UIKit/UIKit.h>

@protocol NavigationRoomViewControllerDelegate

@required
- (void)navigationRoomViewControllerSelectWebPage:(NSString*)aWebPage;

@end

@interface NavigationRoomViewController : UITableViewController
{

}

@property (nonatomic, assign) id <NavigationRoomViewControllerDelegate> delegate;
@property (nonatomic, assign) NSMutableArray* navigationArray;

@end
