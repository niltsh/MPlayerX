/*
 * MPlayerX - PlayingInfo.h
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

@class ParameterManager;

#define kPIAudioIDInvalid	(-1)
#define kPIVideoIDInvalid	(-1)

@interface PlayingInfo : NSObject 
{
	unsigned char	currentChapter;
	NSNumber		*currentTime;
	NSNumber		*currentAudioID;
	NSNumber		*currentVideoID;
	unsigned char	currentSub;
	
	float volume;
	float audioBalance;
	BOOL  mute;
	NSNumber *audioDelay;
	NSNumber *subDelay;
	float subPos;
	NSNumber *subScale;
	NSNumber *speed;
	NSNumber *cachingPercent;
}

@property(assign, readwrite) unsigned char	currentChapter;
@property(retain, readwrite) NSNumber		*currentTime;
@property(retain, readwrite) NSNumber		*currentAudioID;
@property(retain, readwrite) NSNumber		*currentVideoID;
@property(assign, readwrite) unsigned char	currentSub;

@property(assign, readwrite) float volume;
@property(assign, readwrite) float audioBalance;
@property(assign, readwrite) BOOL  mute;
@property(retain, readwrite) NSNumber *audioDelay;
@property(retain, readwrite) NSNumber *subDelay;
@property(assign, readwrite) float subPos;
@property(retain, readwrite) NSNumber *subScale;
@property(retain, readwrite) NSNumber *speed;
@property(retain, readwrite) NSNumber *cachingPercent;

-(void) resetWithParameterManager:(ParameterManager*)pm;

@end
