/*
 * MPlayerX - MPApplication+Scripting.m
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

#import "MPApplication.h"
#import "PlayerController.h"
#import "CocoaAppendix.h"
#import "AppController.h"
#import "KeyCode.h"
#import "ControlUIView.h"

@implementation MPApplication (Scripting)

-(id) processScriptCommand:(NSScriptCommand*)command
{
    id ret = nil;

    NSString *name = [[command commandDescription] commandName];

    if ([name isEqualToString:@"seekto"]) {
        [controlUI seekTo:[command directParameter]];
        
    } else if ([name isEqualToString:@"current time"]) {
        ret = [NSNumber numberWithDouble:[[[[playerController mediaInfo] playingInfo] currentTime] doubleValue]];

    } else if ([name isEqualToString:@"duration"]) {
        ret = [NSNumber numberWithDouble:[[[playerController mediaInfo] length] doubleValue]];
        
    } else if ([name isEqualToString:@"playstatus"]) {
        int status = [playerController playerState];
        switch (status) {
            case kMPCPausedState:
                ret = @"Paused";
                break;
            case kMPCPlayingState:
            case kMPCOpenedState:
                ret = @"Playing";
                break;
            default:
                ret = @"Stopped";
                break;
        }
    } else if ([name isEqualToString:@"pause"]) {
        if ([playerController playerState] == kMPCPlayingState) {
            [controlUI togglePlayPause:self];
        }
    } else if ([name isEqualToString:@"play"]) {
        if ([playerController playerState] == kMPCPausedState) {
            [controlUI togglePlayPause:self];
        }
    } else if ([name isEqualToString:@"mute"]) {
        [controlUI toggleMute:self];

    } else if ([name isEqualToString:@"playpause"]) {
        [controlUI togglePlayPause:self];

    } else if ([name isEqualToString:@"stop"]) {
        [playerController stop];

    } else if ([name isEqualToString:@"goto next episode"]) {
        [NSApp sendEvent:[NSEvent makeKeyDownEvent:kSCMNextEpisodeKeyEquivalent modifierFlags:0]];

    } else if ([name isEqualToString:@"goto previous episode"]) {
        [NSApp sendEvent:[NSEvent makeKeyDownEvent:kSCMPrevEpisodeKeyEquivalent modifierFlags:0]];
    }
    return ret;
}
@end
