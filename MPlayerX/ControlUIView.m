/*
 * MPlayerX - ControlUIView.m
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

#import "UserDefaults.h"
#import "KeyCode.h"
#import "LocalizedStrings.h"
#import "ControlUIView.h"
#import "RootLayerView.h"
#import "PlayerController.h"
#import "FloatWrapFormatter.h"
#import "ArrowTextField.h"
#import "ResizeIndicator.h"
#import "OsdText.h"
#import "TitleView.h"
#import "CocoaAppendix.h"
#import "TimeFormatter.h"
#import "DisplayLayer.h"

#define CONTROLALPHA		(1)
#define BACKGROUNDALPHA		(0.9)

#define CONTROL_CORNER_RADIUS	(6)

#define NUMOFVOLUMEIMAGES		(3)	//这个值是除了没有音量之后的image个数
#define AUTOHIDETIMEINTERNAL	(3)

#define LASTSTOPPEDTIMERATIO	(100)

NSString * const kFillScreenButtonImageLRKey = @"LR";
NSString * const kFillScreenButtonImageUBKey = @"UB";

NSString * const kStringFMTTimeAppendTotal	= @" / %@";

#define PlayState	(NSOnState)
#define PauseState	(NSOffState)

@interface ControlUIView (ControlUIViewInternal)
-(void) windowHasResized:(NSNotification*)notification;
-(void) calculateHintTime;
-(void) resetSubtitleMenu;
-(void) resetAudioMenu;
-(void) resetVideoMenu;
-(void) playBackOpened:(NSNotification*)notif;
-(void) playBackStarted:(NSNotification*)notif;
-(void) playBackStopped:(NSNotification*)notif;
-(void) playBackWillStop:(NSNotification*)notif;
-(void) playInfoUpdated:(NSNotification*)notif;
-(void) playBackFinalized:(NSNotification*)notif;

-(void) gotCurentTime:(NSNumber*) timePos;
-(void) gotSpeed:(NSNumber*) speed;
-(void) gotSubDelay:(NSNumber*) sd;
-(void) gotAudioDelay:(NSNumber*) ad;
-(void) gotMediaLength:(NSNumber*) length;
-(void) gotSeekableState:(NSNumber*) seekable;
-(void) gotSubInfo:(NSArray*) subs changed:(int)changeKind;
-(void) gotCachingPercent:(NSNumber*) caching;
-(void) gotAudioInfo:(NSArray*) ais;
-(void) gotVideoInfo:(NSArray*) vis;
@end


@implementation ControlUIView

+(void) initialize
{
	NSNumber *boolYes = [NSNumber numberWithBool:YES];
	NSNumber *boolNo  = [NSNumber numberWithBool:NO];
	
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:50], kUDKeyVolume,
					   [NSNumber numberWithDouble:AUTOHIDETIMEINTERNAL], kUDKeyCtrlUIAutoHideTime,
					   boolNo, kUDKeySwitchTimeHintPressOnAbusolute,
					   boolNo, kUDKeyTimeTextAltTotal,
					   [NSNumber numberWithFloat:10], kUDKeyVolumeStep,
					   [NSNumber numberWithFloat:BACKGROUNDALPHA], kUDKeyCtrlUIBackGroundAlpha,
					   boolYes, kUDKeyShowOSD,
					   [NSNumber numberWithFloat:0.1], kUDKeyResizeStep,
					   boolYes, kUDKeyCloseWindowWhenStopped,
					   boolYes, kUDKeyAutoShowLBInFullScr,
					   [NSNumber numberWithUnsignedInt:kPMLetterBoxModeBottomOnly], kUDKeyAutoFSLBMode,
					   boolNo, kUDKeyHideTitlebar,
					   nil]];
}

-(id) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
		shouldHide = NO;
		fillGradient = nil;
		backGroundColor = nil;
		backGroundColor2 = nil;
		autoHideTimer = nil;
		autoHideTimeInterval = 0;
		timeFormatter = [[TimeFormatter alloc] init];
		floatWrapFormatter = [[FloatWrapFormatter alloc] init];
		subListMenu = [[NSMenu alloc] initWithTitle:@"SubListMenu"];
		audioListMenu = [[NSMenu alloc] initWithTitle:@"AudioListMenu"];
		videoListMenu = [[NSMenu alloc] initWithTitle:@"VideoListMenu"];
	}
	return self;
}

- (void)awakeFromNib
{
	orgHeight = [self bounds].size.height;
	
	// 自身的设定
	[self setAlphaValue:CONTROLALPHA];
	[self refreshBackgroundAlpha];
	// 自动隐藏设定
	[self refreshAutoHideTimer];
	
	////////////////////////////////////////set KeyEquivalents////////////////////////////////////////
	[volumeButton setKeyEquivalent:kSCMMuteKeyEquivalent];
	[playPauseButton setKeyEquivalent:kSCMPlayPauseKeyEquivalent];
	[fullScreenButton setKeyEquivalentModifierMask:kSCMFullscreenKeyEquivalentModifierFlagMask];
	[fullScreenButton setKeyEquivalent:kSCMFullScrnKeyEquivalent];

	[menuSnapshot setKeyEquivalent:kSCMSnapShotKeyEquivalent];

	[menuSubScaleInc setKeyEquivalentModifierMask:kSCMSubScaleIncreaseKeyEquivalentModifierFlagMask];
	[menuSubScaleInc setKeyEquivalent:kSCMSubScaleIncreaseKeyEquivalent];
	[menuSubScaleDec setKeyEquivalentModifierMask:kSCMSubScaleDecreaseKeyEquivalentModifierFlagMask];
	[menuSubScaleDec setKeyEquivalent:kSCMSubScaleDecreaseKeyEquivalent];
	
	[menuPlayFromLastStoppedPlace setKeyEquivalent:kSCMPlayFromLastStoppedKeyEquivalent];
	[menuPlayFromLastStoppedPlace setKeyEquivalentModifierMask:kSCMPlayFromLastStoppedKeyEquivalentModifierFlagMask];
	
	[menuSwitchSub setKeyEquivalent:kSCMSwitchSubKeyEquivalent];
	[menuSwitchAudio setKeyEquivalent:kSCMSwitchAudioKeyEquivalent];
	[menuSwitchVideo setKeyEquivalent:kSCMSwitchVideoKeyEquivalent];

	[menuVolInc setKeyEquivalent:kSCMVolumeUpKeyEquivalent];
	[menuVolDec setKeyEquivalent:kSCMVolumeDownKeyEquivalent];
	
	[menuToggleLockAspectRatio setKeyEquivalent:kSCMToggleLockAspectRatioKeyEquivalent];
	
	[menuResetLockAspectRatio setKeyEquivalent:kSCMResetLockAspectRatioKeyEquivalent];
	[menuResetLockAspectRatio setKeyEquivalentModifierMask:kSCMResetLockAspectRatioKeyEquivalentModifierFlagMask];
	
	[menuToggleLetterBox setKeyEquivalent:kSCMToggleLetterBoxKeyEquivalent];
	
	[menuSizeInc setKeyEquivalentModifierMask:kSCMWindowSizeIncKeyEquivalentModifierFlagMask];
	[menuSizeDec setKeyEquivalentModifierMask:kSCMWindowSizeDecKeyEquivalentModifierFlagMask];
	[menuSizeInc setKeyEquivalent:kSCMWindowSizeIncKeyEquivalent];
	[menuSizeDec setKeyEquivalent:kSCMWindowSizeDecKeyEquivalent];
	
	[menuShowMediaInfo setKeyEquivalent:kSCMShowMediaInfoKeyEquivalent];
	
	[menuToggleFullScreen setKeyEquivalent:kSCMFullScrnKeyEquivalent];
	[menuToggleFillScreen setKeyEquivalent:kSCMFillScrnKeyEquivalent];
	[menuToggleAuxiliaryCtrls setKeyEquivalent:kSCMAcceControlKeyEquivalent];
	
	[menuMoveToTrash setKeyEquivalentModifierMask:kSCMMoveToTrashKeyEquivalentModifierFlagMask];
	unichar keyTemp = kSCMMoveToTrashKeyEquivalent;
	[menuMoveToTrash setKeyEquivalent:[NSString stringWithCharacters:&keyTemp length:1]];
	
	[menuMoveFrameToCenter setKeyEquivalent:kSCMMoveFrameToCenterKeyEquivalent];

	////////////////////////////////////////load Images////////////////////////////////////////
	// 初始化音量大小图标
	volumeButtonImages = [[NSArray alloc] initWithObjects:	[NSImage imageNamed:@"vol_no"], [NSImage imageNamed:@"vol_low"],
															[NSImage imageNamed:@"vol_mid"], [NSImage imageNamed:@"vol_high"],
															nil];
	// fillScreenButton初期化
	fillScreenButtonAllImages =  [[NSDictionary alloc] initWithObjectsAndKeys: 
								  [NSArray arrayWithObjects:[NSImage imageNamed:@"fillscreen_lr"], [NSImage imageNamed:@"exitfillscreen_lr"], nil], kFillScreenButtonImageLRKey,
								  [NSArray arrayWithObjects:[NSImage imageNamed:@"fillscreen_ub"], [NSImage imageNamed:@"exitfillscreen_ub"], nil], kFillScreenButtonImageUBKey, 
								  nil];
	
	// 从userdefault中获得default 音量值
	// [volumeSlider setFloatValue:];
	[self setVolume:[ud objectForKey:kUDKeyVolume]];
	
	// Mask mouseup event
	[[volumeSlider cell] sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];

	// set Volume menu
	[menuVolInc setEnabled:YES];
	[menuVolInc setTag:1];	
	[menuVolDec setEnabled:YES];
	[menuVolDec setTag:-1];
	
	// set Volume step
	volStep = [ud floatForKey:kUDKeyVolumeStep];

	// 初始化时间显示slider和text
	[[timeText cell] setFormatter:timeFormatter];
	[timeText setStringValue:@""];
	[[timeTextAlt cell] setFormatter:timeFormatter];
	[timeTextAlt setStringValue:@""];
	
	[timeSlider setEnabled:NO];
	[timeSlider setMaxValue:0];
	[timeSlider setMinValue:-1];
	// 只有拖拽和按下鼠标的时候触发事件
	[[timeSlider cell] sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];

	// set Time hint text
	[hintTime setAlphaValue:0];
	[[hintTime cell] setFormatter:timeFormatter];
	[hintTime setStringValue:@""];

	// 初始状态是hide
	[fullScreenButton setHidden: YES];

	// set fillscreen button status and image
	[fillScreenButton setHidden: YES];	
	NSArray *fillScrnBtnModeImages = [fillScreenButtonAllImages objectForKey:kFillScreenButtonImageUBKey];
	[fillScreenButton setImage: [fillScrnBtnModeImages objectAtIndex:0]];
	[fillScreenButton setAlternateImage:[fillScrnBtnModeImages objectAtIndex:1]];
	[fillScreenButton setState: NSOffState];
	
	// set fomatter and step
	[[speedText cell] setFormatter:floatWrapFormatter];
	[[subDelayText cell] setFormatter:floatWrapFormatter];
	[[audioDelayText cell] setFormatter:floatWrapFormatter];
	
	[speedText setStepValue:[ud floatForKey:kUDKeySpeedStep]];
	[subDelayText setStepValue:[ud floatForKey:kUDKeySubDelayStepTime]];
	[audioDelayText setStepValue:[ud floatForKey:kUDKeyAudioDelayStepTime]];

	// set list for sub/audio/video menu
	[menuSwitchSub setSubmenu:subListMenu];
	[subListMenu setAutoenablesItems:NO];
	[self resetSubtitleMenu];
	
	[menuSwitchAudio setSubmenu:audioListMenu];
	[audioListMenu setAutoenablesItems:NO];
	[self resetAudioMenu];
	
	[menuSwitchVideo setSubmenu:videoListMenu];
	[videoListMenu setAutoenablesItems:NO];
	[self resetVideoMenu];
	
	// set menuItem tags
	[menuSubScaleInc setTag:1];
	[menuSubScaleDec setTag:-1];
	
	[menuSizeInc setTag:1];
	[menuSizeDec setTag:-1];

	// set menu status
	[menuToggleLockAspectRatio setEnabled:NO];
	[menuToggleLockAspectRatio setTitle:([dispView lockAspectRatio])?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
	[menuResetLockAspectRatio setAlternate:YES];
	
	[menuToggleLetterBox setTitle:([ud integerForKey:kUDKeyLetterBoxMode] == kPMLetterBoxModeNotDisplay)?(kMPXStringMenuShowLetterBox):
																										 (kMPXStringMenuHideLetterBox)];
	[menuToggleFullScreen setEnabled:NO];
	[menuToggleFullScreen setTitle:kMPXStringMenuEnterFullscrn];
	
	[menuToggleFillScreen setEnabled:NO];
	
	[toggleAcceButton setTag:NO];
	[menuToggleAuxiliaryCtrls setTag:NO];
	[menuToggleAuxiliaryCtrls setTitle:kMPXStringMenuShowAuxCtrls];

	// set OSD active status
	[osd setActive:NO];
	
	[notifCenter addObserver:self selector:@selector(windowHasResized:)
						name:NSWindowDidResizeNotification
					  object:[self window]];
	
	[notifCenter addObserver:self selector:@selector(playBackOpened:)
						name:kMPCPlayOpenedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackStarted:)
						name:kMPCPlayStartedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackWillStop:)
						name:kMPCPlayWillStopNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackStopped:)
						name:kMPCPlayStoppedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackFinalized:)
						name:kMPCPlayFinalizedNotification object:playerController];

	[notifCenter addObserver:self selector:@selector(playInfoUpdated:)
						name:kMPCPlayInfoUpdatedNotification object:playerController];
	
	// this functioin must be called after the Notification is setuped
	[playerController setupKVO];

	// force hide titlebar
	[title setAlphaValue:([ud boolForKey:kUDKeyHideTitlebar])?0:CONTROLALPHA];
}

-(void) dealloc
{
	[notifCenter removeObserver:self];
	
	if (autoHideTimer) {
		[autoHideTimer invalidate];
	}

	[fillScreenButtonAllImages release];
	[volumeButtonImages release];
	[timeFormatter release];
	[floatWrapFormatter release];
	
	[menuSwitchSub setSubmenu:nil];
	[subListMenu release];

	[menuSwitchAudio setSubmenu:nil];
	[audioListMenu release];
	
	[menuSwitchVideo setSubmenu:nil];
	[videoListMenu release];
	
	[fillGradient release];
	[backGroundColor release];
	[backGroundColor2 release];
	
	[super dealloc];
}

-(BOOL) acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL) acceptsFirstResponder { return YES; }

-(void) refreshBackgroundAlpha
{
	[fillGradient release];
	[backGroundColor release];
	[backGroundColor2 release];
	
	float backAlpha = [ud floatForKey:kUDKeyCtrlUIBackGroundAlpha];

	fillGradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithDeviceWhite:0.220 alpha:backAlpha], 0.00f,
																  [NSColor colorWithDeviceWhite:0.150 alpha:backAlpha], 0.33f,
																  [NSColor colorWithDeviceWhite:0.090 alpha:backAlpha], 0.36f,
																  [NSColor colorWithDeviceWhite:0.050 alpha:backAlpha], 1.00f,	
																  nil];
	backGroundColor  = [[NSColor colorWithDeviceWhite:0.45 alpha:backAlpha] retain];
	backGroundColor2 = [[NSColor colorWithDeviceWhite:0.32 alpha:backAlpha] retain];
	
	[self setNeedsDisplay:YES];
}

-(void) refreshOSDSetting
{
	BOOL new = [ud boolForKey:kUDKeyShowOSD]; 
	if (new) {
		// 如果是显示OSD的话，那么就得到新值
		[osd setAutoHideTimeInterval:[ud doubleForKey:kUDKeyOSDAutoHideTime]];
		[osd setFrontColor:[NSUnarchiver unarchiveObjectWithData:[ud objectForKey:kUDKeyOSDFrontColor]]];
		// 并且强制显示OSD，但是这个和目前OSD的状态不一定一样
		[osd setActive:YES];
		[osd setStringValue:kMPXStringOSDSettingChanged owner:kOSDOwnerOther updateTimer:YES];
	}
	if ([playerController couldAcceptCommand]) {
		// 如果正在播放，那么就设定显示
		// 如果不在播放，osd的active状态会被设置为强制OFF，所以不能设定
		// 在开始播放的时候，会再一次设定active状态
		[osd setActive:new];
	}
}
////////////////////////////////////////////////AutoHideThings//////////////////////////////////////////////////
-(void) refreshAutoHideTimer
{
	float ti = [ud doubleForKey:kUDKeyCtrlUIAutoHideTime];
	
	if ((ti != autoHideTimeInterval) && (ti > 0)) {
		// 这个Timer没有retain，所以也不需要release
		if (autoHideTimer) {
			[autoHideTimer invalidate];
			autoHideTimer = nil;
		}
		autoHideTimeInterval = ti;
		autoHideTimer = [NSTimer timerWithTimeInterval:autoHideTimeInterval/2
												target:self
											  selector:@selector(tryToHide)
											  userInfo:nil
											   repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:autoHideTimer forMode:NSDefaultRunLoopMode];
	}
}

-(void) doHide
{
	// 这段代码是不能重进的，否则会不停的hidecursor
	if ([self alphaValue] > (CONTROLALPHA-0.05)) {
		// 得到鼠标在这个window的坐标
		NSPoint pos = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
		
		// 如果不在这个View的话，那么就隐藏自己
		// if HideTitlebar is ON, ignore the titlebar area when hiding the cursor
		if ((!NSPointInRect([self  convertPoint:pos fromView:nil], self.bounds)) && 
			((!NSPointInRect([title convertPoint:pos fromView:nil], title.bounds)) || [ud boolForKey:kUDKeyHideTitlebar])) {
			[self.animator setAlphaValue:0];
			
			// 如果是全屏模式也要隐藏鼠标
			if ([dispView isInFullScreenMode]) {
				// 这里的[self window]不是成员的那个window，而是全屏后self的新window
				if ([[self window] isKeyWindow]) {
					// 如果不是key window的话，就不隐藏鼠标
					CGDisplayHideCursor(dispView.fullScrnDevID);
				}
			} else {
				// 不是全屏的话，隐藏resizeindicator
				// 全屏的话不管
				[rzIndicator.animator setAlphaValue:0];
				// 这里应该判断kUDKeyHideTitlebar的，但是由于这里是要隐藏title
				// 因此多次将AlphaValue设置为0也不会有坏影响
				[title.animator setAlphaValue:0];
			}
		}			
	}	
}

-(void) tryToHide
{
	if (shouldHide) {
		[self doHide];
	} else {
		shouldHide = YES;
	}
}

-(void) showUp
{
	shouldHide = NO;

	[self.animator setAlphaValue:CONTROLALPHA];

	if ([dispView isInFullScreenMode]) {
		// 全屏模式还要显示鼠标
		CGDisplayShowCursor(dispView.fullScrnDevID);
	} else {
		// 不是全屏模式的话，要显示resizeindicator
		// 全屏的时候不管
		[rzIndicator.animator setAlphaValue:CONTROLALPHA];

		if (![ud boolForKey:kUDKeyHideTitlebar]) {
			// if kUDKeyHideTitlebar is OFF, go to display the titlebar
			[title.animator setAlphaValue:CONTROLALPHA];
		}
	}
}

////////////////////////////////////////////////Actions//////////////////////////////////////////////////
-(IBAction) togglePlayPause:(id)sender
{
	[playerController togglePlayPause];

	NSString *osdStr;

	switch (playerController.playerState) {
		case kMPCStoppedState:
			// 停止状态
			[self playBackStopped:nil];
			osdStr = kMPXStringOSDPlaybackStopped;
			break;
		case kMPCPausedState:
			// 暂停状态
			[dispView setPlayerWindowLevel];
			[playPauseButton setState:PauseState];
			osdStr = kMPXStringOSDPlaybackPaused;
			break;
		case kMPCPlayingState:
			// 播放状态
			[dispView setPlayerWindowLevel];
			[playPauseButton setState:PlayState];
			osdStr = kMPXStringOSDNull;
			break;
		default:
			osdStr = kMPXStringOSDNull;
			break;
	}
	[osd setStringValue:osdStr owner:kOSDOwnerOther updateTimer:YES];
}

-(IBAction) toggleMute:(id)sender
{
	BOOL mute = [playerController toggleMute];

	// set buttons and menu status
	[volumeButton setState:(mute)?NSOnState:NSOffState];
	[volumeSlider setEnabled:!mute];
	[menuVolInc setEnabled:!mute];
	[menuVolDec setEnabled:!mute];
	
	// update OSD
	[osd setStringValue:(mute)?(kMPXStringOSDMuteON):(kMPXStringOSDMuteOFF)
				  owner:kOSDOwnerOther
			updateTimer:YES];
}

-(IBAction) setVolume:(id)sender
{
	if ([volumeSlider isEnabled]) {
		// 这里必须要从sender拿到floatValue，而不能直接从volumeSlider拿
		// 因为有可能是键盘快捷键，这个时候，ShortCutManager会发一个NSNumber作为sender过来
		float vol = [playerController setVolume:[sender floatValue]];

		// update buttons status
		[volumeSlider setFloatValue: vol];
		
		double max = [volumeSlider maxValue];
		int now = (int)((vol*NUMOFVOLUMEIMAGES + max -1)/max);
		[volumeButton setImage: [volumeButtonImages objectAtIndex: now]];
		
		// 将音量作为UserDefaults存储
		[ud setFloat:vol forKey:kUDKeyVolume];
		
		// update OSD
		[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDVolumeHint, vol]
					  owner:kOSDOwnerOther
				updateTimer:YES];
	}
}

-(IBAction) changeVolumeBy:(id)sender
{
	float delta = ([sender isKindOfClass:[NSMenuItem class]])?([sender tag]):([sender floatValue]);
	
	[self setVolume:[NSNumber numberWithFloat:[volumeSlider floatValue] + (delta * volStep)]];
}

-(IBAction) seekTo:(id) sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		// action from menu
		sender = [NSNumber numberWithFloat:MAX(0, (((float)[sender tag]) / LASTSTOPPEDTIMERATIO) - 5)];
	}
	
	// when dragging, use absolute seeking
	float time = [playerController seekTo:[sender floatValue]
									 mode:([[timeSlider cell] isDragging])?kMPCSeekModeAbsolute:kMPCSeekModeRelative];

	[self updateHintTime];
	
	if ([osd isActive] && (time > 0)) {
		NSString *osdStr = [timeFormatter stringForObjectValue:[NSNumber numberWithFloat:time]];
		double length = [timeSlider maxValue];
		
		if (length > 0) {
			osdStr = [osdStr stringByAppendingFormat:kStringFMTTimeAppendTotal, [timeFormatter stringForObjectValue:[NSNumber numberWithDouble:length]]];
		}
		[osd setStringValue:osdStr owner:kOSDOwnerTime updateTimer:YES];
	}
}

-(void) changeTimeBy:(float) delta
{
	delta = [playerController changeTimeBy:delta];

	if ([osd isActive] && (delta > 0)) {
		NSString *osdStr = [timeFormatter stringForObjectValue:[NSNumber numberWithFloat:delta]];
		double length = [timeSlider maxValue];
		
		if (length > 0) {
			osdStr = [osdStr stringByAppendingFormat:kStringFMTTimeAppendTotal, [timeFormatter stringForObjectValue:[NSNumber numberWithDouble:length]]];
		}
		[osd setStringValue:osdStr owner:kOSDOwnerTime updateTimer:YES];
	}
}

-(IBAction) toggleFullScreen:(id)sender
{
	if ([dispView toggleFullScreen]) {
		// 成功
		if ([dispView isInFullScreenMode]) {
			// 进入全屏
			
			[fullScreenButton setState: NSOnState];
			[menuToggleFullScreen setTitle:kMPXStringMenuExitFullscrn];

			// fillScreenButton的Image设定之类的，
			// 在RootLayerView里面实现，因为设定这个需要比较多的参数
			// 会让接口变的很难看
			[fillScreenButton setHidden: NO];
			[menuToggleFillScreen setEnabled:YES];
			
			// 如果自己已经被hide了，那么就把鼠标也hide
			if ([self alphaValue] < (CONTROLALPHA-0.05)) {
				CGDisplayHideCursor(dispView.fullScrnDevID);
			}
			
			// 进入全屏，强制隐藏resizeindicator
			[rzIndicator setAlphaValue:0];
			// 这里应该判断kUDKeyHideTitlebar的，但是由于这里是要隐藏title
			// 因此多次将AlphaValue设置为0也不会有坏影响
			[title setAlphaValue:0];
			
			[menuToggleLockAspectRatio setTitle:([dispView lockAspectRatio])?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
			[menuToggleLockAspectRatio setEnabled:NO];
		} else {
			// 退出全屏
			CGDisplayShowCursor(dispView.fullScrnDevID);

			[fullScreenButton setState:NSOffState];
			[menuToggleFullScreen setTitle:kMPXStringMenuEnterFullscrn];

			[fillScreenButton setHidden: YES];
			[menuToggleFillScreen setEnabled:NO];
			
			if ([self alphaValue] > (CONTROLALPHA-0.05)) {
				// 如果controlUI没有隐藏，那么显示resizeindiccator
				[rzIndicator.animator setAlphaValue:CONTROLALPHA];

				if (![ud boolForKey:kUDKeyHideTitlebar]) {
					// if kUDKeyHideTitlebar is OFF, go to display the titlebar
					[title.animator setAlphaValue:CONTROLALPHA];
				}
			}
			[menuToggleLockAspectRatio setEnabled:YES];
		}
	} else {
		// 失败
		[fullScreenButton setState: NSOffState];
		[menuToggleFullScreen setTitle:kMPXStringMenuEnterFullscrn];
		
		[fillScreenButton setHidden: YES];
		[menuToggleFillScreen setEnabled:NO];
		
		[menuToggleLockAspectRatio setEnabled:NO];
	}

	[self windowHasResized:nil];
}

-(IBAction) toggleFillScreen:(id)sender
{
	if (sender || ([fillScreenButton state] == NSOnState)) {
		[fillScreenButton setState: ([dispView toggleFillScreen])?NSOnState:NSOffState];
	}
}

-(IBAction) toggleAccessaryControls:(id)sender
{
	NSRect rcSelf = [self frame];
	CGFloat delta = accessaryContainer.frame.size.height -10;
	NSRect rcAcc = [accessaryContainer frame];

	if ([sender tag] == NO) {
		// to show
		rcSelf.size.height = orgHeight + delta;
		rcSelf.origin.y -= MIN(rcSelf.origin.y, delta);
		
		[self.animator setFrame:rcSelf];
		
		rcAcc.origin.y = 0;
		rcAcc.origin.x = (rcSelf.size.width - rcAcc.size.width) / 2;
		[accessaryContainer setFrameOrigin:rcAcc.origin];
		
		[accessaryContainer.animator setHidden: NO];
		
		[menuToggleAuxiliaryCtrls setTitle:kMPXStringMenuHideAuxCtrls];
		[menuToggleAuxiliaryCtrls setTag:YES];
		[toggleAcceButton setState:NSOnState];
		[toggleAcceButton setTag:YES];
		
	} else {
		[accessaryContainer.animator setHidden: YES];

		rcSelf.size.height = orgHeight;
		rcSelf.origin.y += delta;
		
		[self.animator setFrame:rcSelf];
		
		rcAcc.origin.y = 0;
		rcAcc.origin.x = (rcSelf.size.width - rcAcc.size.width) / 2;
		[accessaryContainer setFrameOrigin:rcAcc.origin];
		
		[menuToggleAuxiliaryCtrls setTitle:kMPXStringMenuShowAuxCtrls];
		[menuToggleAuxiliaryCtrls setTag:NO];
		[toggleAcceButton setState:NSOffState];
		[toggleAcceButton setTag:NO];
	}
	[hintTime.animator setAlphaValue:0];
}

-(IBAction) changeSpeed:(id) sender
{
	[playerController setSpeed:[sender floatValue]];
}

-(IBAction) changeAudioDelay:(id) sender
{
	[playerController setAudioDelay:[sender floatValue]];	
}

-(IBAction) changeSubDelay:(id)sender
{
	[playerController setSubDelay:[sender floatValue]];
}

-(IBAction) changeSubScale:(id)sender
{
	[playerController changeSubScaleBy:[sender tag] * [ud floatForKey:kUDKeySubScaleStepValue]];
}

-(IBAction) stepSubtitles:(id)sender
{
	int selectedTag = -2;
	NSMenuItem* mItem;
	
	// 找到目前被选中的字幕
	for (mItem in [subListMenu itemArray]) {
		if ([mItem state] == NSOnState) {
			selectedTag = [mItem tag];
			break;
		}
	}
	// 得到下一个字幕的tag
	// 如果没有一个菜单选项被选中，那么就选中隐藏显示字幕
	selectedTag++;
	
	if (!(mItem = [subListMenu itemWithTag:selectedTag])) {
		// 如果是字幕的最后一项，那么就轮到隐藏字幕菜单选项
		mItem = [subListMenu itemWithTag:-1];
	}
	[self setSubWithID:mItem];
}

-(IBAction) setSubWithID:(id)sender
{
	if (sender) {
		[playerController setSubtitle:[sender tag]];
		
		for (NSMenuItem* mItem in [subListMenu itemArray]) {
			if ([mItem state] == NSOnState) {
				[mItem setState:NSOffState];
				break;
			}
		}
		[sender setState:NSOnState];
		
		[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDSubtitleHint, [sender title]]
					  owner:kOSDOwnerOther
				updateTimer:YES];
	}
}

-(IBAction) stepAudios:(id)sender
{
	NSUInteger num = [audioListMenu numberOfItems];
	
	if (num) {
		NSUInteger idx = 0, found = 0;
		NSMenuItem* mItem;
		
		for (mItem in [audioListMenu itemArray]) {
			if ([mItem state] == NSOnState) {
				found = idx+1;
				break;
			}
			idx++;
		}
		if (found >= num) {
			found = 0;
		}
		[self setAudioWithID:[audioListMenu itemAtIndex:found]];
	}
}

-(IBAction) setAudioWithID:(id)sender
{
	if (sender) {
		[playerController setAudio:[sender tag]];
		
		// This is a hack
		// since I have to reset the volume when switch audio
		// so I should disable OSD when set volume
		BOOL oldAct = [osd isActive];
		[osd setActive:NO];
		// 这个可能是mplayer的bug，当轮转一圈从各个音轨到无声在回到音轨时，声音会变到最大，所以这里再设定一次音量
		[self setVolume:volumeSlider];
		[osd setActive:oldAct];
		
		for (NSMenuItem* mItem in [audioListMenu itemArray]) {
			if ([mItem state] == NSOnState) {
				[mItem setState:NSOffState];
				break;
			}
		}
		[sender setState:NSOnState];
		
		[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDAudioHint, [sender title]]
					  owner:kOSDOwnerOther
				updateTimer:YES];
	}
}

-(IBAction) stepVideos:(id)sender
{
	NSUInteger num = [videoListMenu numberOfItems];
	
	if (num) {
		NSUInteger idx = 0, found = 0;
		NSMenuItem* mItem;

		for (mItem in [videoListMenu itemArray]) {
			if ([mItem state] == NSOnState) {
				found = idx+1;
				break;
			}
			idx++;
		}
		if (found >= num) {
			found = 0;
		}
		[self setVideoWithID:[videoListMenu itemAtIndex:found]];
	}
}

-(IBAction) setVideoWithID:(id)sender
{
	if (sender) {
		[playerController setVideo:[sender tag]];
		
		for (NSMenuItem* mItem in [videoListMenu itemArray]) {
			if ([mItem state] == NSOnState) {
				[mItem setState:NSOffState];
				break;
			}
		}
		[sender setState:NSOnState];
		
		[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDVideoHint, [sender title]]
					  owner:kOSDOwnerOther
				updateTimer:YES];
	}
}

-(IBAction) changeSubPosBy:(id)sender
{
	if (sender) {
		if ([sender isKindOfClass:[NSNumber class]]) {
			// 如果是NSNumber的话，说明不是Target-Action发过来的
			[playerController changeSubPosBy:[sender floatValue]];
		}
	}
}

-(IBAction) changeAudioBalanceBy:(id)sender
{
	if (sender) {
		if ([sender isKindOfClass:[NSNumber class]]) {
			// 如果是NSNumber的话，说明不是Target-Action发过来的
			[playerController changeAudioBalanceBy:[sender floatValue]];
		}
	} else {
		//nil说明是想复原
		[playerController setAudioBalance:0];
	}
}

-(IBAction) toggleLockAspectRatio:(id)sender
{
	[dispView setLockAspectRatio:(![dispView lockAspectRatio])];

	BOOL lock = [dispView lockAspectRatio];
	[menuToggleLockAspectRatio setTitle:(lock)?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
	
	[osd setStringValue:(lock)?(kMPXStringOSDAspectRatioLocked):(kMPXStringOSDAspectRatioUnLocked)
				  owner:kOSDOwnerOther
			updateTimer:YES];
}

-(IBAction) resetAspectRatio:(id)sender
{
	[dispView resetAspectRatio];
	[menuToggleLockAspectRatio setTitle:([dispView lockAspectRatio])?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
	
	[osd setStringValue:kMPXStringOSDAspectRatioReset
				  owner:kOSDOwnerOther
			updateTimer:YES];
}

-(IBAction) toggleLetterBox:(id)sender
{
	NSInteger lbMode = [ud integerForKey:kUDKeyLetterBoxMode];

	if (sender) {
		// 说明是从menu激发的事件
		// 如果是nil，说明是内部激发的事件，那么只是更新menu状态
		if (lbMode == kPMLetterBoxModeNotDisplay) {
			// 没有在显示
			lbMode = [ud integerForKey:kUDKeyLetterBoxModeAlt];
			[ud setInteger:lbMode forKey:kUDKeyLetterBoxMode];
		} else {
			// 正在显示
			lbMode = kPMLetterBoxModeNotDisplay;
			[ud setInteger:lbMode forKey:kUDKeyLetterBoxMode];
		}
	}

	// not in the fullscreen mode
	float margin = [ud floatForKey:kUDKeyLetterBoxHeight];

	switch (lbMode) {
		case kPMLetterBoxModeBoth:
			[menuToggleLetterBox setTitle:kMPXStringMenuHideLetterBox];
			[playerController setLetterBox:YES top:margin bottom:margin];
			break;
		case kPMLetterBoxModeBottomOnly:
			[menuToggleLetterBox setTitle:kMPXStringMenuHideLetterBox];
			[playerController setLetterBox:YES top:-1.0f bottom:margin];
			break;
		case kPMLetterBoxModeTopOnly:
			[menuToggleLetterBox setTitle:kMPXStringMenuHideLetterBox];
			[playerController setLetterBox:YES top:margin bottom:-1.0f];
			break;
		default:
			[menuToggleLetterBox setTitle:kMPXStringMenuShowLetterBox];
			[playerController setLetterBox:NO top:-1.0f bottom:-1.0f];
			break;
	}
	[playerController changeTimeBy:0.01f];
}

-(IBAction) stepWindowSize:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		float step = [sender tag] * [ud floatForKey:kUDKeyResizeStep];
		
		[dispView changeWindowSizeBy:NSMakeSize(step, step) animate:YES];
	}
}

-(IBAction) moveFrameToCenter:(id)sender
{
	[dispView moveFrameToCenter];
}

////////////////////////////////////////////////FullscreenThings//////////////////////////////////////////////////
-(void) setFillScreenMode:(NSString*)modeKey state:(NSInteger) state
{
	NSArray *fillScrnBtnModeImages = [fillScreenButtonAllImages objectForKey:modeKey];
	
	if (fillScrnBtnModeImages) {
		[fillScreenButton setImage:[fillScrnBtnModeImages objectAtIndex:0]];
		[fillScreenButton setAlternateImage:[fillScrnBtnModeImages objectAtIndex:1]];
	}
	[fillScreenButton setState:state];
}

////////////////////////////////////////////////displayThings//////////////////////////////////////////////////
-(void) displayStarted
{
	[fullScreenButton setHidden: NO];
	[menuToggleFullScreen setEnabled:YES];
	
	[menuSnapshot setEnabled:YES];
	
	if (![dispView isInFullScreenMode]) {
		[menuToggleLockAspectRatio setEnabled:YES];
	}
	[menuToggleLockAspectRatio setTitle:([dispView lockAspectRatio])?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
}

-(void) displayStopped
{
	[fullScreenButton setHidden: YES];
	[menuToggleFullScreen setEnabled:NO];
	
	[menuSnapshot setEnabled:NO];

	[menuToggleLockAspectRatio setEnabled:NO];
}

////////////////////////////////////////////////playback//////////////////////////////////////////////////
-(void) playBackOpened:(NSNotification*)notif
{
	[osd setActive:[ud boolForKey:kUDKeyShowOSD]];

	NSNumber *stopTime = [[notif userInfo] objectForKey:kMPCPlayLastStoppedTimeKey];
	if (stopTime) {
		[menuPlayFromLastStoppedPlace setTag: ([stopTime integerValue] * LASTSTOPPEDTIMERATIO)];
		[menuPlayFromLastStoppedPlace setEnabled:YES];
	} else {
		[menuPlayFromLastStoppedPlace setEnabled:NO];		
	}
}

-(void) playBackStarted:(NSNotification*)notif
{
	[playPauseButton setState:(playerController.playerState == kMPCPlayingState)?PlayState:PauseState];

	[speedText setEnabled:YES];
	[subDelayText setEnabled:YES];
	[audioDelayText setEnabled:YES];
	
	[menuSwitchAudio setEnabled:YES];
	[menuSwitchVideo setEnabled:YES];
}

-(void) playBackWillStop:(NSNotification*)notif
{
	[osd setStringValue:@"" owner:kOSDOwnerOther updateTimer:YES];
	[osd setActive:NO];
}

/** 这个API会在两个时间点被调用，
 * 1. mplayer播放结束，不论是强制结束还是自然结束
 * 2. mplayer播放失败 */
-(void) playBackStopped:(NSNotification*)notif
{
	[playPauseButton setState:PauseState];

	[timeText setStringValue:@""];
	[timeTextAlt setStringValue:@""];
	[timeSlider setFloatValue:-1];
	
	// 由于mplayer无法静音开始，因此每次都要回到非静音状态
	[volumeButton setState:NSOffState];
	[volumeSlider setEnabled:YES];
	[menuVolInc setEnabled:YES];
	[menuVolDec setEnabled:YES];

	[speedText setEnabled:NO];
	[subDelayText setEnabled:NO];
	[audioDelayText setEnabled:NO];
	
	[menuSwitchAudio setEnabled:NO];
	[menuSwitchSub setEnabled:NO];
	[menuSwitchVideo setEnabled:NO];
	
	[menuSubScaleInc setEnabled:NO];
	[menuSubScaleDec setEnabled:NO];
	[menuPlayFromLastStoppedPlace setEnabled:NO];
}

-(void) playBackFinalized:(NSNotification*)notif
{
	// 如果不继续播放，或者没有下一个播放文件，那么退出全屏
	// 这个时候的显示状态displaying是NO
	// 因此，如果是全屏的话，会退出全屏，如果不是全屏的话，也不会进入全屏
	[self toggleFullScreen:nil];
	// 并且重置 fillScreen状态
	[self toggleFillScreen:nil];
	
	if ([ud boolForKey:kUDKeyCloseWindowWhenStopped]) {
		[dispView closePlayerWindow];
	}
	
	// 播放全部结束，将渲染区放回中心
	[dispView moveFrameToCenter];
}

-(void) playInfoUpdated:(NSNotification*)notif
{
	NSString *keyPath = [[notif userInfo] objectForKey:kMPCPlayInfoUpdatedKeyPathKey];
	NSDictionary *change = [[notif userInfo] objectForKey:kMPCPlayInfoUpdatedChangeDictKey];

	if ([keyPath isEqualToString:kKVOPropertyKeyPathCurrentTime]) {
		// 得到现在的播放时间
		[self gotCurentTime:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathSpeed]) {
		// 得到播放速度
		[self gotSpeed:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathSubDelay]) {
		// 得到 字幕延迟
		[self gotSubDelay:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathAudioDelay]) {
		// 得到 声音延迟
		[self gotAudioDelay:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathLength]){
		// 得到媒体文件的长度
		[self gotMediaLength:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathSeekable]) {
		// 得到 能否跳跃
		[self gotSeekableState:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathCachingPercent]) {
		// 得到目前的caching percent
		[self gotCachingPercent:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathSubInfo]) {
		// 得到 字幕信息
		[self gotSubInfo:[change objectForKey:NSKeyValueChangeNewKey]
					  changed:[[change objectForKey:NSKeyValueChangeKindKey] intValue]];
	
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathAudioInfo]) {
		// 得到音频的信息
		[self gotAudioInfo:[change objectForKey:NSKeyValueChangeNewKey]];
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathVideoInfo]) {
		// got the video info
		[self gotVideoInfo:[change objectForKey:NSKeyValueChangeNewKey]];
	}
}
////////////////////////////////////////////////KVO for time//////////////////////////////////////////////////
-(void) gotMediaLength:(NSNumber*) length
{
	float len = [length floatValue];
	
	if (len > 0) {
		[timeSlider setMaxValue:len];
		[timeSlider setMinValue:0];
		if ([ud boolForKey:kUDKeyTimeTextAltTotal]) {
			// diplay total time
			[timeTextAlt setIntValue:len + 0.5]; 
		} else {
			// display remain time
			[timeTextAlt setIntValue:-len-0.5];
		}
	} else {
		[timeSlider setEnabled:NO];
		[timeSlider setMaxValue:0];
		[timeSlider setMinValue:-1];
		[hintTime.animator setAlphaValue:0];
	}
}

-(void) gotCurentTime:(NSNumber*) timePos
{
	float time = [timePos floatValue];
	double length = [timeSlider maxValue];

	if (length > 0) {
		if ([ud boolForKey:kUDKeyTimeTextAltTotal]) {
			[timeTextAlt setIntValue:length + 0.5];
		} else {
			// display remaining time
			[timeTextAlt setIntValue:time - length - 0.5];
		}
	}

	[timeText setIntValue:time + 0.5];
	// 即使timeSlider被禁用也可以显示时间
	[timeSlider setFloatValue:time];
	
	if (length > 0) {
		[self calculateHintTime];
	}
	
	if ([osd isActive] && (time > 0)) {
		NSString *osdStr = [timeFormatter stringForObjectValue:timePos];
		
		if (length > 0) {
			osdStr = [osdStr stringByAppendingFormat:kStringFMTTimeAppendTotal, [timeFormatter stringForObjectValue:[NSNumber numberWithDouble:length]]];
		}
		[osd setStringValue:osdStr owner:kOSDOwnerTime updateTimer:NO];		
	}
}

-(void) gotSeekableState:(NSNumber*) seekable
{
	[timeSlider setEnabled:[seekable boolValue]];
}

-(void) gotSpeed:(NSNumber*) speed
{
	[speedText setFloatValue:[speed floatValue]];
	
	[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDSpeedHint, [speed floatValue]] 
				  owner:kOSDOwnerOther
			updateTimer:YES];
}

-(void) gotSubDelay:(NSNumber*) sd
{
	[subDelayText setFloatValue:[sd floatValue]];
	
	[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDSubDelayHint, [sd floatValue]]
				  owner:kOSDOwnerOther
			updateTimer:YES];
}

-(void) gotAudioDelay:(NSNumber*) ad
{
	[audioDelayText setFloatValue:[ad floatValue]];

	[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDAudioDelayHint, [ad floatValue]]
				  owner:kOSDOwnerOther
			updateTimer:YES];
}

-(void) resetSubtitleMenu
{
	[subListMenu removeAllItems];
	
	// 添加分割线
	NSMenuItem *mItem = [NSMenuItem separatorItem];
	[mItem setEnabled:NO];
	[mItem setTag:-2];
	[mItem setState:NSOffState];
	[subListMenu addItem:mItem];
	
	// 添加 隐藏字幕的菜单选项
	mItem = [[NSMenuItem alloc] init];
	[mItem setEnabled:YES];
	[mItem setTarget:self];
	[mItem setAction:@selector(setSubWithID:)];
	[mItem setTitle:kMPXStringDisable];
	[mItem setTag:-1];
	[mItem setState:NSOffState];
	[subListMenu addItem:mItem];
	[mItem release];	
}

-(void) gotSubInfo:(NSArray*) subs changed:(int)changeKind
{
	if (changeKind == NSKeyValueChangeSetting) {
		[self resetSubtitleMenu];
	}
	
	if (subs && (subs != (id)[NSNull null]) && [subs count]) {
		
		NSInteger idx = [subListMenu numberOfItems] - 2;
		NSMenuItem *mItem = nil;
		
		// 将所有的字幕名字加到菜单中
		for(NSString *str in subs) {
			mItem = [[NSMenuItem alloc] init];
			[mItem setEnabled:YES];
			[mItem setTarget:self];
			[mItem setAction:@selector(setSubWithID:)];
			[mItem setTitle:str];
			[mItem setTag:idx];
			[mItem setState:NSOffState];
			[subListMenu insertItem:mItem atIndex:idx];
			[mItem release];
			idx++;
		}
		
		if (changeKind == NSKeyValueChangeSetting) {
			[[subListMenu itemAtIndex:0] setState:NSOnState];
		} else {
			[self setSubWithID:mItem];
		}

		[menuSwitchSub setEnabled:YES];
		[menuSubScaleInc setEnabled:YES];
		[menuSubScaleDec setEnabled:YES];
		
	} else if (changeKind == NSKeyValueChangeSetting) {
		[menuSwitchSub setEnabled:NO];
		[menuSubScaleInc setEnabled:NO];
		[menuSubScaleDec setEnabled:NO];
	}
}

-(void) gotCachingPercent:(NSNumber*) caching
{
	NSWindow *win = [self window];
	float percent = [caching floatValue];
	
	if ([osd isActive] && (percent > 0.01)) {
		if (![win isVisible]) {
			[win makeKeyAndOrderFront:self];
		}
		
		[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDCachingPercent, percent*100]
					  owner:kOSDOwnerOther
				updateTimer:YES];
	}
}

-(void) resetAudioMenu
{
	[audioListMenu removeAllItems];
}

-(void) gotAudioInfo:(NSArray*) ais
{
	[audioListMenu removeAllItems];

	if (ais && (ais != (id)[NSNull null]) && [ais count]) {
		
		NSMenuItem *mItem = nil;
		
		for (id info in ais) {
			mItem = [[NSMenuItem alloc] init];
			[mItem setEnabled:YES];
			[mItem setTarget:self];
			[mItem setAction:@selector(setAudioWithID:)];
			[mItem setTitle:[info description]];
			[mItem setTag:[info ID]];
			[mItem setState:NSOffState];
			[audioListMenu addItem:mItem];
			[mItem release];
		}
		
		[[audioListMenu itemAtIndex:0] setState:NSOnState];
		
		[menuSwitchAudio setEnabled:YES];
	} else {
		[menuSwitchAudio setEnabled:NO];
	}
}

-(void) resetVideoMenu
{
	[videoListMenu removeAllItems];
}

-(void) gotVideoInfo:(NSArray*) vis
{
	[videoListMenu removeAllItems];
	
	if (vis && (vis != (id)[NSNull null]) && [vis count]) {
		
		NSMenuItem *mItem = nil;
		
		for (id info in vis) {
			mItem = [[NSMenuItem alloc] init];
			[mItem setEnabled:YES];
			[mItem setTarget:self];
			[mItem setAction:@selector(setVideoWithID:)];
			[mItem setTitle:[info description]];
			[mItem setTag:[info ID]];
			[mItem setState:NSOffState];
			[videoListMenu addItem:mItem];
			[mItem release];
		}
		
		[[videoListMenu itemAtIndex:0] setState:NSOnState];
		
		[menuSwitchVideo setEnabled:YES];
	} else {
		[menuSwitchVideo setEnabled:NO];
	}
}
////////////////////////////////////////////////draw myself//////////////////////////////////////////////////
- (void)drawRect:(NSRect)dirtyRect
{
	NSRect rc = [self bounds];
	NSPoint pt;
	
	//////////////////// main background
	NSBezierPath *fillPath = [NSBezierPath bezierPathWithRoundedRect:rc xRadius:CONTROL_CORNER_RADIUS yRadius:CONTROL_CORNER_RADIUS];
	[fillGradient drawInBezierPath:fillPath angle:270];

	//////////////////// top line
	[backGroundColor set];
	NSBezierPath *hilightPath = [NSBezierPath bezierPath];
	 
	pt.x = rc.size.width - CONTROL_CORNER_RADIUS;
	pt.y = rc.size.height;
	[hilightPath moveToPoint:pt];
	
	pt.x = CONTROL_CORNER_RADIUS;
	[hilightPath lineToPoint:pt];

	[hilightPath stroke];
	
	//////////////////// round corner line
	[backGroundColor2 set];
	
	NSBezierPath *roundPath = [NSBezierPath bezierPath];
	pt.x = rc.size.width;
	pt.y = rc.size.height - CONTROL_CORNER_RADIUS;
	[roundPath moveToPoint:pt];
	
	pt.x = rc.size.width - CONTROL_CORNER_RADIUS;
	[roundPath appendBezierPathWithArcWithCenter:pt radius:CONTROL_CORNER_RADIUS
									  startAngle:0 endAngle:90];
	pt.x = CONTROL_CORNER_RADIUS;
	pt.y = rc.size.height;
	[roundPath moveToPoint:pt];

	pt.y = rc.size.height - CONTROL_CORNER_RADIUS;
	[roundPath appendBezierPathWithArcWithCenter:pt radius:CONTROL_CORNER_RADIUS
									  startAngle:90 endAngle:180];
	[roundPath stroke];
}

-(void) calculateHintTime
{
	NSPoint pt = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	NSRect frm = timeSlider.frame;
	
	float timeDisp = ((pt.x-frm.origin.x) * [timeSlider maxValue])/ frm.size.width;;

	if ((([NSEvent modifierFlags] == kSCMSwitchTimeHintKeyModifierMask)?YES:NO) != 
		[ud boolForKey:kUDKeySwitchTimeHintPressOnAbusolute]) {
		// 如果没有按Fn，显示时间差
		// 否则显示绝对时间
		timeDisp -= [timeSlider floatValue];
	}
	[hintTime setIntValue:timeDisp + ((timeDisp>0)?0.5:-0.5)];
}

-(void) updateHintTime
{
	// 得到鼠标在CotrolUI中的位置
	NSPoint pt = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	NSRect frm = timeSlider.frame;

	// if the media is not seekable, timeSlider is disabled
	// but if the length of the media is available, we should display the hintTime, whether it is seekable or not
	if (NSPointInRect(pt, frm) && ([timeSlider maxValue] > 0)) {
		// 如果鼠标在timeSlider中
		// 更新时间
		[self calculateHintTime];
		
		CGFloat wd = [hintTime bounds].size.width;
		pt.x -= (wd/2);
		pt.x = MIN(pt.x, [self bounds].size.width - wd);
		pt.y = frm.origin.y + frm.size.height - 4;
		
		[hintTime setFrameOrigin:pt];
		
		[hintTime.animator setAlphaValue:1];
		// [self setNeedsDisplay:YES];
	} else {
		[hintTime.animator setAlphaValue:0];
	}
}

- (void)mouseDragged:(NSEvent *)event
{
	NSRect selfFrame = [self frame];
	NSRect contentBound = [[[self window] contentView] bounds];
	
	selfFrame.origin.x += [event deltaX];
	selfFrame.origin.y -= [event deltaY];
	
	selfFrame.origin.x = MAX(contentBound.origin.x, 
							 MIN(selfFrame.origin.x, contentBound.origin.x + contentBound.size.width - selfFrame.size.width));
	selfFrame.origin.y = MAX(contentBound.origin.y, 
							 MIN(selfFrame.origin.y, contentBound.origin.y + contentBound.size.height - selfFrame.size.height));
	
	[self setFrameOrigin:selfFrame.origin];
}

-(void) windowHasResized:(NSNotification *)notification
{
	[hintTime.animator setAlphaValue:0];
	
	// 这里是为了让字体大小符合窗口大小
	[osd setStringValue:nil owner:osd.owner updateTimer:NO];
}
@end
