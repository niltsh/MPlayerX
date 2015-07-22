/*
 * MPlayerX - AudioInfo.m
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

#import "AudioInfo.h"


@implementation AudioInfo

@synthesize ID;
@synthesize language;
@synthesize name;
@synthesize codec;
@synthesize format;
@synthesize bitRate;
@synthesize sampleRate;
@synthesize sampleSize;
@synthesize channels;

-(id) init
{
	self = [super init];

	if (self) {
		ID = -2;
		language = nil;
		name = nil;
		codec = nil;
		format = nil;
		bitRate = 0;
		sampleRate = 0;
		sampleSize = 0;
		channels = 0;
	}
	return self;
}

-(void) dealloc
{
	[codec release];
	[language release];
	[name release];
	[format release];
	
	[super dealloc];
}

-(void) setInfoDataWithArray:(NSArray*)arr
{
	if ([arr count] >= 7) {
		[self setFormat:[arr objectAtIndex:1]];
		[self setBitRate:[[arr objectAtIndex:2] intValue]];
		[self setSampleRate:[[arr objectAtIndex:3] intValue]];
		[self setSampleSize:[[arr objectAtIndex:4] intValue] * 8];
		[self setChannels:[[arr objectAtIndex:5] intValue]];
		[self setCodec:[arr objectAtIndex:6]];	
	}	
}

-(NSString*) description
{
	NSString *strName = (name)?(name):(@"noname");
	NSString *strLang = (language)?(language):(@"unknown");
 	
	return [NSString stringWithFormat:@"%d: %@ [%@]", ID, strName, strLang];
}

@end
