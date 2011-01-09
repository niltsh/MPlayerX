/*
 * MPlayerX - coredef_private.m
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

// mplayer通信所用的command的字符串
NSString * const kMPCTogglePauseCmd		= @"pause\n";
NSString * const kMPCFrameStepCmd		= @"frame_step\n";
NSString * const kMPCSubSelectCmd		= @"sub_select\n";
NSString * const kMPCSeekCmd			= @"seek";
NSString * const kMPCAssMargin			= @"ass_margin";
NSString * const kMPCAfAddCmd			= @"af_add";
NSString * const kMPCAfDelCmd			= @"af_del";

NSString * const kMPCGetPropertyPreFix	= @"get_property";
NSString * const kMPCSetPropertyPreFix	= @"set_property";
NSString * const kMPCSetPropertyPreFixPauseKeep	= @"pausing_keep_force set_property";
NSString * const kMPCPausingKeepForce	= @"pausing_keep_force";

////////////////////////////////////////////////////////////////////
// 没有ID结尾的是 命令字符串 和 属性字符串 有可能是公用的
NSString * const kMPCTimePos			= @"time_pos";
NSString * const kMPCOsdLevel			= @"osdlevel";
NSString * const kMPCSpeed				= @"speed";
NSString * const kMPCChapter			= @"chapter";
NSString * const kMPCPercentPos			= @"percent_pos";
NSString * const kMPCVolume				= @"volume";
NSString * const kMPCAudioBalance		= @"balance";
NSString * const kMPCMute				= @"mute";
NSString * const kMPCAudioDelay			= @"audio_delay";
NSString * const kMPCSwitchAudio		= @"switch_audio";
NSString * const kMPCSub				= @"sub";
NSString * const kMPCSubDelay			= @"sub_delay";
NSString * const kMPCSubPos				= @"sub_pos";
NSString * const kMPCSubScale			= @"sub_scale";
NSString * const kMPCSubLoad			= @"sub_load";
NSString * const kMPCSwitchVideo		= @"switch_video";
NSString * const kMPCEqualizer			= @"equalizer";
NSString * const kMPCPan				= @"pan";

// 有ID结尾的是 只用来做属性字符串的
NSString * const kMPCLengthID			= @"LENGTH";
NSString * const kMPCSeekableID			= @"SEEKABLE";
NSString * const kMPCSubInfosID			= @"MPXSUBNAMES";
NSString * const kMPCSubInfoAppendID	= @"MPXSUBFILEADD";
NSString * const kMPCCachingPercentID	= @"CACHING";
NSString * const kMPCPlayBackStartedID	= @"PBST";
NSString * const kMPCAudioInfoID		= @"AUDIOINFO";
NSString * const kMPCVideoInfoID		= @"VIDEOINFO";
NSString * const kMPCAudioIDs			= @"AUDIO_IDS";
NSString * const kMPCVideoIDs			= @"VDEO_IDS";
NSString * const kMPCDemuxerID			= @"DEMUXER";

NSString * const kKVOPropertyKeyPathState	= @"state";