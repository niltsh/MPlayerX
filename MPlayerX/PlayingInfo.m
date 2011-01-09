/*
 * MPlayerX - PlayingInfo.m
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

#import "PlayingInfo.h"
#import "ParameterManager.h"

@implementation PlayingInfo

@synthesize	currentChapter;
@synthesize	currentTime;
@synthesize	currentAudioID;
@synthesize currentVideoID;
@synthesize	currentSub;

@synthesize	volume;
@synthesize	audioBalance;
@synthesize	mute;
@synthesize	audioDelay;
@synthesize	subDelay;
@synthesize	subPos;
@synthesize	subScale;
@synthesize speed;
@synthesize cachingPercent;

-(id) init
{
	self = [super init];
	
	if (self) {
		NSNumber *floatZero = [NSNumber numberWithFloat:0.0];
		
		currentChapter = 0;
		currentTime = [floatZero retain];
		currentAudioID = nil;
		currentVideoID = nil;
		currentSub = 0;
		volume = 100;
		audioBalance = 0;
		mute = NO;
		audioDelay = [floatZero retain];
		subDelay = [floatZero retain];
		subPos = 100;
		subScale = [[NSNumber alloc] initWithFloat:1.5];
		speed = [[NSNumber alloc] initWithFloat:1.0];
		cachingPercent = [floatZero retain];
	}
	return self;
}

-(void) dealloc
{
	[currentTime release];
	[audioDelay release];
	[subDelay release];
	[speed release];
	[subScale release];
	[cachingPercent release];
	
	[currentAudioID release];
	[currentVideoID release];
	
	[super dealloc];
}

-(void) resetWithParameterManager:(ParameterManager*)pm
{
	NSNumber *floatZero = [NSNumber numberWithFloat:0.0];
	
	currentChapter = 0;
	currentSub = 0;
	// 将来可能都会用到KVO
	[self setAudioBalance:0];
	
	[self setVolume:pm.volume];
	[self setSubPos:pm.subPos];
	[self setSubScale:[NSNumber numberWithFloat:[pm subScale]]];
	
	[self setMute:NO];
	[self setCurrentTime:floatZero];
	[self setAudioDelay:floatZero];
	[self setSubDelay:floatZero];
	[self setSpeed:[NSNumber numberWithFloat:1]];
	[self setCachingPercent:floatZero];

	[self setCurrentAudioID:nil];
	[self setCurrentVideoID:nil];
}
@end
