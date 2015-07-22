/*
 * MPlayerX - ChapterItem.m
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

#import "ChapterItem.h"
#import "TimeFormatter.h"

@implementation ChapterItem

@synthesize name;
@synthesize start;
@synthesize end;

-(id) init
{
	self = [super init];
	
	if (self) {
		name = nil;
		start = 0;
		end = 0;
	}
	return self;
}

-(void) dealloc
{
	[name release];
	[super dealloc];
}

-(NSString*) description
{
	return [NSString stringWithFormat:@"%@ [%@ - %@]", 
			name,
			[TimeFormatter stringForIntegerValue:start / kMPCChapterTimeBase],
			[TimeFormatter stringForIntegerValue:end   / kMPCChapterTimeBase]]; 
}
@end
