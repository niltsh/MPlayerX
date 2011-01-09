/*
 * MPlayerX - CoreController.h
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
#import "coredef.h"
#import "PlayerCore.h"
#import "ParameterManager.h"
#import "LogAnalyzer.h"

@class LogAnalyzer, ParameterManager, MovieInfo, PlayerCore, SubConverter;

@interface CoreController : NSObject <PlayerCoreDelegate, LogAnalyzerDelegate>
{
	// state
	int state;

	// basic components
	MovieInfo *movieInfo;
	LogAnalyzer *la;
	ParameterManager *pm;
	PlayerCore *playerCore;
	NSDictionary *mpPathPair;
	SubConverter *subConv;

	// render things
	void *imageData;
	unsigned int imageSize;
	NSString *sharedBufferName;
	NSConnection *renderConn;

	// delegates
	id<CoreDisplayDelegate> dispDelegate;
	id<CoreControllerDelegate> delegate;
	
	NSTimer *pollingTimer;
	
	NSDictionary *keyPathDict;
	NSDictionary *typeDict;
}

@property (readonly)			int state;
@property (retain, readwrite, nonatomic)	NSDictionary *mpPathPair;
@property (readonly)			MovieInfo *movieInfo;
@property (retain, readwrite)	ParameterManager *pm;
@property (readonly)			LogAnalyzer *la;
@property (assign, readwrite)	id<CoreDisplayDelegate> dispDelegate;
@property (assign, readwrite)	id<CoreControllerDelegate> delegate;

-(void) setSubConverterDelegate:(id<SubConverterDelegate>)dlgt;

-(void) setWorkDirectory:(NSString*) wd;

-(void) playMedia:(NSString*)moviePath;
-(void) performStop;
-(void) togglePause;

-(void) frameStep:(NSInteger)frameNum;

/** 成功发送的话，playingInfo的speed属性会被更新 */
-(void) setSpeed: (float) speed;

/** 成功发送的话，playingInfo的currentChapter属性会被更新 */
-(void) setChapter: (int) chapter;

/** 返回设定的时间值，如果是-1，那说明没有成功发送，但是即使成功发送了，也不会更新playingInfo的currentTime属性，
 *  这个属性会在单独的线程更新，需要用KVO来获取
 *  time 在相对模式时为delta，绝对模式时为目的时间
 */
-(float) setTimePos:(float)time mode:(SEEK_MODE)seekMode;

/** 成功发送的话，playingInfo的volume属性会被更新,返回能够被更新的正确值 */
-(float) setVolume: (float) vol;

/** 成功发送的话，playingInfo的audioBalance属性会被更新 */
-(void) setBalance: (float) bal;

/** 成功发送的话，playingInfo的mute属性会被更新 */
-(BOOL) setMute: (BOOL) mute;

-(void) setAudioDelay: (float) delay;

-(void) setAudio: (int) audioID;

-(void) setVideo: (int) videoID;

-(void) setSub: (int) subID;

/** 成功发送的话，playingInfo的subDelay属性会被更新 */
-(void) setSubDelay: (float) delay;

/** 成功发送的话，playingInfo的subPos属性会被更新 */
-(void) setSubPos: (float) pos;

/** 成功发送的话，playingInfo的subScale属性会被更新 */
-(void) setSubScale: (float) scale;

-(void) loadSubFile: (NSString*) path;

-(void) setLetterBox:(BOOL) renderSubInLB top:(float) topRatio bottom:(float)bottomRatio;

-(void) setEqualizer:(NSArray*)amps;

-(void) mapAudioChannelsTo:(NSInteger) chDst;

@end
