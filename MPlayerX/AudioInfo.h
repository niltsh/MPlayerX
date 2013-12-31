/*
 * MPlayerX - AudioInfo.h
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


@interface AudioInfo : NSObject 
{
	int ID;
	NSString *language;
	NSString *name;
	
	NSString *codec;
	NSString *format;
	int bitRate;
	int sampleRate;
	int sampleSize;
	int channels;
}
@property(assign, readwrite) int ID;
@property(retain, readwrite) NSString *language;
@property(retain, readwrite) NSString *name;

@property(retain, readwrite) NSString *codec;
@property(retain, readwrite) NSString *format;
@property(assign, readwrite) int bitRate;
@property(assign, readwrite) int sampleRate;
@property(assign, readwrite) int sampleSize;
@property(assign, readwrite) int channels;

/**
 * What is in the arr?
 * [0] Not used (actually this is ID of the AI now)
 * [1] Format
 * [2] BitRate
 * [3] SampleRate
 * [4] Bits per Sample
 * [5] Number of channels
 * [6] Codec name
 *
 * This definition is depended on the output of mplayer.
 * should de-coupling with mplayer
 */
-(void) setInfoDataWithArray:(NSArray*)arr;
@end
