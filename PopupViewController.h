//
//  PopupViewController.h
//  Haidy-House
//
//  Created by Jan Koranda on 8/6/12./Users/jankoranda/Documents/Projekty/Haidy House/Haidy House/PopupViewController.h
//
//

#import <UIKit/UIKit.h>
#import "NavigationRoomViewController.h"

@protocol PopupViewControllerDelegate

@required
- (void)selectWebPage:(NSString*)aPage;
- (void)selectSip;
- (void)hidePopupView;
@end

@interface PopupViewController : UITableViewController <UIPopoverControllerDelegate, NavigationRoomViewControllerDelegate>
{
    UIViewController *fTemporaryView;
    NSMutableArray *fNavigationArray;
@private BOOL isUseSip;
}

@property (nonatomic, assign) id <PopupViewControllerDelegate> delegate;
@property (nonatomic, retain) UIPopoverController* popoverController;
@property (nonatomic, retain) NavigationRoomViewController* navigationRoomController;

- (IBAction) handleSwipeLeft:(UISwipeGestureRecognizer*)sender;
- (void) loadJSONData;
- (void) fetchedJSONData:(NSData*)responseData;

@end
