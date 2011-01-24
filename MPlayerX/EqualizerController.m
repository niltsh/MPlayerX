/*
 * MPlayerX - EqualizerController.m
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

#import "KeyCode.h"
#import "EqualizerController.h"
#import "PlayerController.h"
#import "UserDefaults.h"

#define kAutoSaveEQSettingsLifeNone			(0)		/**< 只要开始播放就reset */
#define kAutoSaveEQSettingsLifeAPN			(1)		/**< 不是APN的时候reset */
#define kAutoSaveEQSettingsLifeApplication	(2)		/**< 程序关闭时reset */
#define kAutoSaveEQSettingsLifeUserDefaults	(3)		/**< 不reset */

@interface EqualizerController (Internal)
-(void) playBackStarted:(NSNotification*)notif;
-(void) playBackStopped:(NSNotification*)notif;
-(void) loadParameters:(NSArray*)settings;
-(void) saveParameters:(NSArray*) arr;
@end

@implementation EqualizerController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithInt:kAutoSaveEQSettingsLifeUserDefaults], kUDKeyAutoSaveEQSettings,
					   nil]];
}

-(id) init
{
	self = [super init];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];

		nibLoaded = NO;
		bars = nil;		
	}
	return self;
}

-(void) dealloc
{
	[bars release];
	[super dealloc];
}

-(void) awakeFromNib
{
	if (!nibLoaded) {
		[menuEQPanel setKeyEquivalent:kSCMEqualizerPanelKeyEquivalent];
		[menuEQPanel setKeyEquivalentModifierMask:kSCMEqualizerPanelKeyEquivalentModifierFlagMask];
		
		if ([ud integerForKey:kUDKeyAutoSaveEQSettings] != kAutoSaveEQSettingsLifeUserDefaults) {
			[ud removeObjectForKey:kUDKeyEQSettings];
		}
		[self loadParameters:[ud arrayForKey:kUDKeyEQSettings]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackStarted:)
													 name:kMPCPlayStartedNotification object:playerController];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackStopped:)
													 name:kMPCPlayStoppedNotification object:playerController];
	}
}

-(IBAction) showUI:(id)sender
{
	if (!nibLoaded) {
		nibLoaded = YES;
		[NSBundle loadNibNamed:@"Equalizer" owner:self];
		bars = [[NSArray alloc] initWithObjects:sli30,sli60,sli125,sli250,sli500,sli1k,sli2k,sli4k,sli8k,sli16k,nil];
		
		[self loadParameters:[ud arrayForKey:kUDKeyEQSettings]];
		
		[EQPanel setLevel:NSMainMenuWindowLevel];
	}
	
	if ([EQPanel isVisible]) {
		[EQPanel orderOut:self];
	} else {
		[EQPanel orderFront:self];
	}
}

-(void) loadParameters:(NSArray*)settings
{
	NSUInteger idx = 0;
	NSUInteger num = 0;

	[playerController setEqualizer:settings];
	
	if (settings) {
		num = [settings count];
	}

	if (bars) {
		for (id bar in bars) {
			if (idx < num) {
				[bar setFloatValue:[[settings objectAtIndex:idx++] floatValue]];
			} else {
				[bar setFloatValue:0.0f];
			}
		}
	}
	
}

-(void) saveParameters:(NSArray*) arr
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *settings = [[NSMutableArray alloc] initWithCapacity:12];
	
	for (id bar in arr) {
		[settings addObject:[NSNumber numberWithFloat:[bar floatValue]]];
	}
	
	[ud setObject:settings forKey:kUDKeyEQSettings];
	
	[settings release];
	
	[pool drain];
}

-(IBAction) setEqualizer:(id)sender
{	
	[playerController setEqualizer:bars];
	
	[self saveParameters:bars];
}

-(IBAction) resetEqualizer:(id)sender
{
	[playerController setEqualizer:nil];
	
	for (id bar in bars) {
		[bar setFloatValue:0.0f];
	}
	[self saveParameters:bars];
}

-(void) playBackStarted:(NSNotification*)notif
{
	if ([ud integerForKey:kUDKeyAutoSaveEQSettings] == kAutoSaveEQSettingsLifeAPN) {
		if (![playerController isAutoPlayed]) {
			// not apn
			[self resetEqualizer:nil];
		}		
	}
}

-(void) playBackStopped:(NSNotification*)notif
{
	if ([ud integerForKey:kUDKeyAutoSaveEQSettings] == kAutoSaveEQSettingsLifeNone) {
		[self resetEqualizer:nil];
	}
}

@end
