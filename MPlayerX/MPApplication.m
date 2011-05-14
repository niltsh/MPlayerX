/*
 * MPlayerX - MPApplication.m
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

#import <iokit/hidsystem/ev_keymap.h>
#import "MPApplication.h"
#import "CocoaAppendix.h"
#import "def.h"

@implementation MPApplication

-(void) sendEvent:(NSEvent*)event
{
	// Catch media key events
    if ([event type] == NSSystemDefined && [event subtype] == 8) {
        int keyCode = (([event data1] & 0xFFFF0000) >> 16);
        int keyState = (((([event data1] & 0x0000FFFF) & 0xFF00) >> 8)) == 0xA;
		
		switch (keyCode) {
			case NX_KEYTYPE_PLAY:
				if (keyState == NO) {
					MPLog(@"play/pause");
					[[NSNotificationCenter defaultCenter] postNotificationName:kMPXMediaKeyPlayPauseNotification object:self];
				}
				break;
			case NX_KEYTYPE_FAST:
				if (keyState == YES) {
					MPLog(@"forward");
					[[NSNotificationCenter defaultCenter] postNotificationName:kMPXMediaKeyForwardNotification object:self];
				}
				break;
			case NX_KEYTYPE_REWIND:
				if (keyState == YES) {
					MPLog(@"backward");
					[[NSNotificationCenter defaultCenter] postNotificationName:kMPXMediaKeyBackwardNotification object:self];
				}
				break;
			default:
				break;
		}
	}
	[super sendEvent:event];
}

@end
