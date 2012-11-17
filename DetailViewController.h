//
//  SubWebViewController.h
//  Haidy House
//
//  Created by Jan Koranda on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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