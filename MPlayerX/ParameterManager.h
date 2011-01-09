/*
 * MPlayerX - ParameterManager.h
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
#import "coredef_private.h"

@interface ParameterManager : NSObject 
{
	NSMutableArray *paramArray;
	
	SUBFILE_NAMERULE subNameRule;
	NSString *font;
	NSString *ao;
	NSString *vo;
	NSString *subPreferedLanguage;
	
	uint32 frontColor;
	uint32 borderColor;
	NSString *assForceStyle;
	BOOL assEnabled;

	// unsigned char autoSync;
	BOOL frameDrop;
	unsigned char osdLevel;
	
	// accessable variables
	NSArray *textSubs;
	NSString *vobSub;
	NSString *subFont;
	NSString *subCP;
	float startTime;
	float volume;
	float subPos;
	float subScale;
	unsigned int threads;
	unsigned int cache;
	unsigned int letterBoxMode;
	float letterBoxHeight;
	unsigned char subAlign;
	BOOL prefer64bMPlayer;
	BOOL guessSubCP;
	BOOL forceIndex;
	BOOL dtsPass;
	BOOL ac3Pass;
	BOOL fastDecoding;
	BOOL useEmbeddedFonts;
	BOOL preferIPV6;
	BOOL pauseAtStart;
	BOOL overlapSub;
	BOOL rtspOverHttp;
	unsigned int mixToStereo;
	NSString *demuxer;
	unsigned int deinterlace;
	unsigned int imgEnhance;
	NSString *extraOptions;
}

@property (assign, readwrite) SUBFILE_NAMERULE subNameRule;
@property (assign, readwrite) BOOL prefer64bMPlayer;
@property (assign, readwrite) BOOL guessSubCP;
@property (assign, readwrite) float startTime;
@property (assign, readwrite) float volume;
@property (assign, readwrite) float subPos;
@property (assign, readwrite) unsigned char subAlign;
@property (assign, readwrite) float subScale;
@property (retain, readwrite) NSString *subFont;
@property (retain, readwrite) NSString *subCP;
@property (assign, readwrite) unsigned int threads;
@property (retain, readwrite) NSArray *textSubs;
@property (retain, readwrite) NSString *vobSub;
@property (assign, readwrite) BOOL forceIndex;
@property (assign, readwrite) BOOL dtsPass;
@property (assign, readwrite) BOOL ac3Pass;
@property (assign, readwrite) BOOL useEmbeddedFonts;
@property (assign, readwrite) unsigned int cache;
@property (assign, readwrite) BOOL preferIPV6;
@property (assign, readwrite) unsigned int letterBoxMode;
@property (assign, readwrite) float letterBoxHeight;
@property (assign, readwrite) BOOL pauseAtStart;
@property (assign, readwrite) BOOL overlapSub;
@property (assign, readwrite) BOOL rtspOverHttp;
@property (assign, readwrite) unsigned int mixToStereo;
@property (retain, readwrite) NSString *demuxer;
@property (assign, readwrite) unsigned int deinterlace;
@property (assign, readwrite) unsigned int imgEnhance;
@property (retain, readwrite) NSString *extraOptions;

-(void) setSubFontColor:(NSColor*)col;
-(void) setSubFontBorderColor:(NSColor*)col;

-(NSArray *) arrayOfParametersWithName:(NSString*) name;

-(void) reset;

@end
