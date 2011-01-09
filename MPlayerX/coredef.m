/*
 * MPlayerX - coredef.m
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

// 指定两种arch的mplayer路径时所用的key
NSString * const kI386Key	= @"i386";
NSString * const kX86_64Key	= @"x86_64";

// KVO观测的属性的KeyPath
NSString * const kKVOPropertyKeyPathCurrentTime		= @"movieInfo.playingInfo.currentTime";
NSString * const kKVOPropertyKeyPathLength			= @"movieInfo.length";
NSString * const kKVOPropertyKeyPathSeekable		= @"movieInfo.seekable";
NSString * const kKVOPropertyKeyPathSubInfo			= @"movieInfo.subInfo";
NSString * const kKVOPropertyKeyPathCachingPercent	= @"movieInfo.playingInfo.cachingPercent";
NSString * const kKVOPropertyKeyPathDemuxer			= @"movieInfo.demuxer";
NSString * const kKVOPropertyKeyPathSpeed			= @"movieInfo.playingInfo.speed";
NSString * const kKVOPropertyKeyPathSubDelay		= @"movieInfo.playingInfo.subDelay";
NSString * const kKVOPropertyKeyPathAudioDelay		= @"movieInfo.playingInfo.audioDelay";

NSString * const kKVOPropertyKeyPathVideoInfo		= @"movieInfo.videoInfo";
NSString * const kKVOPropertyKeyPathAudioInfo		= @"movieInfo.audioInfo";
NSString * const kKVOPropertyKeyPathVideoInfoID		= @"movieInfo.playingInfo.currentVideoID";
NSString * const kKVOPropertyKeyPathAudioInfoID		= @"movieInfo.playingInfo.currentAudioID";
