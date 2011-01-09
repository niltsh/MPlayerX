/*
 * MPlayerX - ControlUIView.h
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

@class RootLayerView, PlayerController, FloatWrapFormatter, ArrowTextField, ResizeIndicator, OsdText, TitleView, TimeFormatter;

@interface ControlUIView : NSView
{
	NSUserDefaults *ud;
	NSNotificationCenter *notifCenter;

	// button images
	NSDictionary *fillScreenButtonAllImages;
	NSArray *volumeButtonImages;
	
	NSGradient *fillGradient;
	NSColor *backGroundColor;
	NSColor *backGroundColor2;

	// formatters
	TimeFormatter *timeFormatter;
	FloatWrapFormatter *floatWrapFormatter;

	// autohide things
	NSTimeInterval autoHideTimeInterval;
	BOOL shouldHide;
	NSTimer *autoHideTimer;

	// list for sub/audio/video
	NSMenu *subListMenu;
	NSMenu *audioListMenu;
	NSMenu *videoListMenu;
		
	float volStep;
	float orgHeight;

	IBOutlet PlayerController *playerController;
	IBOutlet RootLayerView *dispView;
	IBOutlet NSButton *fillScreenButton;
	IBOutlet NSButton *fullScreenButton;
	IBOutlet NSButton *playPauseButton;
	IBOutlet NSButton *volumeButton;
	IBOutlet NSSlider *volumeSlider;
	IBOutlet NSTextField *timeText;
	IBOutlet NSTextField *timeTextAlt;
	
	IBOutlet NSSlider *timeSlider;
	IBOutlet NSTextField *hintTime;
	
	IBOutlet NSView *accessaryContainer;
	IBOutlet NSButton *toggleAcceButton;

	IBOutlet ArrowTextField *speedText;
	IBOutlet ArrowTextField *subDelayText;
	IBOutlet ArrowTextField *audioDelayText;
	
	IBOutlet ResizeIndicator *rzIndicator;
	IBOutlet OsdText *osd;
	IBOutlet TitleView *title;
	
	IBOutlet NSMenuItem *menuSnapshot;
	IBOutlet NSMenuItem *menuSwitchSub;
	IBOutlet NSMenuItem *menuSubScaleInc;
	IBOutlet NSMenuItem *menuSubScaleDec;
	IBOutlet NSMenuItem *menuPlayFromLastStoppedPlace;
	IBOutlet NSMenuItem *menuSwitchAudio;
	IBOutlet NSMenuItem *menuVolInc;
	IBOutlet NSMenuItem *menuVolDec;
	IBOutlet NSMenuItem *menuToggleLockAspectRatio;
	IBOutlet NSMenuItem *menuResetLockAspectRatio;
	IBOutlet NSMenuItem *menuToggleLetterBox;
	IBOutlet NSMenuItem *menuSwitchVideo;
	IBOutlet NSMenuItem *menuSizeInc;
	IBOutlet NSMenuItem *menuSizeDec;
	IBOutlet NSMenuItem *menuShowMediaInfo;
	IBOutlet NSMenuItem *menuToggleFullScreen;
	IBOutlet NSMenuItem *menuToggleFillScreen;
	IBOutlet NSMenuItem *menuToggleAuxiliaryCtrls;
	IBOutlet NSMenuItem *menuMoveToTrash;
	IBOutlet NSMenuItem *menuMoveFrameToCenter;
}

////////////////////////////////显示相关////////////////////////////////
extern NSString * const kFillScreenButtonImageLRKey;
extern NSString * const kFillScreenButtonImageUBKey;
-(void) setFillScreenMode:(NSString*)modeKey state:(NSInteger) state;

-(void) displayStarted;
-(void) displayStopped;

//////////////////////////////自动隐藏相关/////////////////////////////
-(void) showUp;
-(void) updateHintTime;
-(void) doHide;
-(void) refreshBackgroundAlpha;
-(void) refreshAutoHideTimer;
-(void) refreshOSDSetting;

//////////////////////////////其他控件相关/////////////////////////////
-(IBAction) togglePlayPause:(id)sender;
-(IBAction) toggleMute:(id)sender;

-(IBAction) setVolume:(id)sender;
-(IBAction) changeVolumeBy:(id)sender;

-(IBAction) seekTo:(id) sender;
-(void) changeTimeBy:(float) delta;

-(IBAction) toggleFullScreen:(id)sender;
-(IBAction) toggleFillScreen:(id)sender;

-(IBAction) toggleAccessaryControls:(id)sender;
-(IBAction) changeSpeed:(id) sender;
-(IBAction) changeAudioDelay:(id) sender;
-(IBAction) changeSubDelay:(id)sender;

-(IBAction) stepSubtitles:(id)sender;
-(IBAction) setSubWithID:(id)sender;

-(IBAction) changeSubScale:(id)sender;

-(IBAction) stepAudios:(id)sender;
-(IBAction) setAudioWithID:(id)sender;

-(IBAction) stepVideos:(id)sender;
-(IBAction) setVideoWithID:(id)sender;

-(IBAction) changeSubPosBy:(id)sender;
-(IBAction) changeAudioBalanceBy:(id)sender;

-(IBAction) toggleLockAspectRatio:(id)sender;
-(IBAction) resetAspectRatio:(id)sender;

-(IBAction) toggleLetterBox:(id)sender;

-(IBAction) stepWindowSize:(id)sender;

-(IBAction) moveFrameToCenter:(id)sender;
@end
