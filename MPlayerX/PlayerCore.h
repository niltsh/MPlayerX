/*
 * MPlayerX - PlayerCore.h
 *
 * Copyright (C) 2009 Zongyao QU
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

#import <Cocoa/Cocoa.h>

// 如果需要与Task通信通过该接口
@protocol PlayerCoreDelegate
-(void) playerCore:(id)player hasTerminated:(BOOL) byForce;			/**< 通知播放任务结束 */
-(void) playerCore:(id)player outputAvailable:(NSData*)outData;		/**< 有输出 */
-(void) playerCore:(id)player errorHappened:(NSData*) errData;		/**< 有错误输出 */
@end

@interface PlayerCore : NSObject
{
	id<PlayerCoreDelegate> delegate;

	NSTask *task;
	NSArray *runningModes;
}

@property (assign, readwrite) id<PlayerCoreDelegate> delegate;

-(void) terminate;
-(BOOL) playMedia:(NSString*)moviePath withExec:(NSString*)execPath withParams:(NSArray*)params;
-(BOOL) sendStringCommand:(NSString*)cmd;

@end
