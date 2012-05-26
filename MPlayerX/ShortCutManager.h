/*
 * MPlayerX - ShortCutManager.h
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
#import "HIDRemote.h"

@class PlayerController, ControlUIView, RootLayerView;

@interface ShortCutManager : NSObject <HIDRemoteDelegate>
{
	NSUserDefaults *ud;
	
	HIDRemote *appleRemoteControl;
	
	BOOL repeatEntered;
	BOOL repeatCanceled;
	NSUInteger repeatCounter;
	float arKeyRepTime;

	float seekStepTimeL;
	float seekStepTimeR;
	float seekStepTimeU;
	float seekStepTimeB;
    
    float seekStepPeriod;
    
    NSTimeInterval lastSeekL;
    NSTimeInterval lastSeekR;
    NSTimeInterval lastSeekU;
    NSTimeInterval lastSeekB;
    
	IBOutlet PlayerController *playerController;
	IBOutlet ControlUIView *controlUI;
	IBOutlet RootLayerView *dispView;
	IBOutlet NSMenu *mainMenu;
}

-(BOOL) processKeyDown:(NSEvent*) event;
-(BOOL) processKeyUp:(NSEvent*) event;

- (void)hidRemote:(HIDRemote *)hidRemote                        // The instance of HIDRemote sending this
  eventWithButton:(HIDRemoteButtonCode)buttonCode               // Event for the button specified by code
        isPressed:(BOOL)isPressed                               // The button was pressed (YES) / released (NO)
fromHardwareWithAttributes:(NSMutableDictionary *)attributes;	// Information on the device this event comes from

@end
