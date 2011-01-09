/*
 * MPlayerX - VideoInfo.m
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

#import "VideoInfo.h"


@implementation VideoInfo

@synthesize ID;
@synthesize language;
@synthesize codec;
@synthesize format;
@synthesize bitRate;
@synthesize width;
@synthesize height;
@synthesize fps;
@synthesize aspect;

-(id) init
{
	self = [super init];
	
	if (self) {
		ID = -2;
		language = nil;
		codec = nil;
		format = nil;
		bitRate = 0;
		width = 0;
		height = 0;
		fps = 0;
		aspect = 0;
	}
	return self;
}

-(void) dealloc
{
	[language release];
	[codec release];
	[format release];
	
	[super dealloc];
}

-(void) setInfoDataWithArray:(NSArray*)arr
{
	if ([arr count] >= 8) {
		[self setFormat:[arr objectAtIndex:1]];
		[self setBitRate:[[arr objectAtIndex:2] intValue]];
		[self setWidth:[[arr objectAtIndex:3] intValue]];
		[self setHeight:[[arr objectAtIndex:4] intValue]];
		[self setFps:[[arr objectAtIndex:5] floatValue]];
		[self setAspect:[[arr objectAtIndex:6] floatValue]];
		[self setCodec:[arr objectAtIndex:7]];	
	}
}

-(NSString*) description
{
	NSString *str = (language)?(language):(@"unknown");
	
	return [NSString stringWithFormat:@"%d: %@", ID, str];
}

@end
