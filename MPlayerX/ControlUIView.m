/*
 * MPlayerX - ControlUIView.m
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
#import "TimeSliderCell.h"

#define CONTROLALPHA		(1)
#define BACKGROUNDALPHA		(0.9)

#define CONTROL_CORNER_RADIUS	(6)

#define NUMOFVOLUMEIMAGES		(3)	//这个值是除了没有音量之后的image个数
#define AUTOHIDETIMEINTERNAL	(3)

#define LASTSTOPPEDTIMERATIO	(100)

#define ASPECTRATIOBASE			(900)

#define ABLOOPTAGBASE           (1000)

NSString * const kFillScreenButtonImageLRKey = @"LR";
NSString * const kFillScreenButtonImageUBKey = @"UB";

NSString * const kStringFMTTimeAppendTotal	= @" / %@";

#define PlayState	(NSOnState)
#define PauseState	(NSOffState)

@interface ControlUIView (ControlUIViewInternal)
-(void) windowHasResized:(NSNotification*)notification;
-(void) appWillTerminate:(NSNotification*)notif;
-(void) calculateHintTime;
-(void) resetSubtitleMenu;
-(void) resetAudioMenu;
-(void) resetVideoMenu;
-(void) resetChapterListMenu;
-(void) tryToHide;

-(void) playBackOpened:(NSNotification*)notif;
-(void) playBackStarted:(NSNotification*)notif;
-(void) playBackStopped:(NSNotification*)notif;
-(void) playBackWillStop:(NSNotification*)notif;
-(void) playInfoUpdated:(NSNotification*)notif;

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
-(void) gotChapterInfo:(NSArray*) cis;
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
					   boolNo, kUDKeyHideTitlebar,
					   [NSNumber numberWithFloat:0.001], kUDKeyFrameScaleStep,
					   boolNo, kUDKeyLBAutoHeightInFullScrn,
					   boolNo, kUDKeyPlayWhenEnterFullScrn,
					   boolYes, kUDKeyResizeControlBar,
                       boolNo, kUDKeyPauseShowTime,
                       boolYes, kUDKeyResumedShowTime,
                       [NSNumber numberWithFloat:-1.0f], kUDKeyControlUICenterYRatio,
                       boolNo, kUDKeyShowRealRemainingTime,
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
		chapterListMenu = [[NSMenu alloc] initWithTitle:@"ChapterListMenu"];
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

	if ([ud boolForKey:kUDKeyResizeControlBar]) {
		[self setAutoresizingMask:NSViewWidthSizable|NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin]; 
	} else {
		[self setAutoresizingMask:NSViewNotSizable|NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin];	 
	}
	
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
	[menuVolInc setKeyEquivalentModifierMask:0];
	[menuVolDec setKeyEquivalentModifierMask:0];
	
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
	
	[menuNextEpisode setKeyEquivalent:kSCMNextEpisodeKeyEquivalent];
	[menuPrevEpisode setKeyEquivalent:kSCMPrevEpisodeKeyEquivalent];

	[menuResetFrameScaleRatio setKeyEquivalentModifierMask:kSCMResetFrameScaleRatioKeyEquivalentModifierFlagMask];
	[menuResetFrameScaleRatio setKeyEquivalent:kSCMResetFrameScaleRatioKeyEquivalent];
	
	[menuEnlargeFrame setKeyEquivalentModifierMask:kSCMScaleFrameLargerKeyEquivalentModifierFlagMask];
	[menuEnlargeFrame setKeyEquivalent:kSCMScaleFrameLargerKeyEquivalent];
	[menuShrinkFrame setKeyEquivalentModifierMask:kSCMScaleFrameSmallerKeyEquivalentModifierFlagMask];
	[menuShrinkFrame setKeyEquivalent:kSCMScaleFrameSmallerKeyEquivalent];
	
	[menuEnlargeFrame2 setKeyEquivalentModifierMask:kSCMScaleFrameLarger2KeyEquivalentModifierFlagMask];
	[menuEnlargeFrame2 setKeyEquivalent:kSCMScaleFrameLargerKeyEquivalent];
	[menuShrinkFrame2 setKeyEquivalentModifierMask:kSCMScaleFrameSmaller2KeyEquivalentModifierFlagMask];
	[menuShrinkFrame2 setKeyEquivalent:kSCMScaleFrameSmallerKeyEquivalent];
	
	[menuMirror setKeyEquivalentModifierMask:kSCMMirrorKeyEquivalentModifierFlagMask];
	[menuMirror setKeyEquivalent:kSCMMirrorKeyEquivalent];
	[menuFlip setKeyEquivalentModifierMask:kSCMFlipKeyEquivalentModifierFlagMask];
	[menuFlip setKeyEquivalent:kSCMFlipKeyEquivalent];

	[menuSpeedUp setKeyEquivalent:kSCMSpeedUpKeyEquivalent];
	[menuSpeedDown setKeyEquivalent:kSCMSpeedDownKeyEquivalent];
	[menuSpeedReset setKeyEquivalent:kSCMSpeedResetKeyEquivalent];
	
	[menuAudioDelayInc setKeyEquivalentModifierMask:kSCMAudioDelayKeyEquivalentModifierFlagMask];
	[menuAudioDelayInc setKeyEquivalent:kSCMAudioDelayPlusKeyEquivalent];
	[menuAudioDelayDec setKeyEquivalentModifierMask:kSCMAudioDelayKeyEquivalentModifierFlagMask];
	[menuAudioDelayDec setKeyEquivalent:kSCMAudioDelayMinusKeyEquivalent];
	[menuAudioDelayReset setKeyEquivalentModifierMask:kSCMAudioDelayKeyEquivalentModifierFlagMask];
	[menuAudioDelayReset setKeyEquivalent:kSCMAudioDelayResetKeyEquivalent];
	
	[menuSubDelayInc setKeyEquivalentModifierMask:kSCMSubDelayKeyEquivalentModifierFlagMask];
	[menuSubDelayInc setKeyEquivalent:kSCMSubDelayPlusKeyEquivalent];
	[menuSubDelayDec setKeyEquivalentModifierMask:kSCMSubDelayKeyEquivalentModifierFlagMask];
	[menuSubDelayDec setKeyEquivalent:kSCMSubDelayMinusKeyEquivalent];
	[menuSubDelayReset setKeyEquivalentModifierMask:kSCMSubDelayKeyEquivalentModifierFlagMask];
	[menuSubDelayReset setKeyEquivalent:kSCMSubDelayResetKeyEquivalent];
	
    [menuZoomToHalfSize setKeyEquivalentModifierMask:kSCMWindowZoomHalfSizeKeyEquivalentModifierFlagMask];
    [menuZoomToHalfSize setKeyEquivalent:kSCMWindowZoomHalfSizeKeyEquivalent];
	[menuZoomToOriginSize setKeyEquivalentModifierMask:kSCMWindowZoomToOrgSizeKeyEquivalentModifierFlagMask];
	[menuZoomToOriginSize setKeyEquivalent:kSCMWindowZoomToOrgSizeKeyEquivalent];
	[menuZoomToDoubleSize setKeyEquivalentModifierMask:kSCMWindowZoomDblSizeKeyEquivalentModifierFlagMask];
	[menuZoomToDoubleSize setKeyEquivalent:kSCMWindowZoomDblSizeKeyEquivalent];
	[menuWndFitToScrn setKeyEquivalentModifierMask:kSCMWindowFitToScreenKeyEquivalentModifierFlagMask];
	[menuWndFitToScrn setKeyEquivalent:kSCMWindowFitToScreenKeyEquivalent];
    
    [menuABLPSetStart setKeyEquivalent:kSCMABLoopSetStartKeyEquivalent];
    [menuABLPSetReturn setKeyEquivalent:kSCMABLoopSetReturnKeyEquivalent];
    [menuABLPCancel setKeyEquivalent:kSCMABLoopSetCancelKeyEquivalent];
    
    [menuGotoSnapshotFolder setKeyEquivalentModifierMask:kSCMGotoSnapshotFolderKeyEquivalentModifierFlagMask];
    [menuGotoSnapshotFolder setKeyEquivalent:kSCMGotoSnapshotFolderKeyEquivalent];
	
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
	[volumeSlider sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];

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
	[timeSlider sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];

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
	
	[menuChapterList setSubmenu:chapterListMenu];
	[chapterListMenu setAutoenablesItems:NO];
	[self resetChapterListMenu];
	
	// set menuItem tags
	[menuSubScaleInc setTag:1];
	[menuSubScaleDec setTag:-1];
	
	[menuSizeInc setTag:1];
	[menuSizeDec setTag:-1];

	// set menu status
	[menuToggleLockAspectRatio setEnabled:NO];
	[menuToggleLockAspectRatio setTitle:([dispView lockAspectRatio])?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
	
	[menuToggleLetterBox setTitle:([ud integerForKey:kUDKeyLetterBoxMode] == kPMLetterBoxModeNotDisplay)?(kMPXStringMenuShowLetterBox):
																										 (kMPXStringMenuHideLetterBox)];
	[menuToggleFullScreen setEnabled:NO];
	[menuToggleFullScreen setTitle:kMPXStringMenuEnterFullscrn];
	
	[menuToggleFillScreen setEnabled:NO];
	
	[toggleAcceButton setTag:NO];

	[menuToggleAuxiliaryCtrls setTag:NO];
	[menuToggleAuxiliaryCtrls setTitle:kMPXStringMenuShowAuxCtrls];
	[menuToggleAuxiliaryCtrls setEnabled:NO];
    
    [menuABLPSetStart setTag:-1 * ABLOOPTAGBASE];
    [menuABLPSetReturn setTag:-1 * ABLOOPTAGBASE];
    
    [ud addObserver:self forKeyPath:kUDKeyDeIntMethod
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];

    //////ibtool bug fix, set noborder////////
	[volumeButton setBordered:NO];
	[nextEPButton setBordered:NO];
	[prevEPButton setBordered:NO];
	[playPauseButton setBordered:NO];
	[fillScreenButton setBordered:NO];
	[fullScreenButton setBordered:NO];
	[toggleAcceButton setBordered:NO];
	[timeText setBordered:NO];
	[timeTextAlt setBordered:NO];
	[timeDispSwitch setBordered:NO];
	
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

	[notifCenter addObserver:self selector:@selector(playInfoUpdated:)
						name:kMPCPlayInfoUpdatedNotification object:playerController];

    [notifCenter addObserver:self selector:@selector(appWillTerminate:)
                        name:NSApplicationWillTerminateNotification
                      object:NSApp];
	
	// this functioin must be called after the Notification is setuped
	[playerController setupKVO];

	// force hide titlebar
	[title setAlphaValue:([ud boolForKey:kUDKeyHideTitlebar])?0:CONTROLALPHA];

    float yRatio = [ud floatForKey:kUDKeyControlUICenterYRatio];
    if (yRatio > 0.0) {
        NSRect superFrame = [[self superview] frame];
        NSRect selfFrame = [self frame];
        // 这里最小值必须为1，为0的时候，ControlUI会跳到窗口最上部，原因未知
        selfFrame.origin.y = MIN(MAX(1, superFrame.size.height * yRatio - selfFrame.size.height / 2), superFrame.size.height - selfFrame.size.height-1);
        [self setFrameOrigin:selfFrame.origin];
    }
}

-(void) dealloc
{
	[notifCenter removeObserver:self];
    
    [ud removeObserver:self forKeyPath:kUDKeyDeIntMethod];
	
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
	
	[menuChapterList setSubmenu:nil];
	[chapterListMenu release];
	
	[fillGradient release];
	[backGroundColor release];
	[backGroundColor2 release];
	
	[super dealloc];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == ud) {
        if ([keyPath isEqualToString:kUDKeyDeIntMethod]) {
            // turn off all item
            for (NSMenuItem *item in [deintMenu itemArray]) {
                if ([item state] == NSOnState) {
                    [item setState:NSOffState];
                    break;
                }
            }
            
            // choose the current item
            [[deintMenu itemWithTag:[ud integerForKey:kUDKeyDeIntMethod]] setState:NSOnState];
        }
        return;
    }
    return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(BOOL) acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL) acceptsFirstResponder { return YES; }

-(void) mouseUp:(NSEvent *)theEvent
{
	if ([theEvent clickCount] != 2) {
        [super mouseUp:theEvent];
    }
}

-(void) refreshBackgroundAlpha
{
	[fillGradient release];
	[backGroundColor release];
	[backGroundColor2 release];
	
	float backAlpha = [ud floatForKey:kUDKeyCtrlUIBackGroundAlpha];

	fillGradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithDeviceWhite:0.220 alpha:backAlpha], 0.00f,
																  [NSColor colorWithDeviceWhite:0.150 alpha:backAlpha], 0.30f,
																  [NSColor colorWithDeviceWhite:0.090 alpha:backAlpha], 0.33f,
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
		autoHideTimer = [NSTimer timerWithTimeInterval:(autoHideTimeInterval + 1)/2
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
		// if HideTitlebar is ON or in fullscreen, ignore the titlebar area when hiding the cursor
		if ((!NSPointInRect([self  convertPoint:pos fromView:nil], self.bounds)) && 
			((!NSPointInRect([title convertPoint:pos fromView:nil], title.bounds)) || [ud boolForKey:kUDKeyHideTitlebar] || [dispView isInFullScreenMode])) {
            [[self window] makeFirstResponder:dispView];
			[self.animator setAlphaValue:0];
			
			// 如果是全屏模式也要隐藏鼠标
			if ([dispView isInFullScreenMode]) {
				// 这里的[self window]不是成员的那个window，而是全屏后self的新window
				if ([[self window] isKeyWindow] && NSPointInRect([NSEvent mouseLocation], [[self window] frame])) {
					// 如果不是key window的话，就不隐藏鼠标
					[NSCursor hide];
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
		[NSCursor unhide];
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
    
    if (([ud boolForKey:kUDKeyPauseShowTime] && (playerController.playerState == kMPCPausedState)) ||
        ([ud boolForKey:kUDKeyResumedShowTime] && (playerController.playerState == kMPCPlayingState))) {
        [self updateOSDTime:[timeSlider floatValue]];
    } else {
        [osd setStringValue:osdStr owner:kOSDOwnerOther updateTimer:YES];
    }
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
    
    [self updateOSDTime:time];
}

-(void) changeTimeBy:(float) delta
{
	delta = [playerController changeTimeBy:delta];
    
    [self updateOSDTime:delta];
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
				[NSCursor hide];
			}
			
			// 进入全屏，强制隐藏resizeindicator
			[rzIndicator setAlphaValue:0];
			// 这里应该判断kUDKeyHideTitlebar的，但是由于这里是要隐藏title
			// 因此多次将AlphaValue设置为0也不会有坏影响
			[title setAlphaValue:0];
			
			[menuToggleLockAspectRatio setTitle:([dispView lockAspectRatio])?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
			[menuToggleLockAspectRatio setEnabled:NO];
			
			[menuEnlargeFrame setEnabled:YES];
			[menuShrinkFrame setEnabled:YES];
			[menuEnlargeFrame2 setEnabled:YES];
			[menuShrinkFrame2 setEnabled:YES];
			[menuWndFitToScrn setEnabled:NO];
			
			if ([ud boolForKey:kUDKeyLBAutoHeightInFullScrn]) {
				NSInteger lb = [ud integerForKey:kUDKeyLetterBoxMode];
				float height = [ud floatForKey:kUDKeyLetterBoxHeight];
				
				NSSize scrnSize = [[[dispView window] screen] frame].size;
				float margin;
				
				switch (lb) {
					case kPMLetterBoxModeBoth:
						margin = ((scrnSize.height * (1 + height * 2) * [dispView aspectRatio] / scrnSize.width) - 1) / 2;
						// MPLog(@"SRN:%f,%f, AR:%f, MH:%f, MRG:%f", scrnSize.width, scrnSize.height, [dispView aspectRatio], [dispView displaySize].height, margin);
						MPLog(@"AutoLBH, AR:%f, margin:%f", [dispView aspectRatio], margin);
						if (margin > 0) {
							[playerController setLetterBox:YES top:margin bottom:margin];
							// [playerController changeTimeBy:0.01f];
						}
						break;
					case kPMLetterBoxModeBottomOnly:
						margin = ((scrnSize.height * (1 + height) * [dispView aspectRatio] / scrnSize.width) - 1);
						// NSLog(@"SRN:%f,%f, AR:%f, MH:%f, MRG:%f", scrnSize.width, scrnSize.height, [dispView aspectRatio], [dispView displaySize].height, margin);
						MPLog(@"AutoLBH, AR:%f, margin:%f", [dispView aspectRatio], margin);
						if (margin > 0) {
							[playerController setLetterBox:YES top:-1.0f bottom:margin];
							// [playerController changeTimeBy:0.01f];
						}
						break;
					case kPMLetterBoxModeTopOnly:
						margin = ((scrnSize.height * (1 + height) * [dispView aspectRatio] / scrnSize.width) - 1);
						// NSLog(@"SRN:%f,%f, AR:%f, MH:%f, MRG:%f", scrnSize.width, scrnSize.height, [dispView aspectRatio], [dispView displaySize].height, margin);
						MPLog(@"AutoLBH, AR:%f, margin:%f", [dispView aspectRatio], margin);
						if (margin > 0) {
							[playerController setLetterBox:YES top:margin bottom:-1.0f];
							// [playerController changeTimeBy:0.01f];
						}
						break;
					default:		
						margin = ((scrnSize.height * [dispView aspectRatio] / scrnSize.width) - 1);
						// NSLog(@"SRN:%f,%f, AR:%f, MH:%f, MRG:%f", scrnSize.width, scrnSize.height, [dispView aspectRatio], [dispView displaySize].height, margin);
						MPLog(@"AutoLBH, AR:%f, margin:%f", [dispView aspectRatio], margin);
						if (margin > 0) {
							NSInteger lbAlt = [ud integerForKey:kUDKeyLetterBoxModeAlt];
							
							switch (lbAlt) {
								case kPMLetterBoxModeBoth:
									margin /= 2;
									[playerController setLetterBox:YES top:margin bottom:margin];
									// [playerController changeTimeBy:0.01f];
									break;
								case kPMLetterBoxModeBottomOnly:
									[playerController setLetterBox:YES top:-1.0f bottom:margin];
									// [playerController changeTimeBy:0.01f];
									break;
								case kPMLetterBoxModeTopOnly:
									[playerController setLetterBox:YES top:margin bottom:-1.0f];
									// [playerController changeTimeBy:0.01f];
									break;
								default:
									break;
							}
						}
						break;						
				}
			}
			
			if ([ud boolForKey:kUDKeyPlayWhenEnterFullScrn] && ([playerController playerState] == kMPCPausedState)) {
				[self togglePlayPause:nil];
			}
		} else {
			// 退出全屏
			[NSCursor unhide];

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
			
			[menuEnlargeFrame setEnabled:NO];
			[menuShrinkFrame setEnabled:NO];
			[menuEnlargeFrame2 setEnabled:NO];
			[menuShrinkFrame2 setEnabled:NO];
			[menuWndFitToScrn setEnabled:YES];
			
			if ([ud boolForKey:kUDKeyLBAutoHeightInFullScrn]) {
				[self toggleLetterBox:nil];
			}
		}
	} else {
		// 失败
		[fullScreenButton setState: NSOffState];
		[menuToggleFullScreen setTitle:kMPXStringMenuEnterFullscrn];
		
		[fillScreenButton setHidden: YES];
		[menuToggleFillScreen setEnabled:NO];
		
		[menuToggleLockAspectRatio setEnabled:NO];
		
		[menuEnlargeFrame setEnabled:NO];
		[menuShrinkFrame setEnabled:NO];
		[menuEnlargeFrame2 setEnabled:NO];
		[menuShrinkFrame2 setEnabled:NO];
		[menuWndFitToScrn setEnabled:NO];
	}
	[self windowHasResized:nil];
}

-(IBAction) toggleFillScreen:(id)sender
{
	if (sender || ([fillScreenButton state] == NSOnState)) {
		// 如果sender为nil
		// 那说明是程序内部发出的重置信号，根据button的状态决定是否触发toggle
		BOOL status = [dispView toggleFillScreen];
		if (status) {
			[fillScreenButton setState:NSOnState];
			[menuToggleFillScreen setState:NSOnState];
		} else {
			[fillScreenButton setState:NSOffState];
			[menuToggleFillScreen setState:NSOffState];
		}
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
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		// from changespeed menu
		if ([sender tag]) {
			// if not zero, means not reset
			[playerController changeSpeedBy:[sender tag] * [ud floatForKey:kUDKeySpeedStep]];
		} else {
			// if zero, reset
			[playerController setSpeed:1];
		}
	} else {
		// from textfield
		[playerController setSpeed:[sender floatValue]];
	}
}

-(IBAction) changeAudioDelay:(id) sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		if ([sender tag]) {
			[playerController changeAudioDelayBy:[sender tag] * [ud floatForKey:kUDKeyAudioDelayStepTime]];
		} else {
			[playerController setAudioDelay:0];
		}
	} else {
		[playerController setAudioDelay:[sender floatValue]];	
	}
}

-(IBAction) changeSubDelay:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		if ([sender tag]) {
			[playerController changeSubDelayBy:[sender tag] * [ud floatForKey:kUDKeySubDelayStepTime]];
		} else {
			[playerController setSubDelay:0];
		}
	} else {
		[playerController setSubDelay:[sender floatValue]];
	}
}

-(IBAction) changeSubScale:(id)sender
{
	[playerController changeSubScaleBy:[sender tag] * [ud floatForKey:kUDKeySubScaleStepValue]];
}

-(IBAction) stepSubtitles:(id)sender
{
	NSInteger selectedTag = -2;
	NSMenuItem* mItem;
	
	// 找到目前被选中的字幕
	for (mItem in [subListMenu itemArray]) {
		if (([mItem state] == NSOnState) && (![mItem isSeparatorItem])) {
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
		[playerController setSubtitle:(int)[sender tag]];
		
		for (NSMenuItem* mItem in [subListMenu itemArray]) {
			if (([mItem state] == NSOnState) && (![mItem isSeparatorItem])) {
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
		[playerController setAudio:(int)[sender tag]];
		
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
		[playerController setVideo:(int)[sender tag]];
		
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

-(IBAction) setChapterWithTime:(id)sender
{
	if (sender) {
		[playerController seekTo:[sender tag] / kMPCChapterTimeBase mode:kMPCSeekModeRelative];
		
		[self updateHintTime];
		
		[osd setStringValue:[NSString stringWithFormat:kMPXStringOSDChapterHint, [sender representedObject]]
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

-(IBAction) setAspectRatio:(id)sender
{
	[dispView setAspectRatio:((CGFloat)[sender tag]) / ASPECTRATIOBASE];
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
	// [playerController changeTimeBy:0.01f];
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

-(IBAction) resetFrameScaleRatio:(id)sender
{
	[dispView resetFrameScaleRatio];
}

-(IBAction) stepFrameScale:(id)sender
{
	CGSize rt;
	rt.width = [sender tag] * [ud floatForKey:kUDKeyFrameScaleStep];
	rt.height = rt.width;
	
	[dispView changeFrameScaleRatioBy:rt];
}

-(IBAction) toggleMirror:(id)sender
{
	[dispView setMirror:![dispView mirror]];
	
	[menuMirror setState:([dispView mirror])?(NSOnState):(NSOffState)];
}

-(IBAction) toggleFlip:(id)sender
{
	[dispView setFlip:![dispView flip]];
	
	[menuFlip setState:([dispView flip])?(NSOnState):(NSOffState)];
}

-(IBAction) zoomToSize:(id)sender
{
	[dispView zoomToSize:((float)[sender tag]) / 4];
}

-(IBAction) toggleTimeAltDisplayMode:(id)sender
{
	[ud setBool:![ud boolForKey:kUDKeyTimeTextAltTotal] forKey:kUDKeyTimeTextAltTotal];
}

-(IBAction) mapAudioChannelsTo:(id)sender
{
	[playerController mapAudioChannelsTo:[sender tag]];
	
	for (NSMenuItem *mitem in [[menuAudioChannels submenu] itemArray]) {
		if (([mitem state] == NSOnState) && (![mitem isSeparatorItem])) {
			[mitem setState:NSOffState];
			break;
		}
	}
	[sender setState:NSOnState];
}

-(IBAction) setABLoopStart:(id)sender
{
    float timeStart = [[playerController mediaInfo].playingInfo.currentTime floatValue];
    float timeEnd = ((float)[menuABLPSetReturn tag]) / ABLOOPTAGBASE;
    
    [menuABLPSetStart setTitle:[NSString stringWithFormat:kMPXStringABLPUpdateStart,
                                                          [TimeFormatter stringForIntegerValue:(NSInteger)timeStart]]];
    [menuABLPSetStart setTag:timeStart * ABLOOPTAGBASE];
    
    [playerController startABLoopFrom:timeStart to:timeEnd];
    
    [osd setStringValue:[NSString stringWithFormat:@"%@: %@ ~ %@", 
                                                   kMPXStringABLPPrefix,
                                                   (timeStart >=0)?([TimeFormatter stringForIntegerValue:(NSInteger)timeStart]):(@""),
                                                   (timeEnd   >=0)?([TimeFormatter stringForIntegerValue:(NSInteger)timeEnd])  :(@"")]
                  owner:kOSDOwnerOther
            updateTimer:YES];
}

-(IBAction) setABLoopReturn:(id)sender
{
    float timeEnd = [[playerController mediaInfo].playingInfo.currentTime floatValue];
    float timeStart = ((float)[menuABLPSetStart tag]) / ABLOOPTAGBASE;
    
    [menuABLPSetReturn setTitle:[NSString stringWithFormat:kMPXStringABLPUpdateReturn,
                                                           [TimeFormatter stringForIntegerValue:(NSInteger)timeEnd]]];
    [menuABLPSetReturn setTag:timeEnd * ABLOOPTAGBASE];

    [playerController startABLoopFrom:timeStart to:timeEnd];
    
    [osd setStringValue:[NSString stringWithFormat:@"%@: %@ ~ %@", 
                                                   kMPXStringABLPPrefix,
                                                   (timeStart >=0)?([TimeFormatter stringForIntegerValue:(NSInteger)timeStart]):(@""),
                                                   (timeEnd   >=0)?([TimeFormatter stringForIntegerValue:(NSInteger)timeEnd])  :(@"")]
                  owner:kOSDOwnerOther
            updateTimer:YES];    
}

-(IBAction) stopABLoop:(id)sender
{
    [playerController stopABLoop];

    [menuABLPSetStart setTag:-1 * ABLOOPTAGBASE];
    [menuABLPSetReturn setTag:-1 * ABLOOPTAGBASE];

    [menuABLPSetStart setTitle:kMPXStringABLPSetStart];
    [menuABLPSetReturn setTitle:kMPXStringABLPSetReturn];
    
    [osd setStringValue:[NSString stringWithFormat:@"%@: %@", kMPXStringABLPPrefix, kMPXStringABLPCancelled]
                  owner:kOSDOwnerOther
            updateTimer:YES];    
}

-(IBAction) choseDeinterlaceMethod:(id)sender
{
    // set userdefault
    [ud setInteger:[sender tag] forKey:kUDKeyDeIntMethod];
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
		[menuWndFitToScrn setEnabled:YES];
	}
	[menuToggleLockAspectRatio setTitle:([dispView lockAspectRatio])?(kMPXStringMenuUnlockAspectRatio):(kMPXStringMenuLockAspectRatio)];
    [menuZoomToHalfSize setEnabled:YES];
	[menuZoomToOriginSize setEnabled:YES];
	[menuZoomToDoubleSize setEnabled:YES];
}

-(void) displayStopped
{
	[fullScreenButton setHidden: YES];
	
	[menuToggleFullScreen setEnabled:NO];
	[menuSnapshot setEnabled:NO];
	[menuToggleLockAspectRatio setEnabled:NO];
    [menuZoomToHalfSize setEnabled:NO];
	[menuZoomToOriginSize setEnabled:NO];
	[menuZoomToDoubleSize setEnabled:NO];
	[menuWndFitToScrn setEnabled:NO];
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
	[audioDelayText setEnabled:YES];
	
	[menuSwitchAudio setEnabled:YES];
	[menuSwitchVideo setEnabled:YES];
	
	[menuToggleAuxiliaryCtrls setEnabled:YES];
	
	[menuSpeedUp setEnabled:YES];
	[menuSpeedDown setEnabled:YES];
	[menuAudioDelayInc setEnabled:YES];
	[menuAudioDelayDec setEnabled:YES];
	
	if ([playerController isPassingThrough]) {
		[volumeButton setEnabled:NO];
		[volumeSlider setEnabled:NO];
		[menuVolInc setEnabled:NO];
		[menuVolDec setEnabled:NO];		
	} else {
		[menuAudioChannels setEnabled:YES];
		for (NSMenuItem *mitem in [[menuAudioChannels submenu] itemArray]) {
			if ([mitem tag] == kMPCMonoAudioNone) {
				[mitem setState:NSOnState];
			} else {
				[mitem setState:NSOffState];
			}
		}
		// 如果是DD的设置的话，ParameterManager里面不会设置音量。
		// 但是如果最后文件不是按照DD播放的话，需要重新设置音量
		// 并且不显示OSD
		BOOL oldAct = [osd isActive];
		[osd setActive:NO];
		// 这个可能是mplayer的bug，当轮转一圈从各个音轨到无声在回到音轨时，声音会变到最大，所以这里再设定一次音量
		[self setVolume:volumeSlider];
		[osd setActive:oldAct];
	}
	
	[self showUp];
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
	[volumeButton setEnabled:YES];
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
	
	[menuSpeedUp setEnabled:NO];
	[menuSpeedDown setEnabled:NO];
	[menuAudioDelayInc setEnabled:NO];
	[menuAudioDelayDec setEnabled:NO];
	[menuSubDelayInc setEnabled:NO];
	[menuSubDelayDec setEnabled:NO];
	
	[menuAudioChannels setEnabled:NO];
    
    [menuABLPSetStart setTitle:kMPXStringABLPSetStart];
    [menuABLPSetReturn setTitle:kMPXStringABLPSetReturn];
    [menuABLPSetStart setTag:-1 * ABLOOPTAGBASE];
    [menuABLPSetReturn setTag:-1 * ABLOOPTAGBASE];
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
		
	} else if ([keyPath isEqualToString:kKVOPropertyKeyPathChapterInfo]) {
		// got chapter info
		[self gotChapterInfo:[change objectForKey:NSKeyValueChangeNewKey]];
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
            if ([ud boolForKey:kUDKeyShowRealRemainingTime]) {
                [timeTextAlt setIntValue:time - length - 0.5];
            } else {
                [timeTextAlt setIntValue:((time - length - 0.5) / [[playerController mediaInfo].playingInfo.speed floatValue])];
            }
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
			// 这个地方只有在最初playback刚刚开始，sub加载的时候才会被调用，因此是安全的
			// 当sub被clear的时候，是不会进入这个分支的
			[[subListMenu itemWithTag:[[[[playerController mediaInfo] playingInfo] currentSubID] integerValue]]
			 setState:NSOnState];
		} else {
			// 当某个sub在中途被加载的时候会调用这里
			// 默认激活这个载入的sub
			[self setSubWithID:mItem];
			
			// 这是一个权宜之计，因为在暂停的情况下加载字幕的话
			// 因为无法保持暂停状态而加载，所以播放会自动开始
			// 这样会造成mplayer状态和MPX状态不一致，这里判断MPX的状态，如果是暂停情况下加载的话，就toggle
			// 底层发出的命令是 pause -1,该命令在播放状态下没有副作用，只是重置了MPX的状态。
			if ([playerController playerState] == kMPCPausedState) {
				[self togglePlayPause:nil];
			}
		}

		[menuSwitchSub setEnabled:YES];
		[menuSubScaleInc setEnabled:YES];
		[menuSubScaleDec setEnabled:YES];
		[menuSubDelayInc setEnabled:YES];
		[menuSubDelayDec setEnabled:YES];

		[subDelayText setEnabled:YES];
		
	} else if (changeKind == NSKeyValueChangeSetting) {
		[menuSwitchSub setEnabled:NO];
		[menuSubScaleInc setEnabled:NO];
		[menuSubScaleDec setEnabled:NO];
		[menuSubDelayInc setEnabled:NO];
		[menuSubDelayDec setEnabled:NO];
	
		[subDelayText setEnabled:NO];
	}
}

-(void) gotCachingPercent:(NSNumber*) caching
{
	NSWindow *win = [self window];
	float percent = [caching floatValue];
	
	if ([osd isActive] && (percent > 0.01)) {
		if (![win isVisible]) {
			[win orderFront:self];
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

-(void) resetChapterListMenu
{
	[chapterListMenu removeAllItems];
}

-(void) gotChapterInfo:(NSArray*) cis
{
	[chapterListMenu removeAllItems];
	
	if (cis && (cis != (id)[NSNull null]) && [cis count]) {
		
		NSMenuItem *mItem = nil;
		
		for (ChapterItem *info in cis) {
			mItem = [[NSMenuItem alloc] init];
			[mItem setEnabled:YES];
			[mItem setTarget:self];
			[mItem setAction:@selector(setChapterWithTime:)];
			[mItem setTitle:[info description]];
			[mItem setTag:[info start]];
			[mItem setState:NSOffState];
			[mItem setRepresentedObject:[info name]];
			
			[chapterListMenu addItem:mItem];
			[mItem release];
		}
		
		[menuChapterList setEnabled:YES];
	} else {
		[menuChapterList setEnabled:NO];
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
	NSRect frm = [[timeSlider cell] effectiveRect];
	
	float timeDisp = ((pt.x-frm.origin.x) * [timeSlider maxValue])/ (frm.size.width);

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
	NSRect frm = [[timeSlider cell] effectiveRect];

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
	} else {
		[hintTime.animator setAlphaValue:0];
	}
}

-(void) updateOSDTime:(float)time
{
	if ([osd isActive] && (time > 0)) {
		NSString *osdStr = [timeFormatter stringForObjectValue:[NSNumber numberWithFloat:time]];
		double length = [timeSlider maxValue];
		
		if (length > 0) {
			osdStr = [osdStr stringByAppendingFormat:kStringFMTTimeAppendTotal, [timeFormatter stringForObjectValue:[NSNumber numberWithDouble:length]]];
		}
		[osd setStringValue:osdStr owner:kOSDOwnerTime updateTimer:YES];
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

-(void) appWillTerminate:(NSNotification*)notif
{
    NSRect selfFrame = [self frame];

    [ud setFloat:(selfFrame.origin.y + selfFrame.size.height / 2) / [[self superview] frame].size.height
          forKey:kUDKeyControlUICenterYRatio];
    [ud synchronize];
}

-(void)resetPosition
{
    NSRect rcWin = [[self superview] frame];
    NSRect rcSelf = self.frame;

    rcSelf.size.width = MIN(rcSelf.size.width, rcWin.size.width - rcSelf.origin.x);

    [self setFrame:rcSelf];
    [rzIndicator resetPosition];
}
@end
