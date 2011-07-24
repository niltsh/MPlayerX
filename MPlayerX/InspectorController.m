/*
 * MPlayerX - InspectorController.m
 *
 * Copyright (C) 2009 - 2011, Zongyao QU
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

#import "InspectorController.h"
#import "PlayerController.h"
#import "CocoaAppendix.h"
#import "LocalizedStrings.h"

#define kLoadMIMaskClear		(0x00)
#define kLoadMIMaskFileName		(0x01)
#define kLoadMIMaskSource		(0x02)
#define kLoadMIMaskDemuxer		(0x04)
#define kLoadMIMaskTrackInfo	(0x08)
#define kLoadMIMaskFormat		(0x10)
#define kLoadMIMaskAll			(kLoadMIMaskFileName | kLoadMIMaskSource | kLoadMIMaskDemuxer | kLoadMIMaskTrackInfo | kLoadMIMaskFormat)

static InspectorController *sharedInstance = nil;
static BOOL init_ed = NO;

@interface InspectorController (InspectorControllerInternal)
-(void) loadMediaInfo:(NSUInteger) mask;
-(void) playInfoUpdated:(NSNotification*)notif;
-(void) playBackStarted:(NSNotification*)notif;
-(void) playBackStopped:(NSNotification*)notif;
@end

@implementation InspectorController

+(InspectorController*) sharedInspectorController
{
	if (sharedInstance == nil) {
		sharedInstance = [[super allocWithZone:nil] init];
	}
	return sharedInstance;
}

-(id) init
{
	if (init_ed == NO) {
		init_ed = YES;
		
		///////
		nibLoaded = NO;
	}
	return self;
}

+(id) allocWithZone:(NSZone *)zone { return [[self sharedInspectorController] retain]; }
-(id) copyWithZone:(NSZone*)zone { return self; }
-(id) retain { return self; }
-(NSUInteger) retainCount { return NSUIntegerMax; }
-(oneway void) release { }
-(id) autorelease { return self; }

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	sharedInstance = nil;

	[super dealloc];
}

-(void) awakeFromNib
{
	if (!nibLoaded) {
		// 还没有load界面
	}
}

-(IBAction) toggleUI:(id)sender
{
	if (!nibLoaded) {
		nibLoaded = YES;
		[NSBundle loadNibNamed:@"Inspector" owner:self];
		
		[inspectorWin setLevel:NSMainMenuWindowLevel];
		
		[self loadMediaInfo:kLoadMIMaskAll];
		
		NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
		
		/// 从现在开始 监听playerController的Notification
		[notifCenter addObserver:self selector:@selector(playInfoUpdated:)
							name:kMPCPlayInfoUpdatedNotification object:playerController];
		[notifCenter addObserver:self selector:@selector(playBackStarted:)
							name:kMPCPlayStartedNotification object:playerController];
		[notifCenter addObserver:self selector:@selector(playBackStopped:)
							name:kMPCPlayStoppedNotification object:playerController];
	}
	
	if ([inspectorWin isVisible]) {
		[inspectorWin orderOut:self];
	} else {
		[inspectorWin orderFront:self];
	}
}

-(void) playInfoUpdated:(NSNotification*)notif
{
	NSString *keyPath = [[notif userInfo] objectForKey:kMPCPlayInfoUpdatedKeyPathKey];

	if ([keyPath isEqualToString:kKVOPropertyKeyPathSubInfo] ||
		[keyPath isEqualToString:kKVOPropertyKeyPathAudioInfo] ||
		[keyPath isEqualToString:kKVOPropertyKeyPathVideoInfo]) {
		[self loadMediaInfo:kLoadMIMaskTrackInfo];
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathAudioInfoID] ||
			   [keyPath isEqualToString:kKVOPropertyKeyPathVideoInfoID]) {
		[self loadMediaInfo:kLoadMIMaskFormat];
	}
}

-(void) playBackStarted:(NSNotification*)notif
{
	[self loadMediaInfo:(kLoadMIMaskFileName | kLoadMIMaskSource | kLoadMIMaskDemuxer)];
}

-(void) playBackStopped:(NSNotification*)notif
{
	[self loadMediaInfo:kLoadMIMaskClear];
}

-(void) loadMediaInfo:(NSUInteger) mask
{
	if (nibLoaded) {
		// get the media info
		MovieInfo *mi = [playerController mediaInfo];
		
		if (([playerController playerState] != kMPCStoppedState) && mi && (mask != kLoadMIMaskClear)) {

			NSUInteger cnt;
			NSURL *path;
			
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

			path = [playerController lastPlayedPath];

			if (mask & kLoadMIMaskFileName) {
				[filename setStringValue:[path lastPathComponent]];
			}
			
			if (mask & kLoadMIMaskSource) {
				if ([path isFileURL]) {
					[sourceInfo setStringValue:[path path]];
				} else {
					[sourceInfo setStringValue:[path absoluteString]];
				}				
			}

			if (mask & kLoadMIMaskDemuxer) {
				[demuxerInfo setStringValue:[[mi demuxer] uppercaseString]];
			}

			if (mask & kLoadMIMaskTrackInfo) {
				NSMutableArray *tracks = [[NSMutableArray alloc] initWithCapacity:3];
				
				cnt = [[mi videoInfo] count]; if (cnt) { [tracks addObject:[NSString stringWithFormat:kMPXStringInfoTrackInfoVideo, cnt]]; }
				cnt = [[mi audioInfo] count]; if (cnt) { [tracks addObject:[NSString stringWithFormat:kMPXStringInfoTrackInfoAudio, cnt]]; }
				cnt = [[mi subInfo] count];   if (cnt) { [tracks addObject:[NSString stringWithFormat:kMPXStringInfoTrackInfoSubtitle, cnt]]; }
				[trackInfo setStringValue:[[tracks componentsJoinedByString:@", "] stringByAppendingString:kMPXStringInfoTrackTrackText]];
				
				[tracks release];				
			}
			
			if (mask & kLoadMIMaskFormat) {
				NSMutableString *dispStr = [[NSMutableString alloc] initWithCapacity:60];
				
				VideoInfo *vi = [mi videoInfoForID:[mi.playingInfo currentVideoID]];
				if (vi) {
					NSString *format = [vi format];
					switch ([format hexValue]) {
						case 0x10000001:
							format = @"MPEG-1";
							break;
						case 0x10000002:
							format = @"MPEG-2";
							break;
						case 0x10000005:
							format = @"H264";
							break;
						default:
							break;
					}
					
					format = [format uppercaseString];
					
					if ([vi bitRate] < 1) {
						[dispStr appendFormat:kMPXStringInfoVideoInfoNoBPS,
						 format,
						 [vi width],
						 [vi height],
						 ((float)[vi fps])];					
					} else {
						[dispStr appendFormat:kMPXStringInfoVideoInfo,
						 format,
						 ((float)[vi bitRate])/1000.0f,
						 [vi width],
						 [vi height],
						 ((float)[vi fps])];					
					}			
				}
				
				AudioInfo *ai = [mi audioInfoForID:[mi.playingInfo currentAudioID]];
				if (ai) {
					// This is a hack
					// mplayer will not always output the string format for audio/video format property
					// this is a temp list for known value
					NSString *format = [ai format];
					
					switch ([format hexValue]) {
						case 0x2000:
							format = @"AC-3";
							break;
						case 0x2001:
							format = @"DTS";
							break;
						case 0x55:
							format = @"MPEG-3";
							break;
						case 0x50:
							format = @"MPEG-1/2";
							break;
						case 0x1:
						case 0x6:
						case 0x7:
							format = @"PCM";
							break;
						case 0x161:
						case 0x162:
						case 0x163:
							format = @"WMA";
							break;
						case 0xF1AC:
							format = @"FLAC";
							break;
						case 0x566F:
							format = @"VORBIS";
							break;

						default:
							break;
					}
					format = [format uppercaseString];
					
					if ([ai bitRate] < 1) {
						[dispStr appendFormat:kMPXStringInfoAudioInfoNoBPS,
						 format,
						 ((float)[ai sampleRate])/1000.0f,
						 [ai sampleSize],
						 [ai channels]];						
					} else {
						[dispStr appendFormat:kMPXStringInfoAudioInfo,
						 format,
						 ((float)[ai bitRate])/1000.0f,
						 ((float)[ai sampleRate])/1000.0f,
						 [ai sampleSize],
						 [ai channels]];						
					}

				}
				[formatInfo setStringValue:dispStr];
				[dispStr release];				
			}
			[pool drain];
			
			if ([infoContainer isHidden]) {
				NSRect rc = [inspectorWin frame];
				rc.size.height += infoContainer.bounds.size.height;
				rc.origin.y -= infoContainer.bounds.size.height;
				
				[inspectorWin setFrame:rc display:YES animate:YES];
				[infoContainer setHidden:NO];
			}
		} else {
			[filename setStringValue:kMPXStringInfoNoInfo];
			
			if (![infoContainer isHidden]) {
				[infoContainer setHidden:YES];
				
				NSRect rc = [inspectorWin frame];
				rc.size.height -= infoContainer.bounds.size.height;
				rc.origin.y += infoContainer.bounds.size.height;
				
				[inspectorWin setFrame:rc display:YES animate:YES];			
			}
		}		
	}
}
@end
