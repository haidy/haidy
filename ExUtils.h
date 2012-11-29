//
//  ExUtils.h
//  Haidy-House
//
//  Created by Jan Koranda on 8/24/12.
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

#import <Foundation/Foundation.h>

@interface ExUtils : NSObject
{
 
}

+(NSURL*) constructUrlFromPage:(NSString*)aPage;
+(BOOL) inHome;
+(void) setInHome:(BOOL)aInHome;
+(BOOL) useSip;
+(void) setUseSip:(BOOL)aUseSip;
+(NSURL*) blankPage;
+(BOOL) setRequiredRequestParams:(NSURLRequest*)aRequest;
+(void) setRequiredCookies:(NSURLRequest*)aRequest;
+(void) handlingErrorCode102WithWebKitErrorDomain:(NSString*)aLoadedUrl;
+(BOOL) runningOnIpad;
+(void) initRemoteServerSessions:(NSArray*)aRemoteServerSessions;

@end
