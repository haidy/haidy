//
//  ToogleSwitchCell.m
//  Haidy-House
//
//  Created by Jan Koranda on 11/7/12.
//
//

#import "SwitchCell.h"

@implementation SwitchCell

@synthesize textLabel, valueSwitch;

/*- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}*/

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(IBAction)valueChange:(UISwitch *)aSender{
        
}

@end
