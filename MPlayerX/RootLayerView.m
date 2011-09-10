/*
 * MPlayerX - RootLayerView.m
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

#import <Quartz/Quartz.h>
#import "UserDefaults.h"
#import "KeyCode.h"
#import "RootLayerView.h"
#import "DisplayLayer.h"
#import "ControlUIView.h"
#import "PlayerController.h"
#import "ShortCutManager.h"
#import "OsdText.h"
#import "VideoTunerController.h"
#import "TitleView.h"
#import "CocoaAppendix.h"

#define kOnTopModeNormal		(0)
#define kOnTopModeAlways		(1)
#define kOnTopModePlaying		(2)

#define kScaleFrameRatioMinLimit	(0.05f)
#define kScaleFrameRatioStepMax		(0.20f)

#define kThreeFingersTapInit		(0)
#define kThreeFingersTapInvalid		(-1)
#define kThreeFingersTapReady		(1)

#define kThreeFingersPinchInit		(0)
#define kThreeFingersPinchInvalid	(-1)
#define kThreeFingersPinchReady		(1)

#define kFourFingersPinchInit		(0)
#define kFourFingersPinchInvalid	(-1)
#define kFourFingersPinchReady		(1)

// calculateFrameFrom:(NSRect)orgFrame toFit:(CGFloat)ar mode:(NSUInteger)modeMask;
#define kCalFrameSizeDiag			(1)
#define kCalFrameSizeInFit			(2)
#define kCalFrameSizeMask			(0xFF)

#define kCalFrameFixPosCenter		(1 << 8)
#define kCalFrameFixPosUpleft		(2 << 8)
#define kCalFrameFixPosMask			(0xFF00)

@interface RootLayerView (RootLayerViewInternal)
-(void) setExternalAspectRatio:(CGFloat)ar;
-(void) updateFrameForFullScreen;
-(NSRect) calculateFrameFrom:(NSRect)orgFrame toFit:(CGFloat)ar mode:(NSUInteger)modeMask;
-(void) setupLayers;
-(void) reorderSubviews;
-(void) prepareForStartingDisplay;

-(void) playBackOpened:(NSNotification*)notif;
-(void) playBackStarted:(NSNotification*)notif;
-(void) playBackStopped:(NSNotification*)notif;
-(void) playeBackFinalized:(NSNotification*)notif;

-(void) applicationDidBecomeActive:(NSNotification*)notif;
-(void) applicationDidResignActive:(NSNotification*)notif;
@end

@interface RootLayerView (CoreDisplayDelegate)
-(int)  coreController:(id)sender startWithFormat:(DisplayFormat)df buffer:(char**)data total:(NSUInteger)num;
-(void) coreController:(id)sender draw:(NSUInteger)frameNum;
-(void) coreControllerStop:(id)sender;
@end

@implementation RootLayerView

@synthesize fullScrnDevID;
@synthesize lockAspectRatio;

#pragma mark Init/Dealloc
+(void) initialize
{
	NSNumber *boolYes = [NSNumber numberWithBool:YES];
	NSNumber *boolNo  = [NSNumber numberWithBool:NO];
	
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithInt:kOnTopModePlaying], kUDKeyOnTopMode,
					   boolNo, kUDKeyStartByFullScreen,
					   boolYes, kUDKeyFullScreenKeepOther,
					   boolNo, kUDKeyQuitOnClose,
					   boolNo, kUDKeyPinPMode,
					   boolNo, kUDKeyAlwaysHideDockInFullScrn,
					   boolYes, kUDKeyDisableHScrollSeek,
					   boolNo, kUDKeyDisableVScrollVol,
					   [NSNumber numberWithFloat:1.5], kUDKeyThreeFingersPinchThreshRatio,
					   [NSNumber numberWithFloat:1.8], kUDKeyFourFingersPinchThreshRatio,
					   boolNo, kUDKeyCloseWndOnEsc,
					   boolYes, kUDKeyDontResizeWhenContinuousPlay,
					   nil]];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
		trackingArea = [[NSTrackingArea alloc] initWithRect:NSInsetRect([self frame], 1, 1) 
													options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect
													  owner:self
												   userInfo:nil];
		[self addTrackingArea:trackingArea];
		shouldResize = NO;
		rcBeforeFullScrn = [[self window] frame];
		
		dispLayer = [[DisplayLayer alloc] init];
		displaying = NO;
		fullScreenOptions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
							 [NSNumber numberWithInt:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar], NSFullScreenModeApplicationPresentationOptions,
							 [NSNumber numberWithBool:![ud boolForKey:kUDKeyFullScreenKeepOther]], NSFullScreenModeAllScreens,
							 [NSNumber numberWithInt:NSTornOffMenuWindowLevel], NSFullScreenModeWindowLevel,
							 nil];
		lockAspectRatio = YES;
		frameAspectRatio = kDisplayAscpectRatioInvalid;
		dragShouldResize = NO;
		firstDisplay = YES;
		playbackFinalized = YES;
		
		threeFingersTap = kThreeFingersTapInit;
		threeFingersPinch = kThreeFingersPinchInit;
		threeFingersPinchDistance = 1;
		fourFingersPinch = kFourFingersPinchInit;
		fourFingersPinchDistance = 1;

		[self setAcceptsTouchEvents:YES];
		[self setWantsRestingTouches:NO];
	}
	return self;
}

-(void) dealloc
{
	[notifCenter removeObserver:self];
	
	[self removeTrackingArea:trackingArea];
	[trackingArea release];
	[fullScreenOptions release];
	[dispLayer release];
	[logo release];
	
	[super dealloc];
}

-(void) setupLayers
{
	// 设定LayerHost，现在只Host一个Layer
	[self setWantsLayer:YES];
	
	// 得到基本的rootLayer
	CALayer *root = [self layer];
	
	// 禁用修改尺寸的action
	[root setDelegate:self];
	[root setDoubleSided:NO];

	// 背景颜色
	CGColorRef col =  CGColorCreateGenericGray(0.0, 1.0);
	[root setBackgroundColor:col];
	CGColorRelease(col);
	
	// 边框颜色
	col = CGColorCreateGenericRGB(0.392, 0.643, 0.812, 0.75);
	[root setBorderColor:col];
	CGColorRelease(col);
	
	// 自动尺寸适应
	[root setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];

	// 图标设定
	logo = [[NSBitmapImageRep alloc] initWithCIImage:
			[CIImage imageWithContentsOfURL:
			 [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"logo.png"]]];
	[root setContentsGravity:kCAGravityCenter];
	[root setContents:(id)[logo CGImage]];
	
	// 默认添加dispLayer
	[root insertSublayer:dispLayer atIndex:0];
	
	// 通知DispLayer
	[dispLayer setBounds:[root bounds]];
	[dispLayer setPosition:CGPointMake(root.bounds.size.width/2, root.bounds.size.height/2)];
}
-(id<CAAction>) actionForLayer:(CALayer*)layer forKey:(NSString*)event { return ((id<CAAction>)[NSNull null]); }

-(void) reorderSubviews
{
	// 将ControlUI放在最上层以防止被覆盖
	[controlUI retain];
	[controlUI removeFromSuperviewWithoutNeedingDisplay];
	[self addSubview:controlUI positioned:NSWindowAbove	relativeTo:nil];
	[controlUI release];
	
	[titlebar retain];
	[titlebar removeFromSuperviewWithoutNeedingDisplay];
	[self addSubview:titlebar positioned:NSWindowAbove relativeTo:nil];
	[titlebar release];
}

-(void) awakeFromNib
{
	[self setupLayers];
	
	[self reorderSubviews];
	
	// 通知dispView接受mplayer的渲染通知
	[playerController setDisplayDelegateForMPlayer:self];
	
	// 默认的全屏的DisplayID
	fullScrnDevID = [[[[playerWindow screen] deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
	
	// 设定可以接受Drag Files
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];

	[VTController setLayer:dispLayer];
	
	[notifCenter addObserver:self selector:@selector(playBackOpened:)
						name:kMPCPlayOpenedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackStarted:)
						name:kMPCPlayStartedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playBackStopped:)
						name:kMPCPlayStoppedNotification object:playerController];
	[notifCenter addObserver:self selector:@selector(playeBackFinalized:)
						name:kMPCPlayFinalizedNotification object:playerController];

	[notifCenter addObserver:self selector:@selector(applicationDidBecomeActive:)
						name:NSApplicationDidBecomeActiveNotification object:NSApp];
	[notifCenter addObserver:self selector:@selector(applicationDidResignActive:)
						name:NSApplicationDidResignActiveNotification object:NSApp];
}

#pragma mark MPCNotification

-(void) playeBackFinalized:(NSNotification*)notif
{
	playbackFinalized = YES;
	// 全部的播放完成，这个时候resetAspectRatio
	[self setExternalAspectRatio:kDisplayAscpectRatioInvalid];
	
	// 播放全部结束，将渲染区放回中心
	[self moveFrameToCenter];
	[self resetFrameScaleRatio];
}

-(void) playBackStopped:(NSNotification*)notif
{
	firstDisplay = YES;
	playbackFinalized = NO;
	[self setPlayerWindowLevel];
	[playerWindow setTitle:kMPCStringMPlayerX];
	[[self layer] setContents:(id)[logo CGImage]];
}

-(void) playBackStarted:(NSNotification*)notif
{
	[self setPlayerWindowLevel];

	if ([[[notif userInfo] objectForKey:kMPCPlayStartedAudioOnlyKey] boolValue]) {
		// if audio only
		[[self layer] setContents:(id)[logo CGImage]];
		[playerWindow setContentSize:[playerWindow contentMinSize]];
		if (![NSApp isHidden]) {
			[playerWindow makeKeyAndOrderFront:nil];
		}
	} else {
		// if has video
		[[self layer] setContents:nil];
	}
}

-(void) playBackOpened:(NSNotification*)notif
{
	NSURL *url = [[notif userInfo] objectForKey:kMPCPlayOpenedURLKey];
	if (url) {		
		if ([url isFileURL]) {
			[playerWindow setTitle:[[url path] lastPathComponent]];
		} else {
			[playerWindow setTitle:[[url absoluteString] lastPathComponent]];
		}
	} else {
		[playerWindow setTitle:kMPCStringMPlayerX];
	}
}

#pragma mark keyboard/mouse
-(BOOL) acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL) acceptsFirstResponder { return YES; }

-(void) mouseMoved:(NSEvent *)theEvent
{
	if (NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], self.bounds)) {
		[controlUI showUp];
		[controlUI updateHintTime];
	}
	[titlebar mouseMoved:theEvent];
}

-(void)mouseDown:(NSEvent *)theEvent
{
	dragMousePos = [NSEvent mouseLocation];
	NSRect winRC = [playerWindow frame];
	
	dragShouldResize = ((NSMaxX(winRC) - dragMousePos.x < 16) && (dragMousePos.y - NSMinY(winRC) < 16))?YES:NO;
	
	// MPLog(@"mouseDown");
}

- (void)mouseDragged:(NSEvent *)event
{
	BOOL ShiftKeyPressed = NO;
	
	// current location of the mouse
	NSPoint posNow = [NSEvent mouseLocation];
	NSPoint delta;
	
	// the position delta from last event
	delta.x = (posNow.x - dragMousePos.x);
	delta.y = (posNow.y - dragMousePos.y);

	dragMousePos = posNow;
	
	switch ([event modifierFlags] & (NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) {
		case NSShiftKeyMask|kSCMDragFullScrFrameModifierFlagMask:
			ShiftKeyPressed = YES;
			
		case kSCMDragFullScrFrameModifierFlagMask:
			if ([self isInFullScreenMode]) {
				// 全屏的时候，移动渲染区域
				CGPoint pt = [dispLayer positionOffsetRatio];
				CGSize sz = dispLayer.bounds.size;
				
				if (ShiftKeyPressed) {
					if (fabsf(delta.x) > fabsf(8 * delta.y)) {
						delta.y = 0;
					} else if (fabsf(8 * delta.x) < fabsf(delta.y)) {
						delta.x = 0;
					} else {
						// if use shift to drag the area, only X or only Y are accepted
						break;
					}
				}

				pt.x += (delta.x / sz.width);
				pt.y += (delta.y / sz.height);

				[dispLayer setPositoinOffsetRatio:pt];
				if ([playerController playerState] == kMPCPausedState) {
					[dispLayer updateCoordinate];
				}
			}
			break;
		//////////////////////////////////////////////////////////////////////////////////////////////////////
		case 0:
			if (![self isInFullScreenMode]) {
				// 非全屏的时候移动窗口

				if (dragShouldResize) {
					NSRect newFrame = [playerWindow frame];
					
					// 当前鼠标坐标与窗口构成的新frame
					newFrame.size.width = posNow.x - newFrame.origin.x;
					newFrame.size.height = newFrame.size.height + newFrame.origin.y - posNow.y;
					newFrame.origin.y = posNow.y;
					
					CGFloat ar;
					
					if (displaying && lockAspectRatio) {
						// there is video displaying
						// 得到新窗口的size
						ar = [dispLayer aspectRatio];
					} else {
						ar = newFrame.size.width / newFrame.size.height;
					}
					newFrame = [self calculateFrameFrom:newFrame 
												  toFit:ar
												   mode:kCalFrameSizeInFit | kCalFrameFixPosUpleft];
					[playerWindow setFrame:newFrame display:YES animate:NO];
					// MPLog(@"%f,%f,%f,%f",newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
					// MPLog(@"should resize");
				} else {
					NSRect winFrm = [playerWindow frame];
					NSScreen *currentScrn = [[self window] screen];
					
					winFrm.origin.x += delta.x;
					winFrm.origin.y += delta.y;
					
					if (currentScrn == [[NSScreen screens] objectAtIndex:0]) {
						// 现在的屏幕是有menubar的话，让窗口不要超过menubar
						NSRect scrnFrm = [currentScrn visibleFrame];
						
						if ((winFrm.origin.y + winFrm.size.height) > (scrnFrm.origin.y + scrnFrm.size.height)) {
							winFrm.origin.y = scrnFrm.origin.y + scrnFrm.size.height - winFrm.size.height;
						}
					}
					
					[playerWindow setFrameOrigin:winFrm.origin];
					// MPLog(@"should move");
				}
			}
			break;
		default:
			break;
	}
}

-(void) mouseUp:(NSEvent *)theEvent
{
	if ([theEvent clickCount] == 2) {
		switch ([theEvent modifierFlags] & (NSShiftKeyMask| NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) {
			case 0:
				[controlUI toggleFullScreen:nil];
				break;
			default:
				break;
		}
	}
	// do not use the playerWindow, since when fullscreen the window holds self is not playerWindow
	// 当鼠标抬起的时候，自动将FR放到rootLayerView上，这样可以让接受键盘鼠标事件
	[[self window] makeFirstResponder:self];
	// MPLog(@"mouseUp");
}

-(void) mouseEntered:(NSEvent *)theEvent
{
	[controlUI showUp];
}

-(void) mouseExited:(NSEvent *)theEvent
{
	if (![self isInFullScreenMode]) {
		// 全屏模式下，不那么积极的
		[controlUI doHide];
	}
}

-(void) keyDown:(NSEvent *)theEvent
{
	if (![shortCutManager processKeyDown:theEvent]) {
		// 如果shortcut manager不处理这个evetn的话，那么就按照默认的流程
		[super keyDown:theEvent];
	}
}

-(void) cancelOperation:(id)sender
{
	if ([self isInFullScreenMode]) {
		// when pressing Escape, exit fullscreen if being fullscreen
		[controlUI toggleFullScreen:nil];
	} else {
		if ([ud boolForKey:kUDKeyCloseWndOnEsc]) {
			[[self window] performClose:nil];
		}
	}
}

-(void)scrollWheel:(NSEvent *)theEvent
{
	float x, y;
	x = [theEvent deltaX];
	y = [theEvent deltaY];
	
	switch ([theEvent modifierFlags] & (NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) {
		case kSCMScaleFrameKeyEquivalentModifierFlagMask:
			if ([self isInFullScreenMode]) {
				// only in full screen mode
				// in Y direction
				CGSize sz;
				sz.height = y / 100.0f;
				sz.width = sz.height;
				[self changeFrameScaleRatioBy:sz];
			}
			break;
		case 0:
			if ((fabsf(x) > fabsf(y*8)) && (![ud boolForKey:kUDKeyDisableHScrollSeek])) {
				// MPLog(@"%f", x);
				switch ([playerController playerState]) {
					case kMPCPausedState:
						if (x < 0) {
							[playerController frameStep];
						}
						break;
					case kMPCPlayingState:
						[controlUI changeTimeBy:-x];
						break;
					default:
						break;
				}
			} else if ((fabsf(x*8) < fabsf(y)) && (![ud boolForKey:kUDKeyDisableVScrollVol])) {
				[controlUI changeVolumeBy:[NSNumber numberWithFloat:y*0.2]];
			}
			break;
		default:
			break;
	}
}

-(void) magnifyWithEvent:(NSEvent *)event
{
	if ([self isInFullScreenMode]) {
		// in full screen
		CGSize sz;
		sz.height = [event magnification] / 2;
		sz.width = sz.height;
		[self changeFrameScaleRatioBy:sz];
	} else {
		[self changeWindowSizeBy:NSMakeSize([event magnification], [event magnification]) animate:NO];
	}
}

-(void) swipeWithEvent:(NSEvent *)event
{
	CGFloat x = [event deltaX];
	CGFloat y = [event deltaY];
	unichar key;
	
	if (x < 0) {
		key = NSRightArrowFunctionKey;
	} else if (x > 0) {
		key = NSLeftArrowFunctionKey;
	} else if (y > 0) {
		key = NSUpArrowFunctionKey;
	} else if (y < 0) {
		key = NSDownArrowFunctionKey;
	} else {
		key = 0;
	}
	
	if (key) {
		[shortCutManager processKeyDown:[NSEvent makeKeyDownEvent:[NSString stringWithCharacters:&key length:1] modifierFlags:0]];
	}
}

-(void) rotateWithEvent:(NSEvent*)event
{
	if ((!lockAspectRatio) || (([NSEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)) {
		// 如果没有锁定，或者锁定的时候按下alt
		float angle = atanf(1 / [dispLayer aspectRatio]);
		
		if ([event modifierFlags] & NSShiftKeyMask) {
			angle += [event rotation] * 3.1415926 / 720;				
		} else {
			angle += [event rotation] * 3.1415926 / 180;
		}
		angle = MIN(0.785/* 45 degree */, MAX(0.17 /* 10 degree */, angle));
		[self setAspectRatio:1/tanf(angle)];
	}
}

#pragma mark multitouch


float DistanceOf(NSPoint p1, NSPoint p2, NSPoint p3)
{
	return fabs(p1.x - p2.x) + fabs(p1.y - p2.y) +
	fabs(p1.x - p3.x) + fabs(p1.y - p3.y) +
	fabs(p2.x - p3.x) + fabs(p2.y - p3.y);
}

float AreaOf(NSPoint p1, NSPoint p2, NSPoint p3, NSPoint p4)
{
	CGFloat top, bottom, left, right;
	top = p1.y;
	bottom = p1.y;
	left = p1.x;
	right = p1.x;
	
	if (left   > p2.x) { left   = p2.x; }
	if (right  < p2.x) { right  = p2.x; }
	if (top    < p2.y) { top    = p2.y; }
	if (bottom > p2.y) { bottom = p2.y; }
	if (left   > p3.x) { left   = p3.x; }
	if (right  < p3.x) { right  = p3.x; }
	if (top    < p3.y) { top    = p3.y; }
	if (bottom > p3.y) { bottom = p3.y; }
	if (left   > p4.x) { left   = p4.x; }
	if (right  < p4.x) { right  = p4.x; }
	if (top    < p4.y) { top    = p4.y; }
	if (bottom > p4.y) { bottom = p4.y; }
	
	return fabs(top - bottom) * fabs(right - left);
}

-(void) touchesBeganWithEvent:(NSEvent*)event
{
	// MPLog(@"BEGAN");
	NSSet *touch = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
	
	switch ([touch count]) {
		case 3:
			if (threeFingersTap == kThreeFingersTapInit) {
				// 如果是三个指头tap，并且现在是OK的状态，那么就ready了
				threeFingersTap = kThreeFingersTapReady;
				// MPLog(@"Three Fingers Tap Ready");
			}
			
			if (threeFingersPinch == kThreeFingersPinchInit) {
				threeFingersPinch = kThreeFingersPinchReady;
				NSArray *touchAr = [touch allObjects];
				threeFingersPinchDistance = DistanceOf([[touchAr objectAtIndex:0] normalizedPosition],
													   [[touchAr objectAtIndex:1] normalizedPosition], 
													   [[touchAr objectAtIndex:2] normalizedPosition]);
				MPLog(@"Init 3f Dist:%f", threeFingersPinchDistance);
			}
			break;
		case 4:
			threeFingersTap = kThreeFingersTapInit;
			threeFingersPinch = kThreeFingersPinchInit;
			
			if (fourFingersPinch == kFourFingersPinchInit) {
				fourFingersPinch = kFourFingersPinchReady;
				NSArray *touchAr = [touch allObjects];
				fourFingersPinchDistance = AreaOf([[touchAr objectAtIndex:0] normalizedPosition],
												  [[touchAr objectAtIndex:1] normalizedPosition],
												  [[touchAr objectAtIndex:2] normalizedPosition],
												  [[touchAr objectAtIndex:3] normalizedPosition]);
				MPLog(@"Init 4f Dist:%f", fourFingersPinchDistance);
			}
			break;
			
		default:
			break;
	}
	[super touchesBeganWithEvent:event];
}

-(void) touchesMovedWithEvent:(NSEvent*)event
{
	// MPLog(@"MOVED");
	// 任何时候当move的时候，就不ready了
	threeFingersTap = kThreeFingersTapInvalid;
	
	if (threeFingersPinch == kThreeFingersPinchReady) {
		NSSet *touch = [event touchesMatchingPhase:NSTouchPhaseMoved|NSTouchPhaseStationary inView:self];
		
		if ([touch count] == 3) {
			NSArray *touchAr = [touch allObjects];
			float dist = DistanceOf([[touchAr objectAtIndex:0] normalizedPosition],
									[[touchAr objectAtIndex:1] normalizedPosition], 
									[[touchAr objectAtIndex:2] normalizedPosition]);
			float thresh = [ud floatForKey:kUDKeyThreeFingersPinchThreshRatio];
			
			MPLog(@"Curr 3f Dist:%f", dist/threeFingersPinchDistance);
			if (((![self isInFullScreenMode]) && (dist > threeFingersPinchDistance * thresh)) ||
				(( [self isInFullScreenMode]) && (dist * thresh < threeFingersPinchDistance))){
				// toggle fullscreen
				threeFingersPinch = kThreeFingersPinchInit;
				[controlUI toggleFullScreen:nil];
			}
		}
	}
	
	if (fourFingersPinch == kFourFingersPinchReady) {
		NSSet *touch = [event touchesMatchingPhase:NSTouchPhaseMoved|NSTouchPhaseStationary inView:self];
		
		if ([touch count] == 4) {
			NSArray *touchAr = [touch allObjects];
			float dist = AreaOf([[touchAr objectAtIndex:0] normalizedPosition],
								[[touchAr objectAtIndex:1] normalizedPosition],
								[[touchAr objectAtIndex:2] normalizedPosition],
								[[touchAr objectAtIndex:3] normalizedPosition]);
			MPLog(@"Curr 4f Dist:%f", dist / fourFingersPinchDistance);
			
			if (dist * [ud floatForKey:kUDKeyFourFingersPinchThreshRatio] < fourFingersPinchDistance) {
				fourFingersPinch = kFourFingersPinchInit;
				[[self window] performClose:self];
			}
		}
	}
	[super touchesMovedWithEvent:event];
}

-(void) touchesEndedWithEvent:(NSEvent*)event
{
	// MPLog(@"ENDED");
	NSSet *touch = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
	
	if ([touch count] == 0) {
		// 当所有指头都离开之后（除了resting）
		if (threeFingersTap == kThreeFingersTapReady) {
			// 如果是ready的话，就toggle play pause
			[controlUI togglePlayPause:nil];
			// MPLog(@"Three Fingers Tap Trigger");
		}
		// 不论是否是ready还是init还是invalid，所有之后离开之后都重置
		threeFingersTap = kThreeFingersTapInit;
		
		threeFingersPinch = kThreeFingersPinchInit;
		fourFingersPinch = kFourFingersPinchInit;
	}
	
	[super touchesEndedWithEvent:event];
}

-(void) touchesCancelledWithEvent:(NSEvent*)event
{
	// MPLog(@"CANCEL");
	threeFingersTap = kThreeFingersTapInit;
	threeFingersPinch = kThreeFingersPinchInit;
	fourFingersPinch = kFourFingersPinchInit;
	
	[super touchesCancelledWithEvent:event];
}

#pragma mark internal
-(void) resetFrameScaleRatio
{
	[dispLayer setScaleRatio:CGSizeMake(1, 1)];
	if ([playerController playerState] == kMPCPausedState) {
		[dispLayer updateCoordinate];
	}
}

-(void) changeFrameScaleRatioBy:(CGSize)rt
{
	CGSize ratio = [dispLayer scaleRatio];
	
	if (fabsf(rt.width) > kScaleFrameRatioStepMax) {
		rt.width = (rt.width > 0)?(kScaleFrameRatioStepMax) : (-kScaleFrameRatioStepMax);
	}
	if (fabsf(rt.height) > kScaleFrameRatioStepMax) {
		rt.height = (rt.height > 0)?(kScaleFrameRatioStepMax) : (-kScaleFrameRatioStepMax);
	}

	ratio.width  += rt.width;
	ratio.height += rt.height;
	
	if (ratio.width < kScaleFrameRatioMinLimit) {
		ratio.width = kScaleFrameRatioMinLimit;
	}
	if (ratio.height < kScaleFrameRatioMinLimit) {
		ratio.height = kScaleFrameRatioMinLimit;
	}
	
	[dispLayer setScaleRatio:ratio];
	if ([playerController playerState] == kMPCPausedState) {
		[dispLayer updateCoordinate];
	}
}

-(void) moveFrameToCenter
{
	[dispLayer setPositoinOffsetRatio:CGPointZero];
	if ([playerController playerState] == kMPCPausedState) {
		[dispLayer updateCoordinate];
	}
}

-(NSRect) calculateFrameFrom:(NSRect)orgFrame toFit:(CGFloat)ar mode:(NSUInteger)modeMask
{
	NSRect contentRect = [playerWindow contentRectForFrameRect:orgFrame];
	NSSize contentMinSize = [playerWindow contentMinSize];

	NSRect screenRc = [[playerWindow screen] visibleFrame];
	NSSize screenContentSize = [playerWindow contentRectForFrameRect:screenRc].size;

	if ((orgFrame.size.width <= 0) || (orgFrame.size.height <= 0)) {
		// 非法尺寸，就用窗口当前的size
		orgFrame = [playerWindow contentRectForFrameRect:[playerWindow frame]];
	} else {
		orgFrame = contentRect;
	} // 从此开始，orgFrame被用来做新的content的rect，节省stack

	if (!IsDisplayLayerAspectValid(ar)) {
		// 如果没有目标AR，那么就用影片原始的AR
		// 注意：不是影片现在的AR，调用该API的时候，影片应该就已经处在当前AR中
		ar = [dispLayer originalAspectRatio];
	}
	if (!IsDisplayLayerAspectValid(ar)) {
		ar = orgFrame.size.width / orgFrame.size.height;
	}

	// 本来应该检查ar是否>0的，但是最差会用当前orgFrame的ar，所以不用检查

	// 计算变形后的contentSize
	if ((modeMask & kCalFrameSizeMask) == kCalFrameSizeInFit) {
		// 按照包含关系计算
		if (orgFrame.size.width > (orgFrame.size.height * ar)) {
			// 要变成竖图
			orgFrame.size.width = orgFrame.size.height * ar;
		} else {
			// 要变成横图
			orgFrame.size.height = orgFrame.size.width / ar;
		}
	} else {
		// 按照对角线计算
		float diagLen = hypotf(orgFrame.size.width, orgFrame.size.height);
		float angle = atanf(1/ar);

		orgFrame.size.width  = diagLen * cosf(angle);
		orgFrame.size.height = diagLen * sinf(angle);
	}
	
	// 最大size需要两个尺寸都保证，而最小size只要保证一个尺寸
	if (screenContentSize.width > (screenContentSize.height * ar)) {
		// 要变成竖图，高度先越界，之后是宽度
		if (orgFrame.size.height > screenContentSize.height) {
			orgFrame.size.height = screenContentSize.height;
			orgFrame.size.width  = orgFrame.size.height * ar;
		}
	} else {
		// 要变成横图，宽度先越界，之后是高度
		if (orgFrame.size.width > screenContentSize.width) {
			orgFrame.size.width  = screenContentSize.width;
			orgFrame.size.height = orgFrame.size.width / ar;
		}			
	}

	if (contentMinSize.width > (contentMinSize.height * ar)) {
		// 要变成竖图，宽度先越界，之后是高度
		if (orgFrame.size.height < contentMinSize.height) {
			orgFrame.size.height = contentMinSize.height;
			orgFrame.size.width  = orgFrame.size.height * ar;
		}
	} else {
		// 要变成横图，高度先越界，之后是宽度
		if (orgFrame.size.width < contentMinSize.width) {
			// 优先照顾宽度
			orgFrame.size.width  = contentMinSize.width;
			orgFrame.size.height = orgFrame.size.width / ar;
		}
	}
	// 此处得到了需要的contentSize，放在orgFrame.size中
	
	// 计算新的origin
	if ((modeMask & kCalFrameFixPosMask) == kCalFrameFixPosUpleft) {
		// 左上角对齐
		orgFrame.origin.y = contentRect.origin.y + contentRect.size.height - orgFrame.size.height;
	} else {
		// 中心对齐
		orgFrame.origin.x += (contentRect.size.width  - orgFrame.size.width)  / 2;
		orgFrame.origin.y += (contentRect.size.height - orgFrame.size.height) / 2;
		orgFrame.origin.x = MAX(screenRc.origin.x, MIN(orgFrame.origin.x, screenRc.origin.x + screenRc.size.width  - orgFrame.size.width));
		orgFrame.origin.y = MAX(screenRc.origin.y, MIN(orgFrame.origin.y, screenRc.origin.y + screenRc.size.height - orgFrame.size.height));		
	}
	// 从此开始，orgFrame代表了最新的content的size和window的origin
	
	// Apple 的Doc说，这里的ContentRect用的是Screen Coordinate
	// 需要验证
	orgFrame = [playerWindow frameRectForContentRect:orgFrame];
	
	return orgFrame;
}

-(void) setExternalAspectRatio:(CGFloat)ar
{
	if (IsDisplayLayerAspectValid(ar)) {
		// 如果是有效值，那么说明是外部的AR，需要根据外部AR算出画面的AR
		NSInteger lbMode = [ud integerForKey:kUDKeyLetterBoxMode];
		float margin = [ud floatForKey:kUDKeyLetterBoxHeight];
		
		switch (lbMode) {
			case kPMLetterBoxModeBoth:
				frameAspectRatio = ar * (1 + 2 * margin);
				break;
			case kPMLetterBoxModeBottomOnly:
			case kPMLetterBoxModeTopOnly:
				frameAspectRatio = ar * (1 + margin);
				break;
			default:
				frameAspectRatio = ar;
				break;
		}
	} else {
		frameAspectRatio = kDisplayAscpectRatioInvalid;
	}
	[dispLayer setExternalAspectRatio:ar];
}

-(void) setLockAspectRatio:(BOOL) lock
{
	if (lock != lockAspectRatio) {
		lockAspectRatio = lock;
		
		if (lockAspectRatio) {
			// 如果锁定 aspect ratio的话，那么就按照现在的window的
			// 如果是全屏的话，[self bounds]就变成了全屏的尺寸，需要修正
			NSSize sz = [self bounds].size;
			CGFloat ar = [dispLayer aspectRatio];
			
			sz.width = sz.height * ar;
			
			if (IsDisplayLayerAspectValid(ar)) {
				[playerWindow setContentAspectRatio:sz];
				[self setExternalAspectRatio:ar];
			}
		} else {
			[playerWindow setContentResizeIncrements:NSMakeSize(1.0, 1.0)];
		}
	}
}

-(void) resetAspectRatio
{
	if (displaying) {
		lockAspectRatio = YES;
		[self setAspectRatio:kDisplayAscpectRatioInvalid];
	}
}

-(void) setAspectRatio:(CGFloat) ar
{
	// 如果ar==kDisplayAscpectRatioInvalid，那说明要reset
	// calculateFrameFrom函数会根据originalAspectRatio来算
	if (displaying) {
		
		NSRect newFrame;

		if (IsDisplayLayerAspectValid(ar)) {
			// 有效说明不是重置
			// 如果现在有letterbox的话，那就会有问题
			// 需要补偿
			NSInteger lbMode = [ud integerForKey:kUDKeyLetterBoxMode];
			float margin = [ud floatForKey:kUDKeyLetterBoxHeight];
			
			switch (lbMode) {
				case kPMLetterBoxModeBoth:
					ar /= (1 + 2 * margin);
					break;
				case kPMLetterBoxModeBottomOnly:
				case kPMLetterBoxModeTopOnly:
					ar /= (1 + margin);
					break;
				default:
					break;
			}
		}
		
		if ([self isInFullScreenMode]) {
			[self setExternalAspectRatio:ar];
			[self updateFrameForFullScreen];
			newFrame = rcBeforeFullScrn;
		} else {
			newFrame = [self calculateFrameFrom:[[self window] frame] toFit:ar mode:kCalFrameFixPosCenter | kCalFrameSizeDiag];
			[playerWindow setFrame:newFrame display:YES animate:YES];
			[self setExternalAspectRatio:ar];
		}
		
		if (lockAspectRatio) {
			//如果是锁定AR的，那么需要重新设定比例
			[playerWindow setContentAspectRatio:[playerWindow contentRectForFrameRect:newFrame].size];

			if ([playerController playerState] == kMPCPausedState) {
				[dispLayer updateCoordinate];
			}
		} else {
			// 如果没有锁定AR，那么dispLayer的AR会随着window变，所以目前不需要做什么事情
		}
	}
}

-(CIImage*) snapshot
{
	return [dispLayer snapshot];
}

-(CGFloat) aspectRatio
{
	return [dispLayer aspectRatio];
}

-(void) changeWindowSizeBy:(NSSize)delta animate:(BOOL)animate
{
	if (![self isInFullScreenMode]) {
		NSRect frm = [playerWindow frame];
		
		// 新的目标size
		delta.width  *= frm.size.width;
		delta.height *= frm.size.height;

		// 目标Rect
		frm.origin.x -= (delta.width ) / 2;
		frm.origin.y -= (delta.height) / 2;
		frm.size.width  += delta.width;
		frm.size.height += delta.height;
		
		frm = [self calculateFrameFrom:frm toFit:[dispLayer aspectRatio] mode:kCalFrameFixPosCenter | kCalFrameSizeDiag];
		
		[playerWindow setFrame:frm display:YES animate:animate];
	}
}

-(BOOL) toggleFullScreen
{
	// ！注意：这里的显示状态和mplayer的播放状态时不一样的，比如，mplayer在MP3的时候，播放状态为YES，显示状态为NO
	if ([self isInFullScreenMode]) {
		// 无论否在显示都可以退出全屏
		
		// 必须砸退出全屏的时候再设定
		// 在退出全屏之前，这个view并不属于window，设定contentsize不起作用
		if (shouldResize) {
			shouldResize = NO;
			// 得到目标frame
			rcBeforeFullScrn = [self calculateFrameFrom:rcBeforeFullScrn
												  toFit:[dispLayer aspectRatio]
												   mode:kCalFrameSizeDiag | kCalFrameFixPosCenter];
			
			[dispLayer forceAdjustToFitBounds:YES];
			if (displaying) {
				// 先将playerWindow放到全屏窗口的背后
				[playerWindow orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
				// 退出全屏
				[self exitFullScreenModeWithOptions:fullScreenOptions];
				// 取消全屏时的各种设置
				[dispLayer enablePositionOffset:NO];
				[dispLayer enableScale:NO];
				// 如果选定了CloseWindowWhenStopped的话
				// 播放完毕退出全屏会在这里显示窗口，然后退出到ControlUIView里面在关闭窗口
				// 出现窗口闪动，因此只有当在diplaying的时候才主动显示窗口
				[playerWindow makeKeyAndOrderFront:self];
			} else {
				// 如果不是displaying，那么根本不会显示window
				// 退出全屏
				[self exitFullScreenModeWithOptions:fullScreenOptions];
				[dispLayer enablePositionOffset:NO];
				[dispLayer enableScale:NO];
			}

			// 如果没有displaying，那么就不需要动画了
			[playerWindow setFrame:rcBeforeFullScrn display:YES animate:displaying];
			if ([playerController playerState] == kMPCPausedState) {
				[dispLayer setNeedsDisplay];
			}
			[dispLayer forceAdjustToFitBounds:NO];
			
			// 当进入全屏的时候，回强制锁定ar
			// 当出了全屏，更新了window的size之后，在这里需要再一次设定window的ar
			[playerWindow setContentAspectRatio:[playerWindow contentRectForFrameRect:rcBeforeFullScrn].size];
		} else {
			[self exitFullScreenModeWithOptions:fullScreenOptions];

			// 推出全屏，重新根据现在的尺寸比例渲染图像
			[dispLayer enablePositionOffset:NO];
			[dispLayer enableScale:NO];
			if ([playerController playerState] == kMPCPausedState) {
				[dispLayer updateCoordinate];
			}
			
			if (displaying) {
				// 如果选定了CloseWindowWhenStopped的话
				// 播放完毕退出全屏会在这里显示窗口，然后退出到ControlUIView里面在关闭窗口
				// 出现窗口闪动，因此只有当在diplaying的时候才主动显示窗口
				[playerWindow makeKeyAndOrderFront:self];
			}
		}
		[playerWindow makeFirstResponder:self];

		// 必须要在退出全屏之后才能设定window level
		[self setPlayerWindowLevel];
	} else if (displaying) {
		// 应该进入全屏
		// 只有在显示图像的时候才能进入全屏

		// 强制Lock Aspect Ratio
		[self setLockAspectRatio:YES];

		BOOL keepOtherSrn = [ud boolForKey:kUDKeyFullScreenKeepOther];
		// 得到window目前所在的screen
		NSScreen *chosenScreen = [playerWindow screen];
		// Presentation Options
		NSApplicationPresentationOptions opts;
		
		if (chosenScreen == [[NSScreen screens] objectAtIndex:0] || (!keepOtherSrn)) {
			// if the main screen
			// there is no reason to always hide Dock, when MPX displayed in the secondary screen
			// so only do it in main screen
			if ([ud boolForKey:kUDKeyAlwaysHideDockInFullScrn]) {
				opts = NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar;
			} else {
				opts = NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar;
			}
		} else {
			// in secondary screens
			opts = [NSApp presentationOptions];
		}

		[fullScreenOptions setObject:[NSNumber numberWithInt:opts] forKey:NSFullScreenModeApplicationPresentationOptions];
		// whether grab all the screens
		[fullScreenOptions setObject:[NSNumber numberWithBool:!keepOtherSrn] forKey:NSFullScreenModeAllScreens];

		shouldResize = YES;
		// 先记下全屏前窗口的方位
		rcBeforeFullScrn = [playerWindow frame];
		// 动画进入全屏
		
		[dispLayer forceAdjustToFitBounds:YES];
		[playerWindow setFrame:[chosenScreen frame] display:YES animate:YES];
		if ([playerController playerState] == kMPCPausedState) {
			[dispLayer setNeedsDisplay];
		}
		// 进入全屏
		[self enterFullScreenMode:chosenScreen withOptions:fullScreenOptions];
		// 推出全屏，重新根据现在的尺寸比例渲染图像
		[dispLayer enablePositionOffset:YES];
		[dispLayer enableScale:YES];
		// 暂停的时候能够正确显示
		if ([playerController playerState] == kMPCPausedState) {
			[dispLayer updateCoordinate];
		}
		[dispLayer forceAdjustToFitBounds:NO];


		[playerWindow orderOut:self];

		[[self window] setCollectionBehavior:NSWindowCollectionBehaviorManaged];
		
		fullScrnDevID = [[[chosenScreen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];

		// 得到screen的分辨率，并和播放中的图像进行比较
		// 知道是横图还是竖图
		NSSize sz = [self bounds].size;
		
		[controlUI setFillScreenMode:(((sz.height * [dispLayer aspectRatio]) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
							   state:([dispLayer fillScreen])?NSOnState:NSOffState];
	} else {
		// 强制渲染一次
		if ([playerController playerState] == kMPCPausedState) {
			[dispLayer updateCoordinate];
		}
		return NO;
	}
	return YES;
}

-(BOOL) toggleFillScreen
{
	[dispLayer setFillScreen: ![dispLayer fillScreen]];
	// 暂停的时候能够正确显示
	if ([playerController playerState] == kMPCPausedState) {
		[dispLayer updateCoordinate];
	}
	return [dispLayer fillScreen];
}

-(void) setPlayerWindowLevel
{
	// in window mode
	int onTopMode = [ud integerForKey:kUDKeyOnTopMode];
	BOOL fullscr = [self isInFullScreenMode];
	
	if ((((onTopMode == kOnTopModeAlways)||((onTopMode == kOnTopModePlaying) && (playerController.playerState == kMPCPlayingState)))&&(!fullscr)) ||
		([NSApp isActive] && fullscr)) {
		[[self window] setLevel: NSTornOffMenuWindowLevel];
	} else {
		[[self window] setLevel: NSNormalWindowLevel];
	}
}

-(BOOL) mirror
{
	return [dispLayer mirror];
}

-(BOOL) flip
{
	return [dispLayer flip];
}

-(void) setMirror:(BOOL)m
{
	[dispLayer setMirror:m];
	if ([playerController playerState] == kMPCPausedState) {
		[dispLayer updateCoordinate];
	}
}

-(void) setFlip:(BOOL)f
{
	[dispLayer setFlip:f];
	if ([playerController playerState] == kMPCPausedState) {
		[dispLayer updateCoordinate];
	}
}

-(void) zoomToSize:(float)ratio
{
	if (displaying) {		
		NSSize orgSize = [dispLayer displaySize];
		CGFloat ar = [dispLayer aspectRatio];

		orgSize.width  *= ratio;
		orgSize.height *= ratio;

		if ([self isInFullScreenMode]) {
			CGSize curSize = [dispLayer bounds].size;
			CGSize sr = [dispLayer scaleRatio];
			
			orgSize.width = MIN(orgSize.width, orgSize.height * ar);
			
			CGFloat r = MAX(orgSize.width/curSize.width, orgSize.height/curSize.height);
			sr.width *= r;
			sr.height *= r;
			
			[dispLayer setScaleRatio:sr];
			if ([playerController playerState] == kMPCPausedState) {
				[dispLayer updateCoordinate];
			}
		} else {
			// not in full screen
			NSRect rc = [playerWindow contentRectForFrameRect:[playerWindow frame]];
			rc.origin.x -= (orgSize.width  - rc.size.width)  / 2;
			rc.origin.y -= (orgSize.height - rc.size.height) / 2;
			rc.size = orgSize;
			rc = [self calculateFrameFrom:[playerWindow frameRectForContentRect:rc] toFit:ar mode:kCalFrameFixPosCenter | kCalFrameSizeDiag];
			[playerWindow setFrame:rc display:YES animate:YES];
		}
	}
}

-(void) updateFrameForFullScreen
{
	// 这个函数必须在全屏的时候调用
	NSRect newFrame;
	
	shouldResize = YES;
	
	newFrame = [self calculateFrameFrom:rcBeforeFullScrn toFit:[dispLayer aspectRatio] mode:kCalFrameFixPosCenter | kCalFrameSizeDiag];
	
	rcBeforeFullScrn = newFrame;
	
	// 判断fillscreen的状态，这个必须在setExternalAspectRatio之后进行
	newFrame.size = [self bounds].size;
	[controlUI setFillScreenMode:(((newFrame.size.height * [dispLayer aspectRatio]) >= newFrame.size.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
						   state:([dispLayer fillScreen])?NSOnState:NSOffState];	
}

-(void) prepareForStartingDisplay
{
	if (firstDisplay) {
		// 如果是第一次显示
		// 但是此时并不知道目前的 externalAspectRatio
		// 如果是invalid，那么说明需要保持自己的状态，如果有value，说明需要一直保持这个aspect
		// 直到reset或者finalized
		firstDisplay = NO;
		
		lockAspectRatio = YES;
		
		[controlUI displayStarted];
		
		if ([self isInFullScreenMode]) {
			[self updateFrameForFullScreen];
		} else {
			if ((![ud boolForKey:kUDKeyDontResizeWhenContinuousPlay]) || playbackFinalized) {
				// 如果强制resize，或者 不是连续播放，就resize到原始尺寸
				[self zoomToSize:1];
			} else {
				// 这里需要调整AR
				// 如果设定了外部强制AR，那么就根据这个AR设定窗口
				// 如果没有设定AR，就将AR归为原始AR
				[self setAspectRatio:[dispLayer externalAspectRatio]];
			}
			
			[playerWindow setContentAspectRatio:[self bounds].size];
			
			if ([ud boolForKey:kUDKeyStartByFullScreen]) {
				[controlUI toggleFullScreen:nil];
			} else {
				if (![NSApp isHidden]) {
					[playerWindow makeKeyAndOrderFront:self];
				}
			}
		}
	} else {
		// 播放过程中出现再次开启display说明
		// 1. letterbox之类会改变AR的用户时间
		// 2. 或者 自发的改变
		[controlUI displayStarted];
		
		CGFloat ar = kDisplayAscpectRatioInvalid;
		
		if (IsDisplayLayerAspectValid(frameAspectRatio)) {
			NSInteger lbMode = [ud integerForKey:kUDKeyLetterBoxMode];
			float margin = [ud floatForKey:kUDKeyLetterBoxHeight];
			
			switch (lbMode) {
				case kPMLetterBoxModeBoth:
					ar = frameAspectRatio / (1 + 2 * margin);
					break;
				case kPMLetterBoxModeBottomOnly:
				case kPMLetterBoxModeTopOnly:
					ar = frameAspectRatio / (1 + margin);
					break;
				default:
					ar = frameAspectRatio;
					break;
			}
		}
		
		if ([self isInFullScreenMode]) {
			[self updateFrameForFullScreen];
			
			if (IsDisplayLayerAspectValid(ar)) {
				
				if ([ud boolForKey:kUDKeyLBAutoHeightInFullScrn]) {
					// 这里是为了对应[自动高度][横图]的AR
					// 如果是竖图的话，不会设定letterbox，但是也不会再次关闭打开display，所以这个暂时是安全的
					NSSize sz = [self bounds].size;
					[dispLayer setExternalAspectRatio:sz.width/sz.height];
					MPLog(@"prepare AR: %f", sz.width/sz.height);
				} else {
					// 这里不需要用[self setExternalAspectRatio]
					// 那个函数里面会根据ar再次设定frameAspectRatio，无用功
					[dispLayer setExternalAspectRatio:ar];
				}
			}
			if ([playerController playerState] == kMPCPausedState) {
				[dispLayer updateCoordinate];
			}
		} else {
			NSRect frm = [self calculateFrameFrom:[playerWindow frame]
											toFit:IsDisplayLayerAspectValid(ar)?(ar):[dispLayer originalAspectRatio]
											 mode:kCalFrameFixPosCenter | kCalFrameSizeDiag];
			[playerWindow setFrame:frm display:YES animate:YES];
			if (IsDisplayLayerAspectValid([dispLayer externalAspectRatio])) {
				// 如果externalAspectRaio有设定值，说明是强制设定
				// 那么就更新extAR
				// 如果extAR是无效的，说明要尊重本来的AR，那什么都不用做
				[self setExternalAspectRatio:ar];
			}
		}
	}
}

#pragma mark drag/drop
///////////////////////////////////for dragging/////////////////////////////////////////
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] && (sourceDragMask & NSDragOperationCopy)) {
		[[self layer] setBorderWidth:6.0];
		return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	[[self layer] setBorderWidth:0.0];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	
	if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		if (sourceDragMask & NSDragOperationCopy) {
			[[self layer] setBorderWidth:0.0];
			[playerController loadFiles:[pboard propertyListForType:NSFilenamesPboardType] fromLocal:YES];
		}
	}
	return YES;
}

#pragma mark coreController delegate
///////////////////////////////////!!!!!!!!!!!!!!!!这三个方法是调用在工作线程上的，如果要操作界面，那么要小心!!!!!!!!!!!!!!!!!!!!!!!!!/////////////////////////////////////////
-(int)  coreController:(id)sender startWithFormat:(DisplayFormat)df buffer:(char**)data total:(NSUInteger)num
{
	if ([dispLayer startWithFormat:df buffer:data total:num] == 0) {
		
		displaying = YES;

		[self performSelectorOnMainThread:@selector(prepareForStartingDisplay) withObject:nil waitUntilDone:YES];

		return 0;
	}
	return 1;
}

-(void) coreController:(id)sender draw:(NSUInteger)frameNum
{
	[dispLayer draw:frameNum];
}

-(void) coreControllerStop:(id)sender
{
	[dispLayer stop];

	displaying = NO;
	[controlUI displayStopped];
	[playerWindow setContentResizeIncrements:NSMakeSize(1.0, 1.0)];
}

#pragma mark Application notification
-(void) applicationDidBecomeActive:(NSNotification*)notif
{
	[self setPlayerWindowLevel];
}

-(void) applicationDidResignActive:(NSNotification*)notif
{
	[self setPlayerWindowLevel];
}

#pragma mark Window Delegate
-(void) windowWillClose:(NSNotification *)notification
{
	[[notification object] orderOut:nil];
	
	if ([ud boolForKey:kUDKeyQuitOnClose]) {
		[NSApp terminate:nil];
	} else {
		[playerController stop];
	}
}

-(BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
	return (displaying && (![window isZoomed]));
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
	if (window == playerWindow) {		
		newFrame = [self calculateFrameFrom:[[window screen] visibleFrame]
									  toFit:[dispLayer aspectRatio]
									   mode:kCalFrameSizeDiag | kCalFrameFixPosCenter];
	}
	return newFrame;
}

-(void) windowDidResize:(NSNotification *)notification
{
	if (!lockAspectRatio) {
		// 如果没有锁住aspect ratio
		NSSize sz = [self bounds].size;
		[self setExternalAspectRatio:(sz.width/sz.height)];
		if ([playerController playerState] == kMPCPausedState) {
			[dispLayer updateCoordinate];
		}
	}
}

@end
