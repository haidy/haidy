//
//  DetailViewController.h
//  Haidy House
//
//  Created by Jan Koranda on 6/18/12.
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

#import <UIKit/UIKit.h>

@protocol DetailViewControllerDelegate

@required
- (void)detailViewControllerDidFinish:(id)controller andError:(BOOL)mError;
@end


@interface DetailViewController : UIViewController
{

}
@property (strong, nonatomic) IBOutlet UIWebView *fWebView;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (nonatomic, assign) id <DetailViewControllerDelegate> delegate;


- (void) loadPage:(NSURLRequest*)urlRequest;
@end