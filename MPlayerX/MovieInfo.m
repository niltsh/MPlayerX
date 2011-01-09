/*
 * MPlayerX - MovieInfo.m
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

#import "MovieInfo.h"
#import "coredef_private.h"
#import "ParameterManager.h"

NSString * const kDemuxValueDefault = @"unknown";
NSString * const kMovieInfoKVOSubInfo		= @"subInfo";
NSString * const kMovieInfoKVOAudioInfo		= @"audioInfo";
NSString * const kMovieInfoKVOVideoInfo		= @"videoInfo";

@implementation MovieInfo

@synthesize demuxer;
@synthesize chapters;
@synthesize length;
@synthesize seekable;
@synthesize playingInfo;
@synthesize metaData;
@synthesize videoInfo;
@synthesize audioInfo;
@synthesize subInfo;

-(id) init
{
	self = [super init];
	
	if (self) {
		NSNumber *zero = [NSNumber numberWithInt:0];
		
		demuxer = [kDemuxValueDefault retain];
		chapters = [zero retain];
		length = [zero retain];
		seekable = [zero retain];
		
		playingInfo = [[PlayingInfo alloc] init];
		metaData = [[NSMutableDictionary alloc] init];
		videoInfo = [[NSMutableArray alloc] init];
		audioInfo = [[NSMutableArray alloc] init];
		subInfo = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void) dealloc
{
	[demuxer release];
	[chapters release];
	[length release];
	[seekable release];
	[playingInfo release];
	[metaData release];
	[videoInfo release];
	[audioInfo release];
	[subInfo release];

	[super dealloc];
}

-(AudioInfo*) audioInfoForID:(NSNumber*)audioID
{
	AudioInfo *ret = nil;
	
	if (audioID) {
		NSInteger intID = [audioID intValue];
		
		for (AudioInfo *info in audioInfo) {
			if ([info ID] == intID) {
				ret = info;
				break;
			}
		}
	}
	return ret;
}

-(VideoInfo*) videoInfoForID:(NSNumber*)videoID
{
	VideoInfo *ret = nil;
	
	if (videoID) {
		NSInteger intID = [videoID intValue];
		for (VideoInfo *info in videoInfo) {
			if ([info ID] == intID) {
				ret = info;
				break;
			}
		}
	}
	return ret;
}

-(void) resetWithParameterManager:(ParameterManager*)pm
{
	NSNumber *zero = [NSNumber numberWithInt:0];

	if (pm) {
		[playingInfo resetWithParameterManager:pm];
	}
	
	[metaData removeAllObjects];

	// 目前这两个还不需要KVO
	[self willChangeValueForKey:kMovieInfoKVOVideoInfo];
	[videoInfo removeAllObjects];
	[self didChangeValueForKey:kMovieInfoKVOVideoInfo];
	
	[self willChangeValueForKey:kMovieInfoKVOAudioInfo];
	[audioInfo removeAllObjects];
	[self didChangeValueForKey:kMovieInfoKVOAudioInfo];
	
	// 比较简单的实现KVO的方式，要不会一个一个的删除，效率比较低
	[self willChangeValueForKey:kMovieInfoKVOSubInfo];
	[subInfo removeAllObjects];
	[self didChangeValueForKey:kMovieInfoKVOSubInfo];
	
	[self setSeekable:zero];
	[self setDemuxer:kDemuxValueDefault];
	[self setChapters:zero];
	[self setLength:zero];
	
}
@end
