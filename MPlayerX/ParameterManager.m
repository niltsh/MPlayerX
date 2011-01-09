/*
 * MPlayerX - ParameterManager.m
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

#import "ParameterManager.h"
#import "CocoaAppendix.h"

NSString * const kPMDefaultAudioOutput	= @"coreaudio"; 
NSString * const kPMDefaultVideoOutput	= @"corevideo"; 
NSString * const kPMDefaultSubLang		= @"en,eng,ch,chs,cht,ja,jpn";

NSString * const kPMParMsgLevel		= @"-msglevel";
NSString * const kPMValMsgLevel		= @"all=-1:global=4:cplayer=4:identify=4";
NSString * const kPMFMTInt			= @"%d";
NSString * const kPMParSlave		= @"-slave";
NSString * const kPMParFrameDrop	= @"-framedrop";
NSString * const kPMParForceIdx		= @"-forceidx";
NSString * const kPMParNoDouble		= @"-nodouble";
NSString * const kPMParCache		= @"-cache";
NSString * const kPMParIPV6			= @"-prefer-ipv6";
NSString * const kPMParIPV4			= @"-prefer-ipv4";
NSString * const kPMParOsdLevel		= @"-osdlevel";
NSString * const kPMParSubFuzziness	= @"-sub-fuzziness";
NSString * const kPMParFont			= @"-font";
NSString * const kPMParAudioOut		= @"-ao";
NSString * const kPMParVideoOut		= @"-vo";
NSString * const kPMFMTVO			= @"%@:shared_buffer:buffer_name=%@";
NSString * const kPMParSLang		= @"-slang";
NSString * const kPMFMTNSObj		= @"%@";
NSString * const kPMParStartTime	= @"-ss";
NSString * const kPMFMTFloat1		= @"%.1f";
NSString * const kPMParVolume		= @"-volume";
NSString * const kPMFMTFloat2		= @"%.2f";
NSString * const kPMFMTHex			= @"%X";
NSString * const kPMParSubPos		= @"-subpos";
NSString * const kPMParSubAlign		= @"-subalign";
NSString * const kPMParOSDScale		= @"-subfont-osd-scale";
NSString * const kPMParTextScale	= @"-subfont-text-scale";
NSString * const kPMBlank			= @"";
NSString * const kPMParSubFont		= @"-subfont";
NSString * const kPMParSubCP		= @"-subcp";
NSString * const kPMParSubFontAutoScale	= @"-subfont-autoscale";
NSString * const kPMVal1				= @"1";
NSString * const kPMVal2				= @"2";
NSString * const kPMParEmbeddedFonts	= @"-embeddedfonts";
NSString * const kPMParNoEmbeddedFonts	= @"-noembeddedfonts";
NSString * const kPMParLavdopts			= @"-lavdopts";
NSString * const kPMFMTThreads			= @"threads=%d";
NSString * const kPMParAss				= @"-ass";
NSString * const kPMParAssColor			= @"-ass-color";
NSString * const kPMParAssFontScale		= @"-ass-font-scale";
NSString * const kPMParAssBorderColor	= @"-ass-border-color";
NSString * const kPMParAssForcrStyle	= @"-ass-force-style";
NSString * const kPMParAssUsesMargin	= @"-ass-use-margins";
NSString * const kPMParAssBottomMargin	= @"-ass-bottom-margin";
NSString * const kPMParAssTopMargin		= @"-ass-top-margin";
NSString * const kPMParNoAutoSub		= @"-noautosub";
NSString * const kPMParSub				= @"-sub";
NSString * const kPMComma				= @",";
NSString * const kPMParVobSub			= @"-vobsub";
NSString * const kPMParAC				= @"-ac";
NSString * const kPMParHWDTS			= @"hwdts,";
NSString * const kPMParHWAC3			= @"hwac3,a52,";
NSString * const kPMParSTPause			= @"-stpause";
NSString * const kPMParDemuxer			= @"-demuxer";
NSString * const kPMValDemuxFFMpeg		= @"lavf";
NSString * const kPMParOverlapSub		= @"-overlapsub";
NSString * const kPMParRtspOverHttp		= @"-rtsp-stream-over-http";
NSString * const kPMParMsgCharset		= @"-msgcharset";
NSString * const kPMValMsgCharset		= @"noconv";
NSString * const kPMParChannels			= @"-channels";
NSString * const kPMParAf				= @"-af";
NSString * const kPMValScaletempo		= @"scaletempo";
NSString * const kPMParVf				= @"-vf";

NSString * const kPMParFieldDominance	= @"-field-dominance";
NSString * const kPMSubParValYadif		= @"yadif=1";
NSString * const kPMSubParValMcDet		= @"mcdeint=2:1:5";

NSString * const kPMSubParPPFD			= @"fd";
NSString * const kPMSubParPPL5			= @"l5";
NSString * const kPMSubParImgEnhNorm	= @"hb:a/vb:a/dr:a";
NSString * const kPMSubParImgEnhAdv		= @"ha:a/va:a/dr:a";
NSString * const kPMSubParPPFilter		= @"pp=";

NSString * const kPMSlash				= @"/";

#define kSubScaleNoAss		(8.0)

@implementation ParameterManager

@synthesize subNameRule;
@synthesize prefer64bMPlayer;
@synthesize guessSubCP;
@synthesize startTime;
@synthesize volume;
@synthesize subPos;
@synthesize subAlign;
@synthesize subScale;
@synthesize subFont;
@synthesize subCP;
@synthesize threads;
@synthesize textSubs;
@synthesize vobSub;
@synthesize forceIndex;
@synthesize dtsPass;
@synthesize ac3Pass;
@synthesize useEmbeddedFonts;
@synthesize cache;
@synthesize preferIPV6;
@synthesize letterBoxMode;
@synthesize letterBoxHeight;
@synthesize pauseAtStart;
@synthesize overlapSub;
@synthesize rtspOverHttp;
@synthesize mixToStereo;
@synthesize demuxer;
@synthesize deinterlace;
@synthesize imgEnhance;
@synthesize extraOptions;

#pragma mark Init/Dealloc
-(id) init
{
	self = [super init];
	
	if (self) {
		paramArray = nil;
		frameDrop = NO;
		osdLevel = 0;
		subNameRule = kSubFileNameRuleContain;
		// 默认禁用-font
		font = nil;
		ao = [[NSString alloc] initWithString:kPMDefaultAudioOutput];
		vo = [[NSString alloc] initWithString:kPMDefaultVideoOutput];
		subPreferedLanguage = [[NSString alloc] initWithString:kPMDefaultSubLang];
		
		assEnabled = YES;
		frontColor = 0xFFFFFF00; //RRGGBBAA
		borderColor = 0x0000000F; //RRGGBBAA
		assForceStyle = [NSString stringWithString:@"BorderStyle=1,Outline=1,MarginV=2"];
		
		prefer64bMPlayer = YES;
		guessSubCP = YES;
		startTime = -1;
		volume = 100;
		subPos = 100;
		subAlign = 2;
		subScale = 1.5;
		subFont = nil;
		subCP = nil;
		threads = 1;
		textSubs = nil;
		vobSub = nil;
		forceIndex = NO;
		dtsPass = NO;
		ac3Pass = NO;
		useEmbeddedFonts = NO;
		cache = 1000;
		preferIPV6 = NO;
		letterBoxMode = kPMLetterBoxModeNotDisplay;
		letterBoxHeight = 0.1;
		pauseAtStart = NO;
		overlapSub = NO;
		rtspOverHttp = NO;
		mixToStereo = kPMMixDTS5_1ToStereo;
		demuxer = nil;
		deinterlace = kPMDeInterlaceNone;
		imgEnhance = kPMImgEnhanceNone;
		
		extraOptions = nil;
	}
	return self;
}

-(void) dealloc
{
	[paramArray release];
	[font release];
	[ao release];
	[vo release];
	[subPreferedLanguage release];
	[subFont release];
	[subCP release];
	[textSubs release];
	[vobSub release];
	[extraOptions release];
	
	[super dealloc];
}

-(void) setSubFontColor:(NSColor*)col
{
	frontColor = [col hexValue];
}

-(void) setSubFontBorderColor:(NSColor*)col
{
	borderColor = [col hexValue];
}

-(void) reset
{
	SAFERELEASE(vobSub);
	SAFERELEASE(textSubs);
}

-(NSArray *) arrayOfParametersWithName:(NSString*) name
{
	BOOL useVideoFilters = NO;
	BOOL usePPFilters    = NO;
	
	if (paramArray) {
		[paramArray removeAllObjects];
	} else {
		paramArray = [[NSMutableArray alloc] initWithCapacity:80];
	}
	
	if (demuxer) {
		[paramArray addObject:kPMParDemuxer];
		[paramArray addObject:demuxer];
	}
	
	[paramArray addObject:kPMParMsgLevel];
	[paramArray addObject:kPMValMsgLevel];
	
	[paramArray addObject:kPMParMsgCharset];
	[paramArray addObject:kPMValMsgCharset];

	[paramArray addObject:kPMParSlave];
	
	if (frameDrop) {
		[paramArray addObject:kPMParFrameDrop];
	}
	
	if (forceIndex) {
		[paramArray addObject:kPMParForceIdx];
	}

	[paramArray addObject:kPMParNoDouble];
	
	if (cache > 0) {
		[paramArray addObject:kPMParCache];
		[paramArray addObject:[NSString stringWithFormat:kPMFMTInt, cache]];
	}
	
	if (preferIPV6) {
		[paramArray addObject:kPMParIPV6];
	} else {
		[paramArray addObject:kPMParIPV4];
	}
	
	if (rtspOverHttp) {
		[paramArray addObject:kPMParRtspOverHttp];
	}
	
	[paramArray addObject:kPMParOsdLevel];
	[paramArray addObject: [NSString stringWithFormat: kPMFMTInt,osdLevel]];
	
	[paramArray addObject:kPMParSubFuzziness];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTInt,subNameRule]];
	
	if (font) {
		[paramArray addObject:kPMParFont];
		[paramArray addObject:font];
	}
	
	if (ao) {
		[paramArray addObject:kPMParAudioOut];
		[paramArray addObject:ao];
	}
	
	if (vo) {
		[paramArray addObject:kPMParVideoOut];
		if (([vo isEqualToString:kPMDefaultVideoOutput]) && name) {
			[paramArray addObject: [NSString stringWithFormat:kPMFMTVO, vo, name]];
		} else {
			[paramArray addObject:vo];
		}
	}
	
	if (subPreferedLanguage) {
		[paramArray addObject:kPMParSLang];
		[paramArray addObject:[NSString stringWithFormat:kPMFMTNSObj, subPreferedLanguage]];		
	}
	
	if (startTime > 0) {
		[paramArray addObject:kPMParStartTime];
		[paramArray addObject:[NSString stringWithFormat:kPMFMTFloat1, startTime]];
	}
	
	[paramArray addObject:kPMParVolume];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1,GetRealVolume(volume)]];
	
	[paramArray addObject:kPMParSubPos];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTInt,((unsigned int)subPos)]];
	
	[paramArray addObject:kPMParSubAlign];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTInt,subAlign]];
	
	[paramArray addObject:kPMParOSDScale];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1,kSubScaleNoAss]];
	
	[paramArray addObject:kPMParTextScale];
	[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1,kSubScaleNoAss]];
	
	if (subFont && (![subFont isEqualToString:kPMBlank])) {
		[paramArray addObject:kPMParSubFont];
		[paramArray addObject:subFont];
	}

	if (subCP && (![subCP isEqualToString:kPMBlank])) {
		[paramArray addObject:kPMParSubCP];
		[paramArray addObject:subCP];
	}
	
	// 字幕大小与高度成正比，默认是对角线长度
	[paramArray addObject:kPMParSubFontAutoScale];
	[paramArray addObject:kPMVal1];
	
	if (useEmbeddedFonts) {
		[paramArray addObject:kPMParEmbeddedFonts];
	} else {
		[paramArray addObject:kPMParNoEmbeddedFonts];
	}
	
	if (overlapSub) {
		[paramArray addObject:kPMParOverlapSub];
	}
	
	if (threads > 1) {
		[paramArray addObject:kPMParLavdopts];
		[paramArray addObject:[NSString stringWithFormat: kPMFMTThreads, threads]];		
	}

	if (assEnabled) {
		[paramArray addObject:kPMParAss];
		
		[paramArray addObject:kPMParAssColor];
		[paramArray addObject:[NSString stringWithFormat: kPMFMTHex, frontColor]];
		
		[paramArray addObject:kPMParAssFontScale];
		[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat1, subScale]];
		
		[paramArray addObject:kPMParAssBorderColor];
		[paramArray addObject:[NSString stringWithFormat: kPMFMTHex, borderColor]];
		
		[paramArray addObject:kPMParAssForcrStyle];
		[paramArray addObject:assForceStyle];
		
		// 目前只有在使用ass的时候，letterbox才有用
		// 但是将来也许不用ass也要实现letter box
		if (letterBoxMode != kPMLetterBoxModeNotDisplay) {
			// 说明要显示letterBox，那么至少会显示bottom
			// 字幕显示在letterBox里
			[paramArray addObject:kPMParAssUsesMargin];
			
			if ((letterBoxMode == kPMLetterBoxModeBoth) || (letterBoxMode == kPMLetterBoxModeBottomOnly)) {
				[paramArray addObject:kPMParAssBottomMargin];
				[paramArray addObject:[NSString stringWithFormat:kPMFMTFloat2, letterBoxHeight]];
			}
			
			if ((letterBoxMode == kPMLetterBoxModeBoth) || (letterBoxMode == kPMLetterBoxModeTopOnly)) {
				// 还要显示top margin
				[paramArray addObject:kPMParAssTopMargin];
				[paramArray addObject:[NSString stringWithFormat: kPMFMTFloat2, letterBoxHeight]];
			}
		}
	}
	
	if (guessSubCP) {
		[paramArray addObject:kPMParNoAutoSub];
	}

	if (textSubs && [textSubs count]) {
		[paramArray addObject:kPMParSub];	
		[paramArray addObject:[textSubs componentsJoinedByString:kPMComma]];
	}
	
	if (vobSub && (![vobSub isEqualToString:kPMBlank])) {
		[paramArray addObject:kPMParVobSub];
		[paramArray addObject:[vobSub stringByDeletingPathExtension]];
	}

	if (dtsPass || ac3Pass) {
		[paramArray addObject:kPMParAC];
		NSString *passStr = kPMBlank;
		if (dtsPass) {
			passStr = [passStr stringByAppendingString:kPMParHWDTS];
		}
		if (ac3Pass) {
			passStr = [passStr stringByAppendingString:kPMParHWAC3];
		}
		[paramArray addObject:passStr];
	} else if (mixToStereo == kPMMixDTS5_1ToStereo) {
		[paramArray addObject:kPMParChannels];
		[paramArray addObject:kPMVal2];
	}

	if (pauseAtStart) {
		[paramArray addObject:kPMParSTPause];
	}
	
	// setting for audio filters
	[paramArray addObject:kPMParAf];
	[paramArray addObject:kPMValScaletempo];
	
	if (PMShouldUsePPFilters(imgEnhance)) {
		useVideoFilters = YES;
		usePPFilters = YES;
	}
	
	// video filters
	if (PMShouldUsePPFilters(deinterlace)) {
		// use PP filters
		useVideoFilters = YES;
		usePPFilters = YES;
		
	} else if (deinterlace == kPMDeInterlaceYaMc) {
		// use vf with Yaif and MC
		useVideoFilters = YES;
		[paramArray addObject:kPMParFieldDominance];
		[paramArray addObject:kPMVal1];
	}

	// -vf <filter1[=parameter1:parameter2:...],filter2,...>
	if (useVideoFilters) {
		NSMutableArray *vfSettings = [[NSMutableArray alloc] initWithCapacity:4];
		
		if (deinterlace == kPMDeInterlaceYaMc) {
			[vfSettings addObject:kPMSubParValYadif];
			[vfSettings addObject:kPMSubParValMcDet];
		}
		
		if (usePPFilters) {
			// pp[=filter1[:option1[:option2...]]/[-]filter2...]
			NSMutableArray* ppSettings = [[NSMutableArray alloc] initWithCapacity:4];
			
			if (deinterlace == kPMDeInterlaceFFMpeg) {
				// (-1 4 2 4 -1)
				[ppSettings addObject:kPMSubParPPFD];
			} else if (deinterlace == kPMDeInterlaceLPF5) {
				// (-1 2 6 2 -1)
				[ppSettings addObject:kPMSubParPPL5];
			}
			
			if (imgEnhance == kPMImgEnhanceNormal) {
				// normal deblock
				[ppSettings addObject:kPMSubParImgEnhNorm];
			} else if (imgEnhance == kPMImgEnhanceAdvanced) {
				// accurate deblock
				[ppSettings addObject:kPMSubParImgEnhAdv];
			}
			[vfSettings addObject:[kPMSubParPPFilter stringByAppendingString:[ppSettings componentsJoinedByString:kPMSlash]]];

			[ppSettings release];
		}
		[paramArray addObject:kPMParVf];
		[paramArray addObject:[vfSettings componentsJoinedByString:kPMComma]];
		
		[vfSettings release];
	}

	if (extraOptions) {
		NSArray *extrasArray = [extraOptions componentsSeparatedByString:@" "];
		
		if (extrasArray) {
			for (NSString *str in extrasArray) {
				if (str && (![str isEqualToString:@""])) {
					[paramArray addObject:str];
				}
			}
		}
	}

	return paramArray;
}

@end
