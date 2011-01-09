/*
 * MPlayerX - CoreController.m
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

#import "CoreController.h"
#import <sys/mman.h>
#import "CocoaAppendix.h"
#import "MovieInfo.h"
#import "SubConverter.h"

#define kPollingTimeForTimePos	(1)

#define kMITypeNoProc		(0)
#define kMITypeFlatValue	(1)
#define kMITypeSubArray		(2)
#define kMITypeSubAppend	(3)
#define kMITypeStateChanged	(4)
#define kMITypeVideoGotInfo	(5)
#define kMITypeAudioGotInfo	(6)
#define kMITypeAudioGotID	(7)
#define kMITypeVideoGotID	(8)

NSString * const kMPCPlayStoppedByForceKey		= @"kMPCPlayStoppedByForceKey";
NSString * const kMPCPlayStoppedTimeKey			= @"kMPCPlayStoppedTimeKey";

NSString * const kCmdStringFMTFloat		= @"%@ %@ %f\n";
NSString * const kCmdStringFMTInteger	= @"%@ %@ %d\n";
NSString * const kCmdStringFMTTimeSeek	= @"%@ %@ %f %d\n";

#define SAFERELEASETIMER(x)		{if(x) {[x invalidate]; [x release]; x = nil;}}

// the Distant Protocol from mplayer binary
@protocol MPlayerOSXVOProto
-(int) startWithWidth:(bycopy NSUInteger)width withHeight:(bycopy NSUInteger)height withPixelFormat:(bycopy OSType)pixelFormat withAspect:(bycopy float)aspect;
-(void) stop;
-(void) render:(bycopy NSUInteger)frameNum;
-(void) toggleFullscreen;
-(void) ontop;
@end

/// 内部方法声明
@interface CoreController (MPlayerOSXVOProto)
-(int) startWithWidth:(bycopy NSUInteger)width withHeight:(bycopy NSUInteger)height withPixelFormat:(bycopy OSType)pixelFormat withAspect:(bycopy float)aspect;
-(void) stop;
-(void) render:(bycopy NSUInteger)frameNum;
-(void) toggleFullscreen;
-(void) ontop;
@end

@interface CoreController (LogAnalyzerDelegate)
-(void) logAnalyzeFinished:(NSDictionary*)dict;
@end

@interface CoreController (PlayerCoreDelegate)
-(void) playerCore:(id)player hasTerminated:(BOOL)byForce;			/**< 通知播放任务结束 */
-(void) playerCore:(id)player outputAvailable:(NSData*)outData;		/**< 有输出 */
-(void) playerCore:(id)player errorHappened:(NSData*) errData;		/**< 有错误输出 */
@end

@interface CoreController (CoreControllerInternal)
-(void) getCurrentTime:(NSTimer*)theTimer;
@end

@implementation CoreController

@synthesize state;
@synthesize dispDelegate;
@synthesize pm;
@synthesize movieInfo;
@synthesize mpPathPair;
@synthesize la;
@synthesize delegate;

///////////////////////////////////////////Init/Dealloc////////////////////////////////////////////////////////
-(id) init
{
	self = [super init];
	
	if (self) {
		NSNumber *flatValue = [NSNumber numberWithInt:kMITypeFlatValue];
		
		keyPathDict = [[NSDictionary alloc] initWithObjectsAndKeys:	kKVOPropertyKeyPathCurrentTime, kMPCTimePos, 
																	kKVOPropertyKeyPathLength, kMPCLengthID,
																	kKVOPropertyKeyPathSeekable, kMPCSeekableID,
																	kKVOPropertyKeyPathSubInfo, kMPCSubInfosID,
																	kKVOPropertyKeyPathSubInfo, kMPCSubInfoAppendID,
																	kKVOPropertyKeyPathCachingPercent, kMPCCachingPercentID,
																	kKVOPropertyKeyPathState, kMPCPlayBackStartedID,
																	kKVOPropertyKeyPathVideoInfo, kMPCVideoInfoID,
																	kKVOPropertyKeyPathAudioInfo, kMPCAudioInfoID,
																	kKVOPropertyKeyPathAudioInfo, kMPCAudioIDs,
																	kKVOPropertyKeyPathVideoInfo, kMPCVideoIDs,
																	kKVOPropertyKeyPathDemuxer, kMPCDemuxerID,
																	nil];
		typeDict = [[NSDictionary alloc] initWithObjectsAndKeys:flatValue, kMPCTimePos, 
																flatValue, kMPCLengthID,
																flatValue, kMPCSeekableID,
																[NSNumber numberWithInt:kMITypeSubArray], kMPCSubInfosID,
																[NSNumber numberWithInt:kMITypeSubAppend], kMPCSubInfoAppendID,
																flatValue, kMPCCachingPercentID,
																[NSNumber numberWithInt:kMITypeStateChanged], kMPCPlayBackStartedID,
																[NSNumber numberWithInt:kMITypeVideoGotInfo], kMPCVideoInfoID,
																[NSNumber numberWithInt:kMITypeAudioGotInfo], kMPCAudioInfoID,
																[NSNumber numberWithInt:kMITypeAudioGotID], kMPCAudioIDs,
																[NSNumber numberWithInt:kMITypeVideoGotID], kMPCVideoIDs,
																flatValue, kMPCDemuxerID,
																nil];
		dispDelegate = nil;
		delegate = nil;
		
		state = kMPCStoppedState;
		
		pm = [[ParameterManager alloc] init];
		movieInfo = [[MovieInfo alloc] init];

		la = [[LogAnalyzer alloc] initWithDelegate:self];
		[movieInfo resetWithParameterManager:pm];
		
		subConv = [[SubConverter alloc] init];
		
		playerCore = [[PlayerCore alloc] init];
		[playerCore setDelegate:self];
		mpPathPair = nil;

		imageData = NULL;
		imageSize = 0;
		sharedBufferName = [[NSString alloc] initWithFormat:@"MPlayerX_%X", self];
		renderConn = [[NSConnection serviceConnectionWithName:sharedBufferName rootObject:self] retain];
		[renderConn runInNewThread];
		
		pollingTimer = nil;
	}
	return self;
}

-(void) setMpPathPair:(NSDictionary *) dict
{
	if (dict) {
		if ([dict objectForKey:kI386Key] && [dict objectForKey:kX86_64Key]) {
			[dict retain];
			[mpPathPair release];
			mpPathPair = dict;
		}
	} else {
		[mpPathPair release];
		mpPathPair = nil;
	}
}

-(void) dealloc
{
	delegate = nil;

	[renderConn release];
	[keyPathDict release];
	[typeDict release];

	[movieInfo release];
	[la release];
	[pm release];
	[playerCore release];
	[mpPathPair release];
	[sharedBufferName release];
	SAFERELEASETIMER(pollingTimer);
	[subConv release];

	[super dealloc];
}

//////////////////////////////////////////////Hack to get communicate with mplayer/////////////////////////////////////////////
-(BOOL) conformsToProtocol:(Protocol *)aProtocol
{
	if (aProtocol == @protocol(MPlayerOSXVOProto)) {
		return YES;
	}
	return [super conformsToProtocol: aProtocol];
}

//////////////////////////////////////////////comunication with playerCore/////////////////////////////////////////////////////
-(void) playerCore:(id)player hasTerminated:(BOOL) byForce
{
	// if mplayer is crashed, it may not call stop to stop display
	// and stop always happens before mplayer really exit
	// so imageData is there means stop is forgotten
	if (imageData) {
		[self stop];
	}
	
	if (delegate) {
		[delegate playebackWillStop];
	}
	state = kMPCStoppedState;

	SAFERELEASETIMER(pollingTimer);
	[la stop];
	[subConv clearWorkDirectory];

	// 在这里重置textSubs和vobSub，这样在下次播放之前，用户可以自己设置这两个元素
	// !!! 但是要注意，如果是在播放过程中直接调用playMedia函数进行下一个播放的时候
	// !!! 由于playMedia函数会先停止播放，这样会导致sub被清空，在手动选择sub的情况下这里会出现无法手动加载的情况
	// !!! 解决方法是，在CoreController正确先调用performStop在playMedia
	[pm reset];
	
	// 只重置与播放无关的东西
	[movieInfo resetWithParameterManager:nil];

	if (delegate) {
		[delegate playebackStopped:[NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:byForce], kMPCPlayStoppedByForceKey,
									[movieInfo.playingInfo currentTime], kMPCPlayStoppedTimeKey, nil]];
	}
	MPLog(@"terminated:%d", byForce);
}

- (void) playerCore:(id)player outputAvailable:(NSData*)outData
{
	[la analyzeData:outData];
}

- (void) playerCore:(id)player errorHappened:(NSData*) errData
{
	NSString *log = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
	
	MPLog(@"ERR:%@", log);
	[log release];
}

//////////////////////////////////////////////protocol for render/////////////////////////////////////////////////////
-(int) startWithWidth:(bycopy NSUInteger)width withHeight:(bycopy NSUInteger)height withPixelFormat:(bycopy OSType)pixelFormat withAspect:(bycopy float)aspect
{
	// MPLog(@"start");
	if (dispDelegate) {
		// make the DisplayFormat
		DisplayFormat fmt;

		fmt.width  = width;
		fmt.height = height;
		fmt.pixelFormat = pixelFormat;
		fmt.aspect = aspect;
		
		switch (pixelFormat) {
			case kYUVSPixelFormat:
				fmt.bytes = 2;
				break;
			case k24RGBPixelFormat:
				fmt.bytes = 3;
				break;
			default:
				fmt.bytes = 4;
				break;
		}
		imageSize = fmt.bytes * width * height;
		
		// 打开shmem
		int shMemID = shm_open([sharedBufferName UTF8String], O_RDONLY, S_IRUSR);
		if (shMemID == -1) {
			MPLog(@"shm_open Failed!");
			return 1;
		}
		
		imageData = mmap(NULL, imageSize * 2, PROT_READ, MAP_SHARED, shMemID, 0);
		// whatever succeed or fail, it should be OK of close the shm
		close(shMemID);
		
		if (imageData == MAP_FAILED) {
			imageData = NULL;
			MPLog(@"mmap Failed");
			return 1;
		}
		char *dataBuf[2];
		dataBuf[0] = imageData;
		dataBuf[1] = imageData + imageSize;
		
		return [dispDelegate coreController:self startWithFormat:fmt buffer:dataBuf total:2];
	}
	return 1;
}

- (void) stop
{
	if (dispDelegate) {
		[dispDelegate coreControllerStop:self];
	}
	if (imageData) {
		munmap(imageData, imageSize * 2);
		imageData = NULL;
		imageSize = 0;
	}
}

-(void) render:(bycopy NSUInteger)frameNum
{
	if (dispDelegate) {
		[dispDelegate coreController:self draw:frameNum];
	}
}

- (void) toggleFullscreen {/* This function should be realized at up-level */}
- (void) ontop {/* This function should be realized at up-level */ }

//////////////////////////////////////////////playing thing/////////////////////////////////////////////////////
-(void) playMedia: (NSString*) moviePath
{
	// 如果正在放映，那么现强制停止
	if (state != kMPCStoppedState) {
		[self performStop];
	}
	
	// 播放开始之前清空subConv的工作文件夹
	[subConv clearWorkDirectory];
	
	// 如果想要自动获得字幕文件的codepage，需要调用这个函数
	if ([pm guessSubCP]) {
		// 为了支持将来的动态加载字幕，必须先设定字幕为UTF-8，即使没有字幕也要这么设定
		[pm setSubCP:@"UTF-8"];

		NSString *vobStr = nil;
		NSDictionary *subEncDict = [subConv getCPFromMoviePath:moviePath nameRule:pm.subNameRule alsoFindVobSub:&vobStr];
		
		NSString *subStr;
		NSArray *subsArray;
		
		if ([pm vobSub] == nil) {
			// 如果用户没有自己设置vobsub的话，这个变量会在每次播放完之后设为nil
			// 如果用户有自己的vobsub，那么就不设置他而用用户的vobsub
			[pm setVobSub:vobStr];
		}
		if ([subEncDict count]) {
			// 如果有字幕文件
			subsArray = [subConv convertTextSubsAndEncodings:subEncDict];
			
			if (subsArray && ([subsArray count] > 0)) {
				[pm setTextSubs:subsArray];
			} else {
				subStr = [[subEncDict allValues] objectAtIndex:0];
				if (![subStr isEqualToString:@""]) {
					// 如果猜出来了
					[pm setSubCP:subStr];
				}
			}
		}
	}

	// 只重置与播放有关的
	[movieInfo.playingInfo resetWithParameterManager:pm];

	if ( [playerCore playMedia:moviePath 
					  withExec:[mpPathPair objectForKey:(pm.prefer64bMPlayer)?kX86_64Key:kI386Key] 
					withParams:[pm arrayOfParametersWithName:(dispDelegate)?(sharedBufferName):(nil)]]
	   ) {
		state = kMPCOpenedState;
		if (delegate) {
			[delegate playebackOpened];
		}
		
		// 这里需要打开Timer去Polling播放时间，然后定期发送现在的播放时间
		pollingTimer = [[NSTimer timerWithTimeInterval:kPollingTimeForTimePos
											    target:self
										 	  selector:@selector(getCurrentTime:)
											  userInfo:nil
											   repeats:YES] retain];

		NSRunLoop *rl = [NSRunLoop currentRunLoop];
		[rl addTimer:pollingTimer forMode:NSDefaultRunLoopMode];
		[rl addTimer:pollingTimer forMode:NSModalPanelRunLoopMode];
		[rl addTimer:pollingTimer forMode:NSEventTrackingRunLoopMode];
	} else {
		// 如果没有成功打开媒体文件
		[pm reset];
	}
}

-(void) setWorkDirectory:(NSString*) wd
{
	[subConv setWorkDirectory:wd];
}

-(void) setSubConverterDelegate:(id<SubConverterDelegate>)dlgt
{
	[subConv setDelegate:dlgt];
}

-(void) getCurrentTime:(NSTimer*)theTimer
{
	if (state == kMPCPlayingState) {
		// 发这个命令会自动让mplayer退出pause状态，而用keep_pause的perfix会得不到任何返回,因此只有在没有pause的时候会polling播放时间
		[playerCore sendStringCommand: [NSString stringWithFormat:@"%@ %@\n", kMPCGetPropertyPreFix, kMPCTimePos]];
	} else if (state == kMPCPausedState) {
		// 即使是暂停的时候这样更新时间，会引发KVO事件，这样是为了保持界面更新
		[movieInfo.playingInfo willChangeValueForKey:@"currentTime"];
		[movieInfo.playingInfo didChangeValueForKey:@"currentTime"];
	}
}

-(void) performStop
{
	// 直接停止core，因为self是core的delegate，
	// terminate方法会调用delegate，然后在那里进行相关的清理工作，所以不在这里做
	SAFERELEASETIMER(pollingTimer);
	[playerCore terminate];
}

-(void) togglePause
{
	switch (state) {
		case kMPCPlayingState:
			[playerCore sendStringCommand: kMPCTogglePauseCmd];
			state = kMPCPausedState;
			break;
		case kMPCPausedState:
			[playerCore sendStringCommand: kMPCTogglePauseCmd];
			state = kMPCPlayingState;
			break;

		default:
			break;
	}
}

-(void) frameStep:(NSInteger)frameNum
{
	if (state == kMPCPlayingState) {
		[self togglePause];
	}
	
	if (state == kMPCPausedState) {
		[playerCore sendStringCommand:kMPCFrameStepCmd];
	}
}

-(void) setSpeed: (float) speed
{
	speed = MAX(speed, 0.1);
	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTFloat, kMPCSetPropertyPreFixPauseKeep, kMPCSpeed, speed]]) {
		[movieInfo.playingInfo setSpeed:[NSNumber numberWithFloat: speed]];
	}
}

-(void) setChapter: (int) chapter
{
	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTInteger, kMPCSetPropertyPreFix, kMPCChapter, chapter]]) {
		[movieInfo.playingInfo setCurrentChapter: chapter];
	}
}

-(float) setTimePos:(float)time mode:(SEEK_MODE)seekMode
{
	float base = 0.0f;
	NSString *cmdStr = nil;

	if (seekMode == kMPCSeekModeAbsolute) {
		// kMPCSeekModeAbsolute : the abs time to jump
		time = MAX(time, 0);
		base = 0;
		cmdStr = [NSString stringWithFormat:kCmdStringFMTFloat, kMPCSetPropertyPreFixPauseKeep, kMPCTimePos, time];
	} else {
		// kMPCSeekModeRelative : the delta time to jump
		base = [movieInfo.playingInfo.currentTime floatValue];
		cmdStr = [NSString stringWithFormat:kCmdStringFMTTimeSeek, kMPCPausingKeepForce, kMPCSeekCmd, time, seekMode];
	}
	
	if ([playerCore sendStringCommand:cmdStr]) {
		time += base;
		[movieInfo.playingInfo setCurrentTime:[NSNumber numberWithFloat:time]];
		return time;
	}
	return -1;
}

-(float) setVolume: (float) vol
{
	vol = MIN(100, MAX(vol, 0));
	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTFloat, kMPCSetPropertyPreFixPauseKeep, kMPCVolume, GetRealVolume(vol)]]) {
		[movieInfo.playingInfo setVolume: vol];
	}
	return vol;
}

-(void) setBalance: (float) bal
{
	bal = MIN(1, MAX(bal, -1));
	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTFloat, kMPCSetPropertyPreFixPauseKeep, kMPCAudioBalance, bal]]) {
		[movieInfo.playingInfo setAudioBalance: bal];
	}
}

-(BOOL) setMute: (BOOL) mute
{
	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTInteger, kMPCSetPropertyPreFixPauseKeep, kMPCMute, (mute)?1:0]]) {
		[movieInfo.playingInfo setMute:mute];
	} else {
		[movieInfo.playingInfo setMute:NO];
		mute = NO;
	}
	return mute;
}

-(void) setAudioDelay: (float) delay
{
	if (fabsf(delay) < 0.00001f) { delay = 0.0f; }
	
	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTFloat, kMPCSetPropertyPreFixPauseKeep, kMPCAudioDelay, -1 * delay]]) {
		[movieInfo.playingInfo setAudioDelay: [NSNumber numberWithFloat: delay]];
	}
}

-(void) setAudio: (int) audioID
{
	[playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTInteger, kMPCSetPropertyPreFixPauseKeep, kMPCSwitchAudio, audioID]];
}

-(void) setVideo: (int) videoID
{
	[playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTInteger, kMPCSetPropertyPreFixPauseKeep, kMPCSwitchVideo, videoID]];
}

-(void) setSub: (int) subID
{
	[playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTInteger, kMPCSetPropertyPreFixPauseKeep, kMPCSub, subID]];
}

-(void) setSubDelay: (float) delay
{
	if (fabsf(delay) < 0.00001f) { delay = 0.0f; }

	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTFloat, kMPCSetPropertyPreFixPauseKeep, kMPCSubDelay, -1 * delay]]) {
		[movieInfo.playingInfo setSubDelay:[NSNumber numberWithFloat: delay]];
	}
}

-(void) setSubPos: (float) pos
{
	pos = MIN(100, MAX(pos, 0));
	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTInteger, kMPCSetPropertyPreFixPauseKeep, kMPCSubPos, ((unsigned int)pos)]]) {
		[movieInfo.playingInfo setSubPos:pos];
	}
}

-(void) setSubScale: (float) scale
{
	scale = MAX(0.1, MIN(scale, 100));

	if ([playerCore sendStringCommand:[NSString stringWithFormat:kCmdStringFMTFloat, kMPCSetPropertyPreFixPauseKeep, kMPCSubScale, scale]]) {
		[movieInfo.playingInfo setSubScale:[NSNumber numberWithFloat:scale]];
	}
}

-(void) loadSubFile: (NSString*) path
{
	NSString *cpStr = [subConv getCPOfTextSubtitle:path];
	if (cpStr) {
		// 找到了编码方式
		NSArray *newPaths = [subConv convertTextSubsAndEncodings:[NSDictionary dictionaryWithObjectsAndKeys:cpStr, path, nil]];
		if (newPaths && [newPaths count]) {
			// MPLog(@"%@", [NSString stringWithFormat:@"%@ \"%@\"", kMPCSubLoad, [newPaths objectAtIndex:0]]);
			[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ \"%@\"\n", kMPCSubLoad, [newPaths objectAtIndex:0]]];
		}
	}
}

-(void) setLetterBox:(BOOL) renderSubInLB top:(float) topRatio bottom:(float)bottomRatio
{
	[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %f %f %d\n", 
								   kMPCPausingKeepForce, kMPCAssMargin, bottomRatio, topRatio, renderSubInLB]];
}

-(void) setEqualizer:(NSArray*)amps
{
	// delete the previous filter
	[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %@\n", kMPCPausingKeepForce, kMPCAfDelCmd, kMPCEqualizer]];
	
	if (amps && ([amps count]>0)) {
		NSMutableString *str = [[NSMutableString alloc] initWithCapacity:40];
		
		for (id amp in amps) {
			[str appendFormat:@":%.2f", [amp floatValue]];
		}
		[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %@=%@\n", kMPCPausingKeepForce, kMPCAfAddCmd, kMPCEqualizer, [str substringFromIndex:1]]];
		[str release];
	}
}

-(void) mapAudioChannelsTo:(NSInteger) chDst
{
	[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %@\n", kMPCPausingKeepForce, kMPCAfDelCmd, kMPCPan]];
	
	AudioInfo *ai = [movieInfo audioInfoForID:[movieInfo.playingInfo currentAudioID]];
	
	if (ai) {
		NSInteger chSrc = [ai channels];
		
		if (chDst == 2) {
			if (chSrc == 1) {
				[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %@=2:1:1\n", kMPCPausingKeepForce, kMPCAfAddCmd, kMPCPan]];
			} else if (chSrc == 6) {
				[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %@=2:0.48:0:0:0.48:0.24:0:0:0.24:0.28:0.28:0.15:0.15\n", kMPCPausingKeepForce, kMPCAfAddCmd, kMPCPan]];
			} else if (chSrc == 8) {
				[playerCore sendStringCommand:[NSString stringWithFormat:@"%@ %@ %@=2:0.4:0:0:0.4:0.24:0:0:0.24:0.28:0:0:0.28:0.13:0.13:0.1:0.1\n", kMPCPausingKeepForce, kMPCAfAddCmd, kMPCPan]];
			}
		}
	}
}

// 这个是LogAnalyzer的delegate方法，
// 因此是运行在工作线程上的，因为这里用到了KVC和KVO
// 有没有必要运行在主线程上？
-(void) logAnalyzeFinished:(NSDictionary*) dict
{
	for (NSString *key in dict) {
		NSString *keyPath = [keyPathDict objectForKey:key];
		
		// MPLog(@"%@", dict);
		if (keyPath) {
			int type = [[typeDict objectForKey:key] intValue];
			
			//如果log里面能找到相应的key path
			switch (type) {
				case kMITypeFlatValue:
					[self setValue:[dict objectForKey:key] forKeyPath:keyPath];
					break;
				case kMITypeSubArray:
					// 这里如果直接使用KVO的话，产生的时Insert的change，效率太低
					// 因此手动发生KVO
					[movieInfo willChangeValueForKey:kMovieInfoKVOSubInfo];
					[movieInfo.subInfo setArray:[[dict objectForKey:key] componentsSeparatedByString:@":"]];
					[movieInfo didChangeValueForKey:kMovieInfoKVOSubInfo];
					break;
				case kMITypeSubAppend:
					// 会发生insert的KVO change
					// MPLog(@"%@", obj);
					[[movieInfo mutableArrayValueForKey:kMovieInfoKVOSubInfo] addObject: [[dict objectForKey:key] lastPathComponent]];
					break;
				case kMITypeStateChanged:
				{
					// 目前只有在播放开始的时候才会激发这个事件，所以可以发notification
					// 但是如果变成一般的事件，发notification要注意！！！
					int stateOld = state;
					state = [[dict objectForKey:key] intValue];
					if (((stateOld & kMPCStateMask) == 0) && (state & kMPCStateMask)) {
						if (delegate) {
							[delegate playebackStarted];
						}
					}
					break;
				}
				case kMITypeAudioGotID:
				{
					AudioInfo *info;
					NSArray *idLang;
					NSArray *IDs = [[dict objectForKey:key] componentsSeparatedByString:@":"];
					
					[movieInfo willChangeValueForKey:kMovieInfoKVOAudioInfo];
					
					for (NSString *str in IDs) {
						idLang = [str componentsSeparatedByString:@","];
						
						info = [[AudioInfo alloc] init];

						[info setID:[[idLang objectAtIndex:0] intValue]];
						[info setLanguage:[idLang objectAtIndex:1]];
						
						[movieInfo.audioInfo addObject:info];
						
						[info release];
					}
					[movieInfo didChangeValueForKey:kMovieInfoKVOAudioInfo];
					break;
				}
				case kMITypeVideoGotID:
				{
					VideoInfo *info;
					NSArray *idLang;
					NSArray *IDs = [[dict objectForKey:key] componentsSeparatedByString:@":"];
					
					[movieInfo willChangeValueForKey:kMovieInfoKVOVideoInfo];
					
					for (NSString *str in IDs) {
						idLang = [str componentsSeparatedByString:@","];
						
						info = [[VideoInfo alloc] init];
						
						[info setID:[[idLang objectAtIndex:0] intValue]];
						[info setLanguage:[idLang objectAtIndex:1]];
						
						[movieInfo.videoInfo addObject:info];
						
						[info release];
					}
					[movieInfo didChangeValueForKey:kMovieInfoKVOVideoInfo];
					break;
				}
				case kMITypeVideoGotInfo:
				case kMITypeAudioGotInfo:
				// This KVO will be called
				// 1. when playback is opened but not started, core just got the infos
				// 2. in multi-track media, this will be called when track was changed
				{
					NSArray *strArr = [[dict objectForKey:key] componentsSeparatedByString:@":"];
					int ID = [[strArr objectAtIndex:0] intValue];
					NSArray *obj = [self valueForKeyPath:keyPath];
					id infoToSet = nil;
					NSString *idKeyPath = nil;
					NSNumber *currentID;
					
					for (id info in obj) {
						if ([info ID] == ID) {
							infoToSet = info;
							break;
						}
					}
					if (infoToSet) {
						[infoToSet setInfoDataWithArray:strArr];
						currentID = [NSNumber numberWithInt:ID];
					} else {
						currentID = nil;
					}
					if (type == kMITypeAudioGotInfo) {
						idKeyPath = kKVOPropertyKeyPathAudioInfoID;
					} else {
						idKeyPath = kKVOPropertyKeyPathVideoInfoID;
					}
					[self setValue:currentID forKeyPath:idKeyPath];
					break;	
				}
				default:
					break;
			}
		}
	}
}

@end
