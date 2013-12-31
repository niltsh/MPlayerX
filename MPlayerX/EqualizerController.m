/*
 * MPlayerX - EqualizerController.m
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

#import "KeyCode.h"
#import "EqualizerController.h"
#import "PlayerController.h"
#import "UserDefaults.h"

#define kAutoSaveEQSettingsLifeNone			(0)		/**< 只要开始播放就reset */
#define kAutoSaveEQSettingsLifeAPN			(1)		/**< 不是APN的时候reset */
#define kAutoSaveEQSettingsLifeApplication	(2)		/**< 程序关闭时reset */
#define kAutoSaveEQSettingsLifeUserDefaults	(3)		/**< 不reset */

#define kEQValueDefault		(0.0f)

@interface EqualizerController (Internal)
-(void) playBackStopped:(NSNotification*)notif;
-(void) playBackFinalized:(NSNotification*)notif;
-(void) saveParameters:(NSArray*) arr;
@end

@implementation EqualizerController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithInt:kAutoSaveEQSettingsLifeAPN], kUDKeyAutoSaveEQSettings,
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

		if ([ud integerForKey:kUDKeyAutoSaveEQSettings] != kAutoSaveEQSettingsLifeUserDefaults) {
			// 如果不是永远保存设置，那么就删除设置
			[ud removeObjectForKey:kUDKeyEQSettings];
		}
		
		// 加载EQ设置
		// 这个时候UI还没有加载，因此不用设定UI的东西
		// 将来如果Controller一开就就会加载UI的话，这里需要注意同步UI
		[playerController setEqualizer:[ud arrayForKey:kUDKeyEQSettings]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackFinalized:)
													 name:kMPCPlayFinalizedNotification object:playerController];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackStopped:)
													 name:kMPCPlayStoppedNotification object:playerController];
	}
}

-(IBAction) showUI:(id)sender
{
	if (!nibLoaded) {
		NSUInteger idx = 0;
		NSUInteger num = 0;
		NSArray *settings = [ud arrayForKey:kUDKeyEQSettings];
		
		nibLoaded = YES;
		[NSBundle loadNibNamed:@"Equalizer" owner:self];
		
		/** \warning Outlet的min和max的设定在XIB文件里面 */
		bars = [[NSArray alloc] initWithObjects:sli30,sli60,sli125,sli250,sli500,sli1k,sli2k,sli4k,sli8k,sli16k,nil];
		
		// 根据Apple的式样书，在没有Key的时候array返回nil而不是null
		// 所以这里的判断是安全的
		if (settings) {
			num = [settings count];
		}
		
		for (id bar in bars) {
			if (idx < num) {
				[bar setFloatValue:[[settings objectAtIndex:idx++] floatValue]];
			} else {
				[bar setFloatValue:kEQValueDefault];
			}
		}

		// 设定窗口的z坐标
		[EQPanel setLevel:NSMainMenuWindowLevel];
	}
	
	if ([EQPanel isVisible]) {
		[EQPanel orderOut:self];
	} else {
		[EQPanel orderFront:self];
	}
}

-(void) saveParameters:(NSArray*) arr
{
	// 由于EQ Slider的设定可能会非常频繁，因此专门用pool
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
		[bar setFloatValue:kEQValueDefault];
	}
	
	[self saveParameters:bars];
}

-(void) playBackStopped:(NSNotification*)notif
{
	if ([ud integerForKey:kUDKeyAutoSaveEQSettings] == kAutoSaveEQSettingsLifeNone) {
		// 播放停止，但是不知道是不是APN
		// 因此只有在 总是reset 的时候reset
		[self resetEqualizer:nil];
	}
}

-(void) playBackFinalized:(NSNotification*)notif
{
	if ([ud integerForKey:kUDKeyAutoSaveEQSettings] == kAutoSaveEQSettingsLifeAPN) {
		// 在 非APN的时候reset选项时
		// 因为 APN的话，是不会有Finalized的notification
		// 因此只要收到这个notification就可以reset
		[self resetEqualizer:nil];
	}
}

@end
