/*
 * MPlayerX - RootLayerView.h
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
#import "coredef.h"

@class ControlUIView, PlayerController, ShortCutManager, DisplayLayer, OsdText, VideoTunerController, TitleView, PlayerWindow, OsdText;

@interface RootLayerView : NSView <CoreDisplayDelegate>
{
	NSUserDefaults *ud;
	NSNotificationCenter *notifCenter;

	NSTrackingArea *trackingArea;
	NSImage *logo;
	
	BOOL shouldResize;
	NSRect rcBeforeFullScrn;
	
	DisplayLayer *dispLayer;
	
	BOOL displaying;
	NSMutableDictionary *fullScreenOptions;
	NSInteger fullScreenStatus;
	
	BOOL lockAspectRatio;
	CGFloat frameAspectRatio;
	
	NSPoint dragMousePos;
	BOOL dragShouldResize;
	
	BOOL firstDisplay;
	BOOL playbackFinalized;
	
	BOOL canMoveAcrossMenuBar;
	
	NSInteger threeFingersTap;
	NSInteger threeFingersPinch;
	float threeFingersPinchDistance;
	NSInteger fourFingersPinch;
	float fourFingersPinchDistance;
    NSInteger threeFingersSwipe;
    NSPoint threeFingersSwipeCord;
    // BOOL hasSwipeEvent;
    
    NSTimeInterval lastScrollLR;
	
	// 在切换全屏的时候，view的window会发生变化，因此这里用一个成员变量锁定window
	IBOutlet PlayerWindow *playerWindow;
	IBOutlet ControlUIView *controlUI;
	IBOutlet PlayerController *playerController;
	IBOutlet ShortCutManager *shortCutManager;
	IBOutlet VideoTunerController *VTController;
	IBOutlet TitleView *titlebar;
    IBOutlet OsdText *osd;
}

@property (assign, readwrite, nonatomic) BOOL lockAspectRatio;

-(void) resetAspectRatio;
-(void) setPlayerWindowLevel;

-(BOOL) toggleFullScreen;
-(BOOL) toggleFillScreen;

-(void) changeWindowSizeBy:(NSSize)delta animate:(BOOL)animate;
-(CIImage*) snapshot;
-(CGFloat) aspectRatio;

-(void) moveFrameToCenter;

-(void) changeFrameScaleRatioBy:(CGSize)rt;
-(void) resetFrameScaleRatio;

-(BOOL) mirror;
-(BOOL) flip;
-(void) setMirror:(BOOL)m;
-(void) setFlip:(BOOL)f;

-(void) zoomToSize:(float)ratio;

-(void) setAspectRatio:(CGFloat)ar;
@end
