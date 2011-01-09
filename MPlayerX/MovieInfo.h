/*
 * MPlayerX - MovieInfo.h
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
#import "PlayingInfo.h"
#import "SubInfo.h"
#import "VideoInfo.h"
#import "AudioInfo.h"

extern NSString * const kMovieInfoKVOSubInfo;
extern NSString * const kMovieInfoKVOAudioInfo;
extern NSString * const kMovieInfoKVOVideoInfo;

@class ParameterManager;

@interface MovieInfo : NSObject
{
	NSString *demuxer;
	NSNumber *chapters;
	NSNumber *length;
	NSNumber *seekable;
	
	PlayingInfo *playingInfo;
	
	NSMutableDictionary *metaData;
	
	NSMutableArray *videoInfo;
	NSMutableArray *audioInfo;
	NSMutableArray *subInfo;
}

@property (retain, readwrite) NSString *demuxer;
@property (retain, readwrite) NSNumber *chapters;
@property (retain, readwrite) NSNumber *length;
@property (retain, readwrite) NSNumber *seekable;

@property (retain, readwrite) PlayingInfo *playingInfo;

@property (retain, readwrite) NSMutableDictionary *metaData;

@property (retain, readwrite) NSMutableArray *videoInfo;
@property (retain, readwrite) NSMutableArray *audioInfo;
@property (retain, readwrite) NSMutableArray *subInfo;

-(void) resetWithParameterManager:(ParameterManager*)pm;
-(AudioInfo*) audioInfoForID:(NSNumber*)audioID;
-(VideoInfo*) videoInfoForID:(NSNumber*)videoID;
@end
