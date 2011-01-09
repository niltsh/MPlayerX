/*
 * MPlayerX - coredef_private.h
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

#import "coredef.h"

#define GetRealVolume(x)		(0.01*(x)*(x))

// mplayer通信所用的command的字符串
extern NSString * const kMPCTogglePauseCmd;
extern NSString * const kMPCFrameStepCmd;
extern NSString * const kMPCSubSelectCmd;
extern NSString * const kMPCSeekCmd;
extern NSString * const kMPCAssMargin;
extern NSString * const kMPCAfAddCmd;
extern NSString * const kMPCAfDelCmd;

extern NSString * const kMPCGetPropertyPreFix;
extern NSString * const kMPCSetPropertyPreFix;
extern NSString * const kMPCSetPropertyPreFixPauseKeep;
extern NSString * const kMPCPausingKeepForce;

////////////////////////////////////////////////////////////////////
// 没有ID结尾的是 命令字符串 和 属性字符串 有可能是公用的
extern NSString * const kMPCTimePos;
extern NSString * const kMPCOsdLevel;
extern NSString * const kMPCSpeed;
extern NSString * const kMPCChapter;
extern NSString * const kMPCPercentPos;
extern NSString * const kMPCVolume;
extern NSString * const kMPCAudioBalance;
extern NSString * const kMPCMute;
extern NSString * const kMPCAudioDelay;
extern NSString * const kMPCSwitchAudio;
extern NSString * const kMPCSub;
extern NSString * const kMPCSubDelay;
extern NSString * const kMPCSubPos;
extern NSString * const kMPCSubScale;
extern NSString * const kMPCSubLoad;
extern NSString * const kMPCSwitchVideo;
extern NSString * const kMPCEqualizer;
extern NSString * const kMPCPan;

// 有ID结尾的是 只用来做属性字符串的
extern NSString * const kMPCLengthID;
extern NSString * const kMPCSeekableID;
extern NSString * const kMPCSubInfosID;
extern NSString * const kMPCSubInfoAppendID;
extern NSString * const kMPCCachingPercentID;
extern NSString * const kMPCPlayBackStartedID;
extern NSString * const kMPCAudioInfoID;
extern NSString * const kMPCVideoInfoID;
extern NSString * const kMPCAudioIDs;
extern NSString * const kMPCVideoIDs;
extern NSString * const kMPCDemuxerID;

extern NSString * const kKVOPropertyKeyPathState;