//
//  ControllClass.h
//  Haidy-House
//
//  Created by Jan Koranda on 8/17/12.
//
//

#import <Foundation/Foundation.h>

@interface ExNavigationData : NSObject

@property NSString *title;
@property NSString *url;
@property NSMutableArray *childs;

-(id) initWithTitle:(NSString*)aTitle Url:(NSString*)aUrl  Childs:(NSMutableArray*)aChilds;

@end
