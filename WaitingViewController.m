//
//  WaitingViewController2.m
//  Haidy-House
//
//  Created by Jan Koranda on 9/19/12.
//
//

#import "WaitingViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface WaitingViewController ()

@end

@implementation WaitingViewController

@synthesize fActivityView, fLabel;

+ (id)createWithParentView:(UIView *)aParentView{
    WaitingViewController *mWaitingViewController = [[WaitingViewController alloc] initWithNibName:@"WaitingViewController" bundle:nil];
    [mWaitingViewController.view setCenter:aParentView.center];
    [aParentView addSubview:mWaitingViewController.view];
    [aParentView bringSubviewToFront:mWaitingViewController.view];
    
    return mWaitingViewController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self.view setHidden:YES];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [fLabel setText:NSLocalizedString(@"Waiting", @"Titulek pro čekací dialog")];
    
    [self.view.layer setCornerRadius:5.0f];
    [self.view.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.view.layer setBorderWidth:3.0f];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) startWaiting
{
    [self.view setHidden:NO];
    [fActivityView startAnimating];
}

- (void) stopWaiting
{
    [self.view setHidden:YES];
    [fActivityView stopAnimating];
}

@end
