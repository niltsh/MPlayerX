/*
 * MPlayerX - ShortCutManager.m
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
#import "ShortCutManager.h"
#import "PlayerController.h"
#import "ControlUIView.h"
#import "RootLayerView.h"
#import "CocoaAppendix.h"

#define kSCMRepeatCounterThreshold	(6)

@interface ShortCutManager (ShortCutManagerInternal)
-(void)simulateEvent:(NSArray*) arg;
-(void) mediaKeyPressed:(NSNotification*)notif;
@end

@implementation ShortCutManager

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:0.1], kUDKeySpeedStep,
					   [NSNumber numberWithFloat:-10], kUDKeySeekStepL,
					   [NSNumber numberWithFloat:10], kUDKeySeekStepR,
					   [NSNumber numberWithFloat:60], kUDKeySeekStepU,
					   [NSNumber numberWithFloat:-60], kUDKeySeekStepB,
					   [NSNumber numberWithFloat:0.1], kUDKeySubDelayStepTime,
					   [NSNumber numberWithFloat:0.1], kUDKeyAudioDelayStepTime,
					   [NSNumber numberWithFloat:0.3], kUDKeyARKeyRepeatTimeInterval,
					   [NSNumber numberWithFloat:1.0], kUDKeyARKeyRepeatTimeIntervalLong,
					   [NSNumber numberWithBool:YES], kUDKeySupportAppleRemote,
                       [NSNumber numberWithBool:NO], kUDKeyARUseSysVol,
                       [NSNumber numberWithBool:NO], kUDKeyARMenuKeyTogTimeDisp,
					   [NSNumber numberWithFloat:0.5], kUDKeyKBSeekStepPeriod,
                       nil]];
}

-(id) init
{
	self = [super init];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];

		seekStepTimeL = [ud floatForKey:kUDKeySeekStepL];
		seekStepTimeR = [ud floatForKey:kUDKeySeekStepR];
		seekStepTimeU = [ud floatForKey:kUDKeySeekStepU];
		seekStepTimeB = [ud floatForKey:kUDKeySeekStepB];
        
        seekStepPeriod = [ud floatForKey:kUDKeyKBSeekStepPeriod];
        
        lastSeekL = 0;
        lastSeekR = 0;
        lastSeekU = 0;
        lastSeekB = 0;

		arKeyRepTime = [ud floatForKey:kUDKeyARKeyRepeatTimeInterval];

		repeatEntered = NO;
		repeatCanceled = NO;
		repeatCounter = 0;
		
		if ([ud boolForKey:kUDKeySupportAppleRemote]) {
			if ((appleRemoteControl = [[HIDRemote alloc] init]) != nil) {
                [appleRemoteControl setDelegate:self];
            }
		} else {
			appleRemoteControl = nil;
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillBecomeActive:)
													 name:NSApplicationWillBecomeActiveNotification
												   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillResignActive:)
													 name:NSApplicationWillResignActiveNotification
												   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaKeyPressed:)
													 name:kMPXMediaKeyPlayPauseNotification
												   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaKeyPressed:)
													 name:kMPXMediaKeyForwardNotification
												   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mediaKeyPressed:)
													 name:kMPXMediaKeyBackwardNotification
												   object:NSApp];
	}
	return self;
}

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    if (appleRemoteControl) {
        if ([appleRemoteControl isStarted]) {
            [appleRemoteControl stopRemoteControl];
        }
        [appleRemoteControl setDelegate:nil];
        [appleRemoteControl release];
    }

	[super dealloc];
}

-(void) mediaKeyPressed:(NSNotification*)notif
{
	if ([[notif name] isEqualToString:kMPXMediaKeyPlayPauseNotification]) {
		[controlUI togglePlayPause:nil];
	} else if ([[notif name] isEqualToString:kMPXMediaKeyForwardNotification]) {
		[mainMenu performKeyEquivalent:[NSEvent makeKeyDownEvent:kSCMNextEpisodeKeyEquivalent modifierFlags:0]];
	} else if ([[notif name] isEqualToString:kMPXMediaKeyBackwardNotification]) {
		[mainMenu performKeyEquivalent:[NSEvent makeKeyDownEvent:kSCMPrevEpisodeKeyEquivalent modifierFlags:0]];
	}
}

-(BOOL) processKeyDown:(NSEvent*) event
{
	unichar key;
	BOOL ret = YES;
	
	// 这里处理的是没有keyequivalent的快捷键
	if ([[event charactersIgnoringModifiers] length] == 0) {
		ret = NO;
	} else {
		key = [[event charactersIgnoringModifiers] characterAtIndex:0];

		switch ([event modifierFlags] & (NSShiftKeyMask| NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask))
		{
			case NSControlKeyMask:
				switch (key)
				{
					case NSUpArrowFunctionKey:
						[playerController changeSpeedBy:[ud floatForKey:kUDKeySpeedStep]];
						break;
					case NSDownArrowFunctionKey:
						[playerController changeSpeedBy:-[ud floatForKey:kUDKeySpeedStep]];
						break;
					case NSLeftArrowFunctionKey:
						[playerController setSpeed:1];
						break;
					default:
						ret = NO;
						break;
				}
				break;
				
			case NSShiftKeyMask:
				switch (key)
				{
					default:
						ret = NO;
						break;
				}
				break;
			case NSAlternateKeyMask:
				switch (key)
				{
					case NSUpArrowFunctionKey:
						[playerController changeAudioDelayBy:[ud floatForKey:kUDKeyAudioDelayStepTime]];
						break;
					case NSDownArrowFunctionKey:
						[playerController changeAudioDelayBy:-[ud floatForKey:kUDKeyAudioDelayStepTime]];
						break;
					case NSLeftArrowFunctionKey:
						[playerController setAudioDelay:0];
						break;
					default:
						ret = NO;
						break;
				}
				break;

			case NSCommandKeyMask:		//按下CMD键
				switch (key)
				{
					case NSUpArrowFunctionKey:
						[playerController changeSubDelayBy:[ud floatForKey:kUDKeySubDelayStepTime]];
						break;
					case NSDownArrowFunctionKey:
						[playerController changeSubDelayBy:-[ud floatForKey:kUDKeySubDelayStepTime]];
						break;
					case NSLeftArrowFunctionKey:
						[playerController setSubDelay:0];
						break;
					default:
						ret = NO;
						break;
				}
				break;
            case NSCommandKeyMask | NSControlKeyMask:
                switch (key)
                {
                    case 'f':
                        [mainMenu performKeyEquivalent:[NSEvent makeKeyDownEvent:kSCMFullScrnKeyEquivalent modifierFlags:0]];
                        break;
                    default:
                        ret = NO;
                        break;
                }
                break;
            case NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask:
            	switch (key) {
            		case NSRightArrowFunctionKey:
            		    if ([playerController playerState] == kMPCPausedState) {
                            [playerController frameStep];
                        } else {
                            [controlUI changeTimeBy:seekStepTimeR];
                        }
            			break;
            		case NSLeftArrowFunctionKey:
            			[controlUI changeTimeBy:seekStepTimeL];
            			break;
            		case NSUpArrowFunctionKey:
            			[controlUI changeTimeBy:seekStepTimeU];
            			break;
            		case NSDownArrowFunctionKey:
            			[controlUI changeTimeBy:seekStepTimeB];
            			break;
            		default:
            			ret = NO;
            			break;
            	}
            	break;
			case 0:				// 什么功能键也没有按
            {
                NSTimeInterval evtTime = [event timestamp];
                //MPLog(@"%f", (float)evtTime);
				switch (key) {                        
					case NSRightArrowFunctionKey:
                        if ((evtTime - lastSeekR) > seekStepPeriod) {
                            if ([playerController playerState] == kMPCPausedState) {
                                [playerController frameStep];
                            } else {
                                [controlUI changeTimeBy:seekStepTimeR];
                            }
                            lastSeekR = evtTime;
                            //MPLog(@"R proc");
                        }
						break;
					case NSLeftArrowFunctionKey:
                        if ((evtTime - lastSeekL) > seekStepPeriod) {
                            [controlUI changeTimeBy:seekStepTimeL];
                            lastSeekL = evtTime;
                        }
						break;
					case NSUpArrowFunctionKey:
                        if ((evtTime - lastSeekU) > seekStepPeriod) {
                            [controlUI changeTimeBy:seekStepTimeU];
                            lastSeekU = evtTime;
                        }
						break;
					case NSDownArrowFunctionKey:
                        if ((evtTime - lastSeekB) > seekStepPeriod) {
                            [controlUI changeTimeBy:seekStepTimeB];
                            lastSeekB = evtTime;
                        }
						break;
					default:
						ret = NO;
						break;
				}
            }
                break;
			default:
				ret = NO;
				break;
		}
	}
	return ret;
}

-(BOOL) processKeyUp:(NSEvent*) event
{
    unichar key;
    BOOL ret = NO;
    // 这里处理的是没有keyequivalent的快捷键
	if ([[event charactersIgnoringModifiers] length] == 0) {
		ret = NO;
	} else {
		key = [[event charactersIgnoringModifiers] characterAtIndex:0];
        
		switch ([event modifierFlags] & (NSShiftKeyMask| NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) {
            case 0:				// 什么功能键也没有按
            {
				switch (key) {                        
					case NSRightArrowFunctionKey:
                        lastSeekR = 0;
						break;
					case NSLeftArrowFunctionKey:
                        lastSeekL = 0;
						break;
					case NSUpArrowFunctionKey:
                        lastSeekU = 0;
						break;
					case NSDownArrowFunctionKey:
                        lastSeekB = 0;
                        break;
					default:
						break;
				}
            }
            default:
                break;
        }
    }
    return ret;
}

- (void)hidRemote:(HIDRemote *)theHidRemote
  eventWithButton:(HIDRemoteButtonCode)buttonCode
        isPressed:(BOOL)isPressed
fromHardwareWithAttributes:(NSMutableDictionary *)attributes
{
	unichar key = 0;
	NSString *keyEqTemp = nil;
	id target = nil;
	SEL action = NULL;
	NSUInteger modifierFlagMask = 0;
	
	if (isPressed) {
		repeatCanceled = NO;
		// 如果是按下键
		switch(buttonCode) {
			case kHIDRemoteButtonCodeUpHold:
			case kHIDRemoteButtonCodeUp:
            {
                if ([ud boolForKey:kUDKeyARUseSysVol]) {
                    NSDictionary *err;
                    NSAppleScript *volUpScpt = [[NSAppleScript alloc] initWithSource:@"set curVolSet to get volume settings \r\n \
                                                                                       set curVol to output volume of curVolSet \r\n \
                                                                                       set curVol to curVol + 5 \r\n \
                                                                                       if curVol > 100 then set curVol to 100 \r\n \
                                                                                       set volume output volume curVol"];
                    [volUpScpt executeAndReturnError:&err];
                    [volUpScpt release];
                } else {
                    keyEqTemp = kSCMVolumeUpKeyEquivalent;
                    target = mainMenu;
                    action = @selector(performKeyEquivalent:);
                }
            }
				break;
                
			case kHIDRemoteButtonCodeDownHold:
			case kHIDRemoteButtonCodeDown:
            {
                if ([ud boolForKey:kUDKeyARUseSysVol]) {
                    NSDictionary *err;
                    NSAppleScript *volDownScpt = [[NSAppleScript alloc] initWithSource:@"set curVolSet to get volume settings \r\n \
                                                                                         set curVol to output volume of curVolSet \r\n \
                                                                                         set curVol to curVol - 5 \r\n \
                                                                                         if curVol < 0 then set curVol to 0 \r\n \
                                                                                         set volume output volume curVol"];
                    [volDownScpt executeAndReturnError:&err];
                    [volDownScpt release];
                } else {
                    keyEqTemp = kSCMVolumeDownKeyEquivalent;
                    target = mainMenu;
                    action = @selector(performKeyEquivalent:);
                }
            }
				break;			
						
			case kHIDRemoteButtonCodeMenu:
            {
                if ([ud boolForKey:kUDKeyARMenuKeyTogTimeDisp]) {
                    [ud setBool:![ud boolForKey:kUDKeyTimeTextAltTotal] forKey:kUDKeyTimeTextAltTotal];
                    [controlUI showUp];
                } else {
                    keyEqTemp = kSCMFullScrnKeyEquivalent;
                    target = mainMenu;
                    action = @selector(performKeyEquivalent:);
                }
            }
				break;			
			
			case kHIDRemoteButtonCodeMenuHold:
				keyEqTemp = kSCMFillScrnKeyEquivalent;
				target = mainMenu;
				action = @selector(performKeyEquivalent:);
				break;
			
			case kHIDRemoteButtonCodePlay:
                // this is only for aluminium
				keyEqTemp = kSCMPlayPauseKeyEquivalent;
				target = controlUI;
				action = @selector(performKeyEquivalent:);
				break;			
            case kHIDRemoteButtonCodeCenter:
                // center key is play/pause for plastic
                // but for aluminium, it is other key
                if ([theHidRemote lastSeenModel] != kHIDRemoteModelAluminum) {
                    keyEqTemp = kSCMPlayPauseKeyEquivalent;
                    target = controlUI;
                    action = @selector(performKeyEquivalent:);
                }
				break;			
			// case kHIDRemoteButtonCodePlayHold:
            case kHIDRemoteButtonCodeCenterHold:
            {
				NSAppleScript *sleepScript = [[NSAppleScript alloc] initWithSource:@"do shell script \"pmset sleepnow\""];
				NSDictionary *err;
				
				// 如果正在播放就先暂停
				if ([playerController playerState] == kMPCPlayingState) {
					[controlUI togglePlayPause:nil];
				}
				[sleepScript executeAndReturnError:&err];
				[sleepScript release];
            }
				break;
			case kHIDRemoteButtonCodeRightHold:
				repeatEntered = YES;
				repeatCounter = 0;
				arKeyRepTime = [ud floatForKey:kUDKeyARKeyRepeatTimeInterval];
			case kHIDRemoteButtonCodeRight:
				key = NSRightArrowFunctionKey;
				target = self;
				action = @selector(processKeyDown:);
				modifierFlagMask = NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask;
				break;
			case kHIDRemoteButtonCodeLeftHold:
				repeatEntered = YES;
				repeatCounter = 0;
				arKeyRepTime = [ud floatForKey:kUDKeyARKeyRepeatTimeInterval];
			case kHIDRemoteButtonCodeLeft:
				key = NSLeftArrowFunctionKey;
				target = self;
				action = @selector(processKeyDown:);
				modifierFlagMask = NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask;
				break;			
			
			default:
				break;
		}
		if (target && action) {
			NSEvent *event;
			if (keyEqTemp) {
				event = [NSEvent makeKeyDownEvent:keyEqTemp modifierFlags:modifierFlagMask];
			} else {
				event = [NSEvent makeKeyDownEvent:[NSString stringWithCharacters:&key length:1] modifierFlags:modifierFlagMask];
			}
			[self simulateEvent:[NSArray arrayWithObjects:target, NSStringFromSelector(action), event, nil]];
		}		
	} else {
		// 如果是放开键
		repeatCanceled = YES;
		repeatEntered = NO;
	}
}

-(void) simulateEvent:(NSArray *)arg
{
	id tgt = [arg objectAtIndex:0];
	SEL sel = NSSelectorFromString([arg objectAtIndex:1]);
	NSEvent *evt = [arg objectAtIndex:2];
	
	if (!repeatCanceled) {
		[tgt performSelector:sel withObject:evt];
	}
	
	if (repeatEntered) {		
		repeatCounter++;
		
		if (repeatCounter != kSCMRepeatCounterThreshold) {
			[self performSelector:@selector(simulateEvent:) withObject:arg afterDelay:arKeyRepTime];
			
		} else if (repeatCounter == kSCMRepeatCounterThreshold) {
			NSEvent *newEv = nil;
			unichar key = [[evt charactersIgnoringModifiers] characterAtIndex:0];
			float timeLong = arKeyRepTime;
			
			if ((key == NSRightArrowFunctionKey) || (key == NSLeftArrowFunctionKey)) {
				if (key == NSRightArrowFunctionKey) {
					key = NSUpArrowFunctionKey;
				} else {
					key = NSDownArrowFunctionKey;
				}
				newEv = [NSEvent makeKeyDownEvent:[NSString stringWithCharacters:&key length:1] modifierFlags:NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask];
				timeLong = [ud floatForKey:kUDKeyARKeyRepeatTimeIntervalLong];
			} else {
				newEv = evt;
			}
			
			[self performSelector:@selector(simulateEvent:)
					   withObject:[NSArray arrayWithObjects:tgt, NSStringFromSelector(sel), newEv, nil]
					   afterDelay:arKeyRepTime];
			arKeyRepTime = timeLong;
		}
	}
}

-(void) applicationWillBecomeActive:(NSNotification*) notif
{
	if (appleRemoteControl && (![appleRemoteControl isStarted])) {
		[appleRemoteControl startRemoteControl:kHIDRemoteModeExclusiveAuto];
	}
}

-(void) applicationWillResignActive:(NSNotification*) notif
{
	if (appleRemoteControl && [appleRemoteControl isStarted]) {
		[appleRemoteControl stopRemoteControl];
	}
}

@end
