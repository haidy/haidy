//
//  ToogleSwitchCell.h
//  Haidy-House
//
//  Created by Jan Koranda on 11/7/12.
//
//

#import <UIKit/UIKit.h>

@interface SwitchCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *textLabel;
@property (nonatomic, retain) IBOutlet UISwitch *valueSwitch;

-(IBAction)valueChange:(UISwitch*)aSender;
@end
