/*
 * MPlayerX - coredef.h
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

/////////////////////////////////////typedef/////////////////////////////////////
typedef struct {
	NSUInteger width;
	NSUInteger height;
	NSUInteger bytes;
	OSType pixelFormat;
	CGFloat aspect;
}DisplayFormat;

typedef enum {
	kSubFileNameRuleExactMatch = 0,
	kSubFileNameRuleContain = 1,
	kSubFileNameRuleAny = 2
} SUBFILE_NAMERULE;

typedef enum {
	kMPCSeekModeRelative = 0,
	kMPCSeekModeAbsolute = 2
} SEEK_MODE;

/////////////////////////////////////protocols/////////////////////////////////////
// the protocol for displaying the video
@protocol CoreDisplayDelegate
-(int)  coreController:(id)sender startWithFormat:(DisplayFormat)df buffer:(char**)data total:(NSUInteger)num;
-(void) coreController:(id)sender draw:(NSUInteger)frameNum;
-(void) coreControllerStop:(id)sender;
@end

@protocol CoreControllerDelegate
-(void) playbackOpened:(id)coreController;
-(void) playbackStarted:(id)coreController;
-(void) playbackWillStop:(id)coreController;
-(void) playbackStopped:(id)coreController info:(NSDictionary*)dict;
-(void) playbackError:(id)coreController;
@end

@protocol SubConverterDelegate
/** \return 返回值需要符合IANA标准, 或者nil不改变当前值 */
-(NSString*) subConverter:(id)subConv detectedFile:(NSString*)path ofCharsetName:(NSString*)charsetName confidence:(float)confidence;
@end

// 如果要得到log解析后的结果，可以用这个delegate函数
// 返回的是A=B字符串中，A为key，B为value的Dict
@protocol LogAnalyzerDelegate
-(void) logAnalyzeFinished:(NSDictionary*) dict;
@end

/////////////////////////////////////macros/////////////////////////////////////
// letterBox显示模式
#define kPMLetterBoxModeNotDisplay	(0)
#define kPMLetterBoxModeBottomOnly	(1)
#define kPMLetterBoxModeTopOnly		(2)
#define kPMLetterBoxModeBoth		(3)

// DTS Remix mode
#define kPMMixToStereoNO		(0)
#define kPMMixDTS5_1ToStereo	(1)

/** !!WARNING!! the settings using post process filters should match the marco below */
#define PMShouldUsePPFilters(x)	((x) & 0xC0)
/*************************************************************************
 * WARNING if the values are changed
 * the tags in the preference panel MUST be modified to match the values */
#define kPMDeInterlaceNone		(0x00)
#define kPMDeInterlaceFFMpeg	(0x41)
#define kPMDeInterlaceLPF5		(0x42)
#define kPMDeInterlaceYaMc		(0x03)

#define kPMImgEnhanceNone		(0x00)
#define kPMImgEnhanceNormal		(0x81)
#define kPMImgEnhanceAdvanced	(0x82)
/*************************************************************************/

/**************************************************************************
 * this setting matches libass spec
 * WARNING the tags in preference panel should be synced with these values */
// default means respect the value in the subtitle file
#define kPMSubAlignDefault			(0x00)

// below shoule be used as mask [vertical] | [horinzontal]
#define kPMSubAlignVerticalBottom	(0x00)
#define kPMSubAlignVerticalMiddle	(0x08)
#define kPMSubAlignVerticalTop		(0x04)
#define kPMSubAlignHorizontalLeft	(0x01)
#define kPMSubAlignHorizontalMiddle	(0x02)
#define kPMSubAlignHorizontalRight	(0x03)
/**************************************************************************/

#define kMPCStoppedState	(0x0000)		/**< 完全停止状态 */
#define kMPCOpenedState		(0x0001)		/**< 播放打开，但是还没有开始播放 */
#define kMPCPlayingState	(0x0100)		/**< 正在播放并且没有暂停 */
#define kMPCPausedState		(0x0101)		/**< 有文件正在播放但是暂停中 */

#define kMPCStateMask		(0x0100)

#define kPMSubBorderWidthDefault	(2)
#define kPMAssSubMarginVDefault		(12)

#define kPMPlayDiskNone		(0)
#define kPMPlayDiskDVD		(1)

// Audio Mono output
#define kMPCMonoAudioNone			(0)
#define kMPCMonoAudioStereo			(1)
#define kMPCMonoAudioLeftOnly		(2)
#define kMPCMonoAudioRightOnly		(3)
#define kMPCMonoAudioLeftExpand		(4)
#define kMPCMonoAudioRightExpand	(5)

/////////////////////////////////////strings/////////////////////////////////////
// 指定两种arch的mplayer路径时所用的key
extern NSString * const kI386Key;
extern NSString * const kX86_64Key;

extern NSString * const kPMValDemuxFFMpeg;

extern NSString * const kMPCPlayStoppedByForceKey;
extern NSString * const kMPCPlayStoppedTimeKey;
extern NSString * const kMPCPlayStoppedAbnormalKey;

// KVO观测的属性的KeyPath
extern NSString * const kKVOPropertyKeyPathCurrentTime;
extern NSString * const kKVOPropertyKeyPathLength;
extern NSString * const kKVOPropertyKeyPathSeekable;
extern NSString * const kKVOPropertyKeyPathSubInfo;
extern NSString * const kKVOPropertyKeyPathCachingPercent;
extern NSString * const kKVOPropertyKeyPathDemuxer;
extern NSString * const kKVOPropertyKeyPathSpeed;
extern NSString * const kKVOPropertyKeyPathSubDelay;
extern NSString * const kKVOPropertyKeyPathAudioDelay;

extern NSString * const kKVOPropertyKeyPathVideoInfo;
extern NSString * const kKVOPropertyKeyPathAudioInfo;

extern NSString * const kKVOPropertyKeyPathVideoInfoID;
extern NSString * const kKVOPropertyKeyPathAudioInfoID;

extern NSString * const kKVOPropertyKeyPathChapterInfo;
