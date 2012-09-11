//
//  ControllClass.m
//  Haidy-House
//
//  Created by Jan Koranda on 8/17/12.
//
//

#import "ExNavigationData.h"

@implementation ExNavigationData

@synthesize title, url, childs;

-(id) initWithTitle:(NSString*)aTitle Url:(NSString*)aUrl  Childs:(NSMutableArray*)aChilds{
    [self setTitle:aTitle];
    [self setUrl:aUrl];
    [self setChilds:aChilds];
    
    return self;
}

@end
