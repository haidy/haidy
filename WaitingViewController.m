//
//  WaitingViewController2.m
//  Haidy-House
//
//  Created by Jan Koranda on 9/19/12.
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
    [self.view.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.view.layer setBorderWidth:1.5f];
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
