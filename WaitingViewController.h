//
//  WaitingViewController2.h
//  Haidy-House
//
//  Created by Jan Koranda on 9/19/12.
//
//

#import <UIKit/UIKit.h>

@interface WaitingViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *fActivityView;
@property (strong, nonatomic) IBOutlet UILabel *fLabel;

+(id)createWithParentView:(UIView*)aParentView;

-(void) startWaiting;
-(void) stopWaiting;

@end
