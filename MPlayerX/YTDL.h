/*
 * MPlayerX - YTDL.h
 *
 * Copyright (C) 2009 - 2012, Zongyao QU
 * 
 * MPlayerX is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * MPlayerX is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with MPlayerX; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import <Foundation/Foundation.h>

#define kYTDLInfoTypeURL    (1)
#define kYTDLInfoTypeTitle  (2)

extern NSString * const kYTDLInfoContentKey;
extern NSString * const kYTDLInfoTypeKey;
extern NSString * const kYTDLInfoIsErrorKey;

@protocol YTDLDelegate
@required
-(void) ytdl:(id)obj gotInfo:(NSDictionary*)info;
@end

@interface YTDL : NSObject
{
    NSString *binPath;
    id<YTDLDelegate> delegate;
    
    NSOperationQueue *queue;
    NSInvocationOperation *currentOperation;
}
@property (assign) id<YTDLDelegate> delegate;

-(id) initWithBinPath:(NSString*)path;
-(void) getInfoFromURL:(NSString*)urlString type:(NSUInteger)type;
-(void) cancel;
@end
