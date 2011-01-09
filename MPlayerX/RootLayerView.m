/*
 * MPlayerX - RootLayerView.m
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

@interface RootLayerView (RootLayerViewInternal)
-(NSSize) calculateContentSize:(NSSize)refSize;
-(NSPoint) calculatePlayerWindowPosition:(NSSize)winSize;
-(void) adjustWindowCoordinateAndAspectRatio:(NSSize) sizeVal;
-(NSSize) adjustWindowCoordinateTo:(NSSize)sizeVal;
-(void) setupLayers;
-(void) reorderSubviews;

-(void) playBackOpened:(NSNotification*)notif;
-(void) playBackStarted:(NSNotification*)notif;
-(void) playBackStopped:(NSNotification*)notif;

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
					   nil]];
}

#pragma mark Init/Dealloc
-(id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
		trackingArea = [[NSTrackingArea alloc] initWithRect:NSInsetRect([self frame], 1, 1) 
													options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingAssumeInside
													  owner:self
												   userInfo:nil];
		[self addTrackingArea:trackingArea];
		shouldResize = NO;
		dispLayer = [[DisplayLayer alloc] init];
		displaying = NO;
		fullScreenOptions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
							 [NSNumber numberWithInt:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar], NSFullScreenModeApplicationPresentationOptions,
							 [NSNumber numberWithBool:![ud boolForKey:kUDKeyFullScreenKeepOther]], NSFullScreenModeAllScreens,
							 [NSNumber numberWithInt:NSTornOffMenuWindowLevel], NSFullScreenModeWindowLevel,
							 nil];
		lockAspectRatio = YES;
		dragShouldResize = NO;
		firstDisplay = YES;
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
	
	col = CGColorCreateGenericRGB(0.392, 0.643, 0.812, 0.75);
	[root setBorderColor:col];
	CGColorRelease(col);
	
	// 自动尺寸适应
	[root setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];

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

	[notifCenter addObserver:self selector:@selector(applicationDidBecomeActive:)
						name:NSApplicationDidBecomeActiveNotification object:NSApp];
	[notifCenter addObserver:self selector:@selector(applicationDidResignActive:)
						name:NSApplicationDidResignActiveNotification object:NSApp];
}

-(void) closePlayerWindow
{
	// 这里不能用close方法，因为如果用close的话会激发wiindowWillClose方法
	[playerWindow orderOut:self];
}

-(void) playBackStopped:(NSNotification*)notif
{
	firstDisplay = YES;
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
		[playerWindow makeKeyAndOrderFront:nil];
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
	
	switch ([event modifierFlags] & (NSShiftKeyMask| NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) {
		case kSCMDragAudioBalanceModifierFlagMask:
			// 这个也基本不能工作
			[controlUI changeAudioBalanceBy:[NSNumber numberWithFloat:([event deltaX] * 2) / self.bounds.size.width]];
			break;
		case NSShiftKeyMask:
			ShiftKeyPressed = YES;
		case 0:
			{
				NSPoint posNow = [NSEvent mouseLocation];
				NSPoint delta;
				delta.x = (posNow.x - dragMousePos.x);
				delta.y = (posNow.y - dragMousePos.y);
				dragMousePos = posNow;

				if (![self isInFullScreenMode]) {
					// 非全屏的时候移动窗口

					if (dragShouldResize) {
						NSRect winRC = [playerWindow frame];
						NSRect newFrame = NSMakeRect(winRC.origin.x,
													 posNow.y, 
													 posNow.x-winRC.origin.x,
													 winRC.size.height + winRC.origin.y - posNow.y);
						
						winRC.size = [playerWindow contentRectForFrameRect:newFrame].size;
						
						if (displaying && lockAspectRatio) {
							// there is video displaying
							winRC.size = [self calculateContentSize:winRC.size];
						} else {
							NSSize minSize = [playerWindow contentMinSize];
							
							winRC.size.width = MAX(winRC.size.width, minSize.width);
							winRC.size.height= MAX(winRC.size.height, minSize.height);
						}
						
						winRC.origin.y -= (winRC.size.height - [[playerWindow contentView] bounds].size.height);
						
						[playerWindow setFrame:[playerWindow frameRectForContentRect:winRC] display:YES];
						// MPLog(@"should resize");
					} else {
						NSPoint winPos = [playerWindow frame].origin;
						winPos.x += delta.x;
						winPos.y += delta.y;
						[playerWindow setFrameOrigin:winPos];
						// MPLog(@"should move");
					}
				} else {
					// 全屏的时候，移动渲染区域
					CGPoint pt = [dispLayer positionOffsetRatio];
					CGSize sz = dispLayer.bounds.size;
					
					delta.x /= sz.width;
					delta.y /= sz.height;
					
					if (ShiftKeyPressed) {
						if (fabsf(delta.x) > fabsf(2 * delta.y)) {
							delta.y = 0;
						} else if (fabsf(2 * delta.x) < fabsf(delta.y)) {
							delta.x = 0;
						} else {
							// if use shift to drag the area, only X or only Y are accepted
							break;
						}
					}
					
					pt.x += delta.x;
					pt.y += delta.y;

					[dispLayer setPositoinOffsetRatio:pt];
					[dispLayer setNeedsDisplay];
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
			case kSCMDragAudioBalanceModifierFlagMask:
				[controlUI changeAudioBalanceBy:nil];
				break;
			case 0:
				[controlUI performKeyEquivalent:[NSEvent makeKeyDownEvent:kSCMFullScrnKeyEquivalent modifierFlags:kSCMFullscreenKeyEquivalentModifierFlagMask]];
				break;
			default:
				break;
		}
	}
	// do not use the playerWindow, since when fullscreen the window holds self is not playerWindow
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
	}
}

-(void)scrollWheel:(NSEvent *)theEvent
{
	float x, y;
	x = [theEvent deltaX];
	y = [theEvent deltaY];
	
	if (fabsf(x) > fabsf(y*2)) {
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
	} else if (fabsf(x*2) < fabsf(y)) {
		[controlUI changeVolumeBy:[NSNumber numberWithFloat:y*0.2]];
	}
}

-(void) moveFrameToCenter
{
	[dispLayer setPositoinOffsetRatio:CGPointMake(0, 0)];
	[dispLayer setNeedsDisplay];
}

-(void) setLockAspectRatio:(BOOL) lock
{
	if (lock != lockAspectRatio) {
		lockAspectRatio = lock;
		
		if (lockAspectRatio) {
			// 如果锁定 aspect ratio的话，那么就按照现在的window的
			NSSize sz = [self bounds].size;
			
			[playerWindow setContentAspectRatio:sz];
			[dispLayer setExternalAspectRatio:(sz.width/sz.height)];
		} else {
			[playerWindow setContentResizeIncrements:NSMakeSize(1.0, 1.0)];
		}
	}
}

-(void) resetAspectRatio
{
	// 如果是全屏，playerWindow是否还拥有rootLayerView不知道
	// 但是全屏的时候并不会立即调整窗口的大小，而是会等推出全屏的时候再调整
	// 如果不是全屏，那么根据现在的size得到最合适的size
	[self adjustWindowCoordinateAndAspectRatio:[[playerWindow contentView] bounds].size];
}

-(void) magnifyWithEvent:(NSEvent *)event
{
	[self changeWindowSizeBy:NSMakeSize([event magnification], [event magnification]) animate:NO];
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
		// only works in non-fullscreen mode
		NSSize sz;
		
		sz = [[playerWindow contentView] bounds].size;

		sz.width  += delta.width  * sz.width;
		sz.height += delta.height * sz.height;
		
		sz = [self calculateContentSize:sz];
		
		NSPoint pos = [self calculatePlayerWindowPosition:sz];
		
		NSRect rc = NSMakeRect(pos.x, pos.y, sz.width, sz.height);
		rc = [playerWindow frameRectForContentRect:rc];

		[playerWindow setFrame:rc display:YES animate:animate];		
	}
}

-(BOOL) toggleFullScreen
{
	// ！注意：这里的显示状态和mplayer的播放状态时不一样的，比如，mplayer在MP3的时候，播放状态为YES，显示状态为NO
	if ([self isInFullScreenMode]) {
		// 无论否在显示都可以退出全屏

		[self exitFullScreenModeWithOptions:fullScreenOptions];
		
		// 必须砸退出全屏的时候再设定
		// 在退出全屏之前，这个view并不属于window，设定contentsize不起作用
		if (shouldResize) {
			shouldResize = NO;
			
			NSSize sz = [self adjustWindowCoordinateTo:[[playerWindow contentView] bounds].size];

			[playerWindow setContentAspectRatio:sz];			
		}
		// 推出全屏，重新根据现在的尺寸比例渲染图像
		[dispLayer adujustToFitBounds];
		[dispLayer setPositionOffset:NO];
		
		[playerWindow makeKeyAndOrderFront:self];
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

		[self enterFullScreenMode:chosenScreen withOptions:fullScreenOptions];

		// 推出全屏，重新根据现在的尺寸比例渲染图像
		[dispLayer adujustToFitBounds];
		[dispLayer setPositionOffset:YES];

		[playerWindow orderOut:self];

		fullScrnDevID = [[[chosenScreen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];

		// 得到screen的分辨率，并和播放中的图像进行比较
		// 知道是横图还是竖图
		NSSize sz = [chosenScreen frame].size;
		
		[controlUI setFillScreenMode:(((sz.height * [dispLayer aspectRatio]) >= sz.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
							   state:([dispLayer fillScreen])?NSOnState:NSOffState];
	} else {
		[dispLayer adujustToFitBounds];
		return NO;
	}
	// 暂停的时候能够正确显示
	[dispLayer setNeedsDisplay];
	return YES;
}

-(BOOL) toggleFillScreen
{
	[dispLayer setFillScreen: ![dispLayer fillScreen]];
	// 暂停的时候能够正确显示
	[dispLayer setNeedsDisplay];
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

-(void) prepareForStartingDisplay
{
	if (firstDisplay) {
		firstDisplay = NO;
		
		[VTController resetFilters:self];
		
		[self adjustWindowCoordinateAndAspectRatio:NSMakeSize(-1, -1)];
		
		[controlUI displayStarted];
		
		if ([ud boolForKey:kUDKeyStartByFullScreen] && (![self isInFullScreenMode])) {
			[controlUI performKeyEquivalent:[NSEvent makeKeyDownEvent:kSCMFullScrnKeyEquivalent modifierFlags:kSCMFullscreenKeyEquivalentModifierFlagMask]];
		}
	} else {
		[controlUI displayStarted];
		
		if ([self isInFullScreenMode]) {
			shouldResize = YES;
		} else {
			[self adjustWindowCoordinateTo:[[playerWindow contentView] bounds].size];
		}
	}
}

-(void) adjustWindowCoordinateAndAspectRatio:(NSSize) sizeVal
{
	// 调用该函数会使DispLayer锁定并且窗口的比例也会锁定
	// 因此在这里设定lock是安全的
	lockAspectRatio = YES;
	// 虽然如果是全屏的话，是无法调用设定窗口的代码，但是全屏的时候无法改变窗口的size
	[dispLayer setExternalAspectRatio:kDisplayAscpectRatioInvalid];
	
	if ([self isInFullScreenMode]) {
		// 如果正在全屏，那么将设定窗口size的工作放到退出全屏的时候进行
		// 必须砸退出全屏的时候再设定
		// 在退出全屏之前，这个view并不属于window，设定contentsize不起作用
		shouldResize = YES;
		
		// 如果是全屏开始的，那么还需要设定ControlUI的FillScreen状态
		// 全屏的时候，view的size和screen的size是一样的
		sizeVal = [self bounds].size;
		
		[controlUI setFillScreenMode:(((sizeVal.height * [dispLayer aspectRatio]) >= sizeVal.width)?kFillScreenButtonImageUBKey:kFillScreenButtonImageLRKey)
							   state:([dispLayer fillScreen])?NSOnState:NSOffState];
	} else {
		// 如果没有在全屏
		sizeVal = [self adjustWindowCoordinateTo:sizeVal];

		[playerWindow setContentAspectRatio:sizeVal];
		
		if (![playerWindow isVisible]) {
			[playerWindow makeKeyAndOrderFront:self];
		}
	}
}

-(NSSize) adjustWindowCoordinateTo:(NSSize)sizeVal
{
	sizeVal = [self calculateContentSize:sizeVal];
	
	NSPoint pos = [self calculatePlayerWindowPosition:sizeVal];

	NSRect rc = NSMakeRect(pos.x, pos.y, sizeVal.width, sizeVal.height);
	
	rc = [playerWindow frameRectForContentRect:rc];
	
	[playerWindow setFrame:rc display:YES];
	
	return sizeVal;
}

-(NSSize) calculateContentSize:(NSSize)refSize
{
	NSSize dispSize = [dispLayer displaySize];
	CGFloat aspectRatio = [dispLayer aspectRatio];
	
	NSSize screenContentSize = [playerWindow contentRectForFrameRect:[[playerWindow screen] visibleFrame]].size;
	NSSize minSize = [playerWindow contentMinSize];
	
	if ((refSize.width < 0) || (refSize.height < 0)) {
		// 非法尺寸
		if (aspectRatio <= 0) {
			// 没有在播放
			refSize = [[playerWindow contentView] bounds].size;
		} else {
			// 在播放就用影片尺寸
			refSize.height = dispSize.height;
			refSize.width = refSize.height * aspectRatio;
		}
	}
	
	refSize.width  = MAX(minSize.width, MIN(screenContentSize.width, refSize.width));
	refSize.height = MAX(minSize.height, MIN(screenContentSize.height, refSize.height));
	
	if (aspectRatio > 0) {
		if (refSize.width > (refSize.height * aspectRatio)) {
			// 现在的movie是竖图
			refSize.width = refSize.height*aspectRatio;
		} else {
			// 现在的movie是横图
			refSize.height = refSize.width/aspectRatio;
		}
	}
	return refSize;
}

-(NSPoint) calculatePlayerWindowPosition:(NSSize) winSize
{
	NSPoint pos = [playerWindow frame].origin;
	NSSize orgSz = [[playerWindow contentView] bounds].size;
	
	pos.x += (orgSz.width - winSize.width)  / 2;
	pos.y += (orgSz.height - winSize.height)/ 2;
	
	// would not let the monitor screen cut the window
	NSRect screenRc = [[playerWindow screen] visibleFrame];

	pos.x = MAX(screenRc.origin.x, MIN(pos.x, screenRc.origin.x + screenRc.size.width - winSize.width));
	pos.y = MAX(screenRc.origin.y, MIN(pos.y, screenRc.origin.y + screenRc.size.height- winSize.height));
	
	return pos;
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
////////////////////////////Application Notification////////////////////////////
-(void) applicationDidBecomeActive:(NSNotification*)notif
{
	[self setPlayerWindowLevel];
}

-(void) applicationDidResignActive:(NSNotification*)notif
{
	[self setPlayerWindowLevel];
}
///////////////////////////////////////////PlayerWindow delegate//////////////////////////////////////////////
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
	if ((window == playerWindow)) {
		NSRect scrnRect = [[window screen] frame];

		newFrame.size = [self calculateContentSize:scrnRect.size];
		newFrame = [window frameRectForContentRect:newFrame];
		newFrame.origin.x = (scrnRect.size.width - newFrame.size.width)/2;
		newFrame.origin.y = (scrnRect.size.height- newFrame.size.height)/2;
	}
	return newFrame;
}

-(void) windowDidResize:(NSNotification *)notification
{
	if (!lockAspectRatio) {
		// 如果没有锁住aspect ratio
		NSSize sz = [self bounds].size;
		[dispLayer setExternalAspectRatio:(sz.width/sz.height)];
	}
}

@end
