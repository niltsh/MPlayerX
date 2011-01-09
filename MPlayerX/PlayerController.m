/*
 * MPlayerX - PlayerController.m
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

#import "CocoaAppendix.h"
#import "UserDefaults.h"
#import "KeyCode.h"
#import "LocalizedStrings.h"
#import "PlayerController.h"
#import "PlayList.h"
#import <sys/sysctl.h>
#import "OpenURLController.h"
#import "CharsetQueryController.h"
#import "AppController.h"
#import "CoreController.h"

NSString * const kMPCPlayOpenedNotification			= @"kMPCPlayOpenedNotification";
NSString * const kMPCPlayOpenedURLKey				= @"kMPCPlayOpenedURLKey";
NSString * const kMPCPlayLastStoppedTimeKey			= @"kMPCPlayLastStoppedTimeKey";

NSString * const kMPCPlayStartedNotification		= @"kMPCPlayStartedNotification";
NSString * const kMPCPlayStartedAudioOnlyKey		= @"kMPCPlayStartedAudioOnlyKey";

NSString * const kMPCPlayStoppedNotification		= @"kMPCPlayStoppedNotification";
NSString * const kMPCPlayWillStopNotification		= @"kMPCPlayWillStopNotification";
NSString * const kMPCPlayFinalizedNotification		= @"kMPCPlayFinalizedNotification";

NSString * const kMPCPlayInfoUpdatedNotification	= @"kMPCPlayInfoUpdatedNotification";
NSString * const kMPCPlayInfoUpdatedKeyPathKey		= @"kMPCPlayInfoUpdatedKeyPathKey";
NSString * const kMPCPlayInfoUpdatedChangeDictKey	= @"kMPCPlayInfoUpdatedChangeDictKey";

NSString * const kMPCDefaultSubFontPath			= @"wqy-microhei.ttc";

NSString * const kMPCMplayerNameMT		= @"mplayer-mt";
NSString * const kMPCMplayerName		= @"mplayer";
NSString * const kMPCFMTMplayerPathM32	= @"binaries/m32/%@";
NSString * const kMPCFMTMplayerPathX64	= @"binaries/x86_64/%@";

NSString * const kMPCFFMpegProtoHead	= @"ffmpeg://";

#define kThreadsNumMax	(8)

#define PlayerCouldAcceptCommand	(((mplayer.state) & 0x0100)!=0)

@interface PlayerController (CoreControllerDelegate)
-(void) playebackOpened;
-(void) playebackStarted;
-(void) playebackStopped:(NSDictionary*)dict;
-(void) playebackWillStop;
@end

@interface PlayerController (PlayerControllerInternal)
-(void) showAlertPanelModal:(NSString*) str;
-(BOOL) shouldRun64bitMPlayer;
-(void) preventSystemSleep;
-(void) playMedia:(NSURL*)url;
-(NSURL*) findFirstMediaFileFromSubFile:(NSString*)path;
@end

@interface PlayerController (SubConverterDelegate)
-(NSString*) subConverter:(id)subConv detectedFile:(NSString*)path ofCharsetName:(NSString*)charsetName confidence:(float)confidence;
@end

@implementation PlayerController

@synthesize lastPlayedPath;

+(void) initialize
{
	NSNumber *boolYes = [NSNumber numberWithBool:YES];
	NSNumber *boolNo  = [NSNumber numberWithBool:NO];
	
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   boolYes, kUDKeyAutoPlayNext,
					   boolYes, kUDKeyAPNFuzzy,
					   kMPCDefaultSubFontPath, kUDKeySubFontPath,
					   boolYes, kUDKeyPrefer64bitMPlayer,
					   boolYes, kUDKeyEnableMultiThread,
					   [NSNumber numberWithFloat:1.0], kUDKeySubScale,
					   [NSNumber numberWithFloat:0.1], kUDKeySubScaleStepValue,
					   [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:1.0 alpha:1.00]], kUDKeySubFontColor,
					   [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0.0 alpha:0.85]], kUDKeySubFontBorderColor,
					   boolNo, kUDKeyForceIndex,
					   [NSNumber numberWithUnsignedInt:kSubFileNameRuleContain], kUDKeySubFileNameRule,
					   boolNo, kUDKeyDTSPassThrough,
					   boolNo, kUDKeyAC3PassThrough,
					   [NSNumber numberWithUnsignedInt:2], kUDKeyThreadNum,
					   boolYes, kUDKeyUseEmbeddedFonts,
					   [NSNumber numberWithUnsignedInt:10000], kUDKeyCacheSize,
					   boolYes, kUDKeyPreferIPV6,
					   boolNo, kUDKeyCachingLocal,
					   [NSNumber numberWithUnsignedInt:kPMLetterBoxModeNotDisplay], kUDKeyLetterBoxMode,
					   [NSNumber numberWithUnsignedInt:kPMLetterBoxModeBottomOnly], kUDKeyLetterBoxModeAlt,
					   [NSNumber numberWithFloat:0.1], kUDKeyLetterBoxHeight,
					   boolYes, kUDKeyPlayWhenOpened,
					   boolYes, kUDKeyOverlapSub,
					   boolYes, kUDKeyRtspOverHttp,
					   [NSNumber numberWithUnsignedInt:kPMMixDTS5_1ToStereo], kUDKeyMixToStereoMode,
					   boolYes, kUDKeyAutoResume,
					   [NSNumber numberWithUnsignedInt:kPMImgEnhanceNone], kUDKeyImgEnhanceMethod,
					   [NSNumber numberWithUnsignedInt:kPMDeInterlaceNone], kUDKeyDeIntMethod,
					   @"", kUDKeyExtraOptions,
					   nil]];	
}

#pragma mark Init/Dealloc
-(id) init
{
	self = [super init];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
		mplayer = [[CoreController alloc] init];
		[mplayer setDelegate:self];
		
		// TODO Need test
		/////////////////////////setup subconverter////////////////////
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir = NO;
		NSString *workDir = [[[fm URLForDirectory:NSApplicationSupportDirectory
										 inDomain:NSUserDomainMask
								appropriateForURL:NULL
										   create:YES
											error:NULL] path] stringByAppendingPathComponent:kMPCStringMPlayerX];
		
		if ([fm fileExistsAtPath:workDir isDirectory:&isDir] && (!isDir)) {
			// 如果存在但不是文件夹的话
			[fm removeItemAtPath:workDir error:NULL];
		}
		if (!isDir) {
			// 如果原来不存在这个文件夹或者存在的是文件的话，都需要重建文件夹
			if (![fm createDirectoryAtPath:workDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
				workDir = nil;
			}
		}
		[mplayer setWorkDirectory:workDir];
		[mplayer setSubConverterDelegate:self];

		/////////////////////////setup CoreController////////////////////
		[self setMultiThreadMode:[ud boolForKey:kUDKeyEnableMultiThread]];
		
		// 得到字幕字体文件的路径
		NSString *subFontPath = [ud stringForKey:kUDKeySubFontPath];
		
		if ([subFontPath isEqualToString:kMPCDefaultSubFontPath]) {
			// 如果是默认的路径的话，需要添加一些路径头
			[mplayer.pm setSubFont:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:subFontPath]];
		} else {
			// 否则直接设定
			[mplayer.pm setSubFont:subFontPath];
		}
		
		// 决定是否使用64bit的mplayer
		[mplayer.pm setPrefer64bMPlayer:[self shouldRun64bitMPlayer]];

		lastPlayedPath = nil;
		lastPlayedPathPre = nil;

		kvoSetuped = NO;
	}
	return self;
}

-(void) setupKVO
{
	if (!kvoSetuped) {
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathLength
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathCurrentTime
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSeekable
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSpeed
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSubDelay
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathAudioDelay
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathSubInfo
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathCachingPercent
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathAudioInfo
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathVideoInfo
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathAudioInfoID
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		[mplayer addObserver:self
				  forKeyPath:kKVOPropertyKeyPathVideoInfoID
					 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
		kvoSetuped = YES;	
	}
}

-(void) dealloc
{
	if (kvoSetuped) {
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathCurrentTime];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathLength];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSeekable];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSpeed];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSubDelay];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathAudioDelay];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathSubInfo];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathCachingPercent];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathAudioInfo];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathVideoInfo];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathAudioInfoID];
		[mplayer removeObserver:self forKeyPath:kKVOPropertyKeyPathVideoInfoID];
		
		kvoSetuped = NO;
	}

	[mplayer release];
	[lastPlayedPath release];

	[super dealloc];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == mplayer) {
		[notifCenter postNotificationName:kMPCPlayInfoUpdatedNotification object:self
								 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										   keyPath, kMPCPlayInfoUpdatedKeyPathKey,
										   change, kMPCPlayInfoUpdatedChangeDictKey, nil]];
		MPLog(@"%@", keyPath);
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(id) setDisplayDelegateForMPlayer:(id<CoreDisplayDelegate>) delegate
{
	[mplayer setDispDelegate:delegate];
	return mplayer;
}

-(int) playerState
{
	return mplayer.state;
}

-(BOOL) couldAcceptCommand
{
	return PlayerCouldAcceptCommand;
}

-(MovieInfo*) mediaInfo
{
	return [mplayer movieInfo];
}

-(void) loadFiles:(NSArray*)files fromLocal:(BOOL)local
{
	if (files) {
		NSString *path;
		BOOL isDir = YES;
		NSFileManager *fm = [NSFileManager defaultManager];

		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		for (id file in files) {
		
			// 如果是字符串的话先转到URL	
			if ([file isKindOfClass:[NSString class]]) {
				if (local) {
					file = [NSURL fileURLWithPath:file isDirectory:NO];
				} else {
					file = [NSURL URLWithString:file];
				}
			}
			
			if (file && [file isKindOfClass:[NSURL class]]) {
				if ([file isFileURL]) {
					// 如果是本地文件
					path = [file path];
					isDir = YES;
					
					if ([fm fileExistsAtPath:path isDirectory:&isDir] && (!isDir)) {
						// 如果文件存在
						NSString *ext = [[path pathExtension] lowercaseString];
						
						if ([[[AppController sharedAppController] supportVideoFormats] containsObject:ext] || 
							[[[AppController sharedAppController] supportAudioFormats] containsObject:ext]) {
							// 如果是支持的格式
							[self playMedia:file];
							break;
							
						} else if ([[[AppController sharedAppController] supportSubFormats] containsObject:ext]) {
							// 如果是字幕文件
							if (PlayerCouldAcceptCommand) {
								// 如果是在播放状态，就加载字幕
								[self loadSubFile:path];
							} else {
								// 如果是在停止状态，那么应该是想打开媒体文件先
								// 需要根据字幕文件名去寻找影片文件
								NSURL *autoSearchMediaFile = [self findFirstMediaFileFromSubFile:path];
								
								if (autoSearchMediaFile) {
									// 如果找到了
									[self playMedia:autoSearchMediaFile];
								}
								// 不管有没有找到，都需要break
								// 找到了就播放
								// 没有找到。说明按照当前的文件名规则并不存在相应的媒体文件
								if (!autoSearchMediaFile) {
									// 如果没有找到合适的播放文件
									[self showAlertPanelModal:kMPXStringCantFindMediaFile];
								}
								break;
							}
						} else {
							// 否则提示
							[self showAlertPanelModal:kMPXStringFileNotSupported];
						}
					} else {
						// 文件不存在
						[self showAlertPanelModal:kMPXStringFileNotExist];
					}
				} else {
					// 如果是非本地文件
					[self playMedia:file];
					break;
				}				
			}
		}
		[pool drain];
	}
}

-(void) playMedia:(NSURL*)url
{
	// 内部函数，没有那么必要判断url的有效性
	NSString *path;	
	NSNumber *stime;
	
	// 设定字幕大小
	[mplayer.pm setSubScale:[ud floatForKey:kUDKeySubScale]];
	[mplayer.pm setSubFontColor: [NSUnarchiver unarchiveObjectWithData: [ud objectForKey:kUDKeySubFontColor]]];
	[mplayer.pm setSubFontBorderColor: [NSUnarchiver unarchiveObjectWithData: [ud objectForKey:kUDKeySubFontBorderColor]]];
	
	[mplayer.pm setForceIndex:[ud boolForKey:kUDKeyForceIndex]];
	[mplayer.pm setSubNameRule:[ud integerForKey:kUDKeySubFileNameRule]];
	[mplayer.pm setDtsPass:[ud boolForKey:kUDKeyDTSPassThrough]];
	[mplayer.pm setAc3Pass:[ud boolForKey:kUDKeyAC3PassThrough]];
	[mplayer.pm setUseEmbeddedFonts:[ud boolForKey:kUDKeyUseEmbeddedFonts]];
	
	[mplayer.pm setLetterBoxMode:[ud integerForKey:kUDKeyLetterBoxMode]];
	[mplayer.pm setLetterBoxHeight:[ud floatForKey:kUDKeyLetterBoxHeight]];
	[mplayer.pm setPauseAtStart:![ud boolForKey:kUDKeyPlayWhenOpened]];
	[mplayer.pm setOverlapSub:[ud boolForKey:kUDKeyOverlapSub]];
	[mplayer.pm setMixToStereo:[ud integerForKey:kUDKeyMixToStereoMode]];
	
	[mplayer.pm setImgEnhance:[ud integerForKey:kUDKeyImgEnhanceMethod]];
	[mplayer.pm setDeinterlace:[ud integerForKey:kUDKeyDeIntMethod]];

	[mplayer.pm setExtraOptions:[ud stringForKey:kUDKeyExtraOptions]];

	// 这里必须要retain，否则如果用lastPlayedPath作为参数传入的话会有问题
	lastPlayedPathPre = [[url absoluteURL] retain];
	
	if ([url isFileURL]) {
		// local files
		path = [url path];

		[mplayer.pm setCache:([ud boolForKey:kUDKeyCachingLocal])?([ud integerForKey:kUDKeyCacheSize]):(0)];
		[mplayer.pm setRtspOverHttp:NO];
		
		// 将文件加入Recent Menu里，只能加入本地文件
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
	} else {
		// network stream
		path = [url absoluteString];
		
		[mplayer.pm setCache:[ud integerForKey:kUDKeyCacheSize]];
		[mplayer.pm setPreferIPV6:[ud boolForKey:kUDKeyPreferIPV6]];
		[mplayer.pm setRtspOverHttp:[ud boolForKey:kUDKeyRtspOverHttp]];
		
		// 将URL加入OpenURLController
		[openUrlController addUrl:path];

		if ([ud boolForKey:kUDKeyFFMpegHandleStream] != ([NSEvent modifierFlags]==kSCMFFMpegHandleStreamShortCurKey)) {
			path = [kMPCFFMpegProtoHead stringByAppendingString:path];
		}
	}

	////////////////////////////////////////////////////////////////////
	// HACK!!! always try to use ffmpeg as the demuxer
	// EXCEPT real media
	NSString *ext = [[path pathExtension] lowercaseString];
	if ([ext isEqualToString:@"rm"] || [ext isEqualToString:@"rmvb"] ||
		[ext isEqualToString:@"ra"] || [ext isEqualToString:@"ram"]) {
		[mplayer.pm setDemuxer:nil];
	} else {
		[mplayer.pm setDemuxer:kPMValDemuxFFMpeg];
	}
	////////////////////////////////////////////////////////////////////

	if ([ud boolForKey:kUDKeyAutoResume] && (stime = [[[AppController sharedAppController] bookmarks] objectForKey:[lastPlayedPathPre absoluteString]])) {
		// if AutoResume is ON and there was a record in the bookmarks
		// and 5s to help the users to remember where they left in the movie
		[mplayer.pm setStartTime:([stime floatValue] - 5)];
	} else {
		[mplayer.pm setStartTime:-1];
	}
	
	[mplayer playMedia:path];
	
	SAFERELEASE(lastPlayedPath);
	lastPlayedPath = lastPlayedPathPre;
	lastPlayedPathPre = nil;
}

-(NSURL*) findFirstMediaFileFromSubFile:(NSString*)path
{
	// 需要先得到 nameRule的最新值
	[mplayer.pm setSubNameRule:[ud integerForKey:kUDKeySubFileNameRule]];

	// 得到最新的nameRule
	SUBFILE_NAMERULE nameRule = [mplayer.pm subNameRule];
	
	NSURL *mediaURL = nil;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// 文件夹路径
	NSString *directoryPath = [path stringByDeletingLastPathComponent];
	// 字幕文件名称
	NSString *subName = [[[path lastPathComponent] stringByDeletingPathExtension] lowercaseString];

	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];

	// 遍历播放文件所在的目录
	for (NSString *mediaFile in directoryEnumerator)
	{
		// TODO 这里需要检查mediaFile是文件名还是 路径名
		NSDictionary *fileAttr = [directoryEnumerator fileAttributes];
		NSString *ext = [[mediaFile pathExtension] lowercaseString];
		
		if ([[fileAttr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
			//不遍历子目录
			[directoryEnumerator skipDescendants];

		} else if ([[fileAttr objectForKey:NSFileType] isEqualToString: NSFileTypeRegular] &&
					([[[AppController sharedAppController] supportVideoFormats] containsObject:ext] || 
					 [[[AppController sharedAppController] supportAudioFormats] containsObject:ext])) {
			// 如果是正常文件，并且是媒体文件
			NSString *mediaName = [[mediaFile stringByDeletingPathExtension] lowercaseString];
			
			switch (nameRule) {
				case kSubFileNameRuleExactMatch:
					if (![mediaName isEqualToString:subName]) continue; // exact match
					break;
				case kSubFileNameRuleAny:
					break; // any sub file is OK
				case kSubFileNameRuleContain:
					if ([subName rangeOfString: mediaName].location == NSNotFound) continue; // contain the movieName
					break;
				default:
					continue;
					break;				
			}
			// 能到这里说明找到了一个合适的播放文件, 跳出循环
			mediaURL = [[NSURL fileURLWithPath:[directoryPath stringByAppendingPathComponent:mediaFile] isDirectory:NO] retain];
			break;
		}
	}
	[pool drain];
	return [mediaURL autorelease];
}

-(void) setMultiThreadMode:(BOOL) mt
{
	NSString *resPath = [[NSBundle mainBundle] resourcePath];
	
	NSString *mplayerName;
	unsigned int threadNum;
	
	if (/*mt*/1) {
		// 使用多线程
		threadNum = MIN(kThreadsNumMax, MAX(1,[ud integerForKey:kUDKeyThreadNum]));
		mplayerName = kMPCMplayerNameMT;
	} else {
		threadNum = MIN(kThreadsNumMax, MAX(1,[ud integerForKey:kUDKeyThreadNum]));
		mplayerName = kMPCMplayerName;
	}

	[ud setInteger:threadNum forKey:kUDKeyThreadNum];
	
	[mplayer.pm setThreads: threadNum];
	
	[mplayer setMpPathPair: [NSDictionary dictionaryWithObjectsAndKeys: 
							 [resPath stringByAppendingPathComponent:[NSString stringWithFormat:kMPCFMTMplayerPathM32, mplayerName]], kI386Key,
							 [resPath stringByAppendingPathComponent:[NSString stringWithFormat:kMPCFMTMplayerPathX64, mplayerName]], kX86_64Key,
							 nil]];
}

////////////////////////////////////////////////cooperative actions with UI//////////////////////////////////////////////////
-(void) stop
{
	[mplayer performStop];
	// 窗口一旦关闭，清理lastPlayPath，则即使再次打开窗口也不会播放以前的文件
	SAFERELEASE(lastPlayedPath);	
}

-(void) togglePlayPause
{
	if (mplayer.state == kMPCStoppedState) {
		//mplayer不在播放状态
		if (lastPlayedPath) {
			// 有可以播放的文件
			[self playMedia:lastPlayedPath];
		}
	} else {
		// mplayer正在播放
		[mplayer togglePause];
	}
}

-(void) frameStep
{
	[mplayer frameStep:1];
}

-(BOOL) toggleMute
{
	return (PlayerCouldAcceptCommand)? ([mplayer setMute:!mplayer.movieInfo.playingInfo.mute]):NO;
}

-(float) setVolume:(float) vol
{
	vol = [mplayer setVolume:vol];
	[mplayer.pm setVolume:vol];
	return vol;
}

-(float) seekTo:(float)time mode:(SEEK_MODE)seekMode
{
	// playingInfo的currentTime是通过获取log来同步的，因此这里不进行直接设定
	if (PlayerCouldAcceptCommand && mplayer.movieInfo.seekable) {
		if (seekMode == kMPCSeekModeRelative) {
			time -= [mplayer.movieInfo.playingInfo.currentTime floatValue];
		}
		
		time = [mplayer setTimePos:time mode:seekMode];
		[mplayer.la stop];
		return time;
	}
	return -1;
}

-(float) changeTimeBy:(float) delta
{
	// playingInfo的currentTime是通过获取log来同步的，因此这里不进行直接设定
	if (PlayerCouldAcceptCommand && mplayer.movieInfo.seekable) {
		delta = [mplayer setTimePos:delta mode:kMPCSeekModeRelative];
		[mplayer.la stop];
		return delta;
	}
	return -1;
}

-(float) changeSpeedBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSpeed:[mplayer.movieInfo.playingInfo.speed floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) changeSubDelayBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubDelay:[mplayer.movieInfo.playingInfo.subDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];
}

-(float) changeAudioDelayBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setAudioDelay:[mplayer.movieInfo.playingInfo.audioDelay floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.audioDelay floatValue];	
}

-(float) changeSubScaleBy:(float) delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubScale: [mplayer.movieInfo.playingInfo.subScale floatValue] + delta];
	}
	return [mplayer.movieInfo.playingInfo.subScale floatValue];
}

-(float) changeSubPosBy:(float)delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubPos: mplayer.movieInfo.playingInfo.subPos + delta*100];
	}
	return mplayer.movieInfo.playingInfo.subPos;
}

-(float) changeAudioBalanceBy:(float)delta
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setBalance:mplayer.movieInfo.playingInfo.audioBalance + delta];
	}
	return mplayer.movieInfo.playingInfo.audioBalance;
}

-(float) setSpeed:(float) spd
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSpeed:spd];
	}
	return [mplayer.movieInfo.playingInfo.speed floatValue];
}

-(float) setSubDelay:(float) sd
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setSubDelay:sd];
	}
	return [mplayer.movieInfo.playingInfo.subDelay floatValue];	
}

-(float) setAudioDelay:(float) ad
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setAudioDelay:ad];
	}
	return [mplayer.movieInfo.playingInfo.audioDelay floatValue];	
}

-(void) setSubtitle:(int) subID
{
	[mplayer setSub:subID];
}

-(void) setAudio:(int) audioID
{
	[mplayer setAudio:audioID];
}

-(void) setAudioBalance:(float)bal
{
	[mplayer setBalance:bal];
}

-(void) setVideo:(int) videoID
{
	[mplayer setVideo:videoID];
}

-(void) loadSubFile:(NSString*)subPath
{
	[mplayer loadSubFile:subPath];
}

-(void) setLetterBox:(BOOL) renderSubInLB top:(float) topRatio bottom:(float)bottomRatio
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setLetterBox:renderSubInLB top:topRatio bottom:bottomRatio];
	}
}

-(void) setEqualizer:(NSArray*) amps
{
	if (PlayerCouldAcceptCommand) {
		[mplayer setEqualizer:amps];
	}
}

//////////////////////////////////////private methods////////////////////////////////////////////////////
-(BOOL) shouldRun64bitMPlayer
{
	int value = 0 ;
	unsigned long length = sizeof(value);
	
	if ((sysctlbyname("hw.optional.x86_64", &value, &length, NULL, 0) == 0) && (value == 1))
		return [ud boolForKey:kUDKeyPrefer64bitMPlayer];
	
	return NO;
}

-(void) showAlertPanelModal:(NSString*) str
{
	id alertPanel = NSGetAlertPanel(kMPXStringError, str, kMPXStringOK, nil, nil);
	[NSApp runModalForWindow:alertPanel];
	NSReleaseAlertPanel(alertPanel);
}

-(void) preventSystemSleep
{
	if (mplayer.state == kMPCPlayingState) {
		UpdateSystemActivity(UsrActivity);
	}
}

///////////////////////////////////////MPlayer Notifications/////////////////////////////////////////////
-(void) playebackOpened
{
	// 用文件名查找有没有之前的播放记录
	NSNumber *stopTime = [[[AppController sharedAppController] bookmarks] objectForKey:[lastPlayedPathPre absoluteString]];
	NSDictionary *dict;

	if (stopTime) {
		dict = [NSDictionary dictionaryWithObjectsAndKeys:
				lastPlayedPathPre, kMPCPlayOpenedURLKey, 
				stopTime, kMPCPlayLastStoppedTimeKey,
				nil];
	} else {
		dict = [NSDictionary dictionaryWithObjectsAndKeys: lastPlayedPathPre, kMPCPlayOpenedURLKey, nil];		
	}

	[notifCenter postNotificationName:kMPCPlayOpenedNotification object:self userInfo:dict];
}

-(void) playebackStarted
{
	[notifCenter postNotificationName:kMPCPlayStartedNotification object:self 
							 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithBool:([mplayer.movieInfo.videoInfo count] == 0)], kMPCPlayStartedAudioOnlyKey,
									   nil]];

	MPLog(@"vc:%lu, ac:%lu", [mplayer.movieInfo.videoInfo count], [mplayer.movieInfo.audioInfo count]);
}

-(void) playebackWillStop
{
	[notifCenter postNotificationName:kMPCPlayWillStopNotification object:self userInfo:nil];
}

-(void) playebackStopped:(NSDictionary*)dict
{	
	BOOL stoppedByForce = [[dict objectForKey:kMPCPlayStoppedByForceKey] boolValue];

	[notifCenter postNotificationName:kMPCPlayStoppedNotification object:self userInfo:nil];

	if (stoppedByForce) {
		// 如果是强制停止
		// 用文件名做key，记录这个文件的播放时间
		[[[AppController sharedAppController] bookmarks] setObject:[dict objectForKey:kMPCPlayStoppedTimeKey] forKey:[lastPlayedPath absoluteString]];
	} else {
		// 自然关闭
		// 删除这个文件key的播放时间
		[[[AppController sharedAppController] bookmarks] removeObjectForKey:[lastPlayedPath absoluteString]];
	}
	
	if ([ud boolForKey:kUDKeyAutoPlayNext] && [lastPlayedPath isFileURL] && (!stoppedByForce)) {
		//如果不是强制关闭的话
		//如果不是本地文件，肯定返回nil
		NSString *nextPath = 
			[PlayList AutoSearchNextMoviePathFrom:[lastPlayedPath path] 
										inFormats:[[[AppController sharedAppController] supportVideoFormats] 
												   setByAddingObjectsFromSet:[[AppController sharedAppController] supportAudioFormats]]];
		
		if (nextPath != nil) {
			BOOL pasTemp = [ud boolForKey:kUDKeyPlayWhenOpened];
			[ud setBool:YES forKey:kUDKeyPlayWhenOpened];
			
			[self loadFiles:[NSArray arrayWithObject:nextPath] fromLocal:YES];
			
			[ud setBool:pasTemp forKey:kUDKeyPlayWhenOpened];

			return;
		}
	}	
	[notifCenter postNotificationName:kMPCPlayFinalizedNotification object:self userInfo:nil];
}

/////////////////////////////////SubConverter Delegate methods/////////////////////////////////////
-(NSString*) subConverter:(SubConverter*)subConv detectedFile:(NSString*)path ofCharsetName:(NSString*)charsetName confidence:(float)confidence
{
	// 当置信率高于阈值的时候，直接返回传入的 charsetName
	NSString *ret = charsetName;
	
	if (confidence <= [ud floatForKey:kUDKeyTextSubtitleCharsetConfidenceThresh]) {
		// 当置信率小于阈值时
		CFStringEncoding ce;
		
		if ([ud boolForKey:kUDKeyTextSubtitleCharsetManual]) {
			// 如果是手动指定的话
			ce = [charsetController askForSubEncodingForFile:path charsetName:charsetName confidence:confidence];
		} else {
			// 如果是自动fallback
			ce = [ud integerForKey:kUDKeyTextSubtitleCharsetFallback];
		}
		ret = (NSString*)CFStringConvertEncodingToIANACharSetName(ce);
	}
	return ret;
}
@end
