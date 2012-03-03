/*
 * MPlayerX - VideoInfo.h
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

#import <Cocoa/Cocoa.h>


@interface VideoInfo : NSObject
{
	int ID;
	NSString *language;
	NSString *name;
	
	NSString *codec;
	NSString *format;
	int bitRate;
	int width;
	int height;
	float fps;
	float aspect;
}
@property(assign, readwrite) int ID;
@property(retain, readwrite) NSString *language;
@property(retain, readwrite) NSString *name;

@property (retain, readwrite) NSString *codec;
@property (retain, readwrite) NSString *format;
@property (assign, readwrite) int bitRate;
@property (assign, readwrite) int width;
@property (assign, readwrite) int height;
@property (assign, readwrite) float fps;
@property (assign, readwrite) float aspect;

/**
 * What is in the arr?
 * [0] Not used (actually the ID of VI)
 * [1] Format
 * [2] BitRate
 * [3] Width
 * [4] Height
 * [5] Frames per second
 * [6] Aspect ratio
 * [7] Codec name
 *
 * This definition is depended on mplayer,
 * should de-coupling with mplayer
 *
 */
-(void) setInfoDataWithArray:(NSArray*)arr;

@end
