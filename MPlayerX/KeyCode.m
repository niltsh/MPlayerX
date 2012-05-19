/*
 * MPlayerX - KeyCode.m
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

/////////////////////////////////short keys defination/////////////////////////////////
NSString * const kSCMVolumeUpKeyEquivalent		= @"=";
NSString * const kSCMVolumeDownKeyEquivalent	= @"-";
NSString * const kSCMSwitchAudioKeyEquivalent	= @"a";
NSString * const kSCMSwitchSubKeyEquivalent		= @"s";
NSString * const kSCMSnapShotKeyEquivalent		= @"S";
NSString * const kSCMMuteKeyEquivalent			= @"m";
NSString * const kSCMPlayPauseKeyEquivalent		= @" ";
NSString * const kSCMFullScrnKeyEquivalent		= @"f";
NSString * const kSCMFillScrnKeyEquivalent		= @"F";
NSString * const kSCMAcceControlKeyEquivalent	= @"c";
NSString * const kSCMSwitchVideoKeyEquivalent	= @"v";

NSString * const kSCMSubScaleIncreaseKeyEquivalent		= @"=";
NSString * const kSCMSubScaleDecreaseKeyEquivalent		= @"-";

NSString * const kSCMPlayFromLastStoppedKeyEquivalent	= @"c";

NSString * const kSCMToggleLockAspectRatioKeyEquivalent	= @"r";

NSString * const kSCMResetLockAspectRatioKeyEquivalent	= @"r";

NSString * const kSCMVideoTunerPanelKeyEquivalent		= @"d";

NSString * const kSCMToggleLetterBoxKeyEquivalent		= @"l";

NSString * const kSCMWindowSizeIncKeyEquivalent			= @"=";
NSString * const kSCMWindowSizeDecKeyEquivalent			= @"-";

NSString * const kSCMShowMediaInfoKeyEquivalent			= @"i";

NSString * const kSCMEqualizerPanelKeyEquivalent		= @"e";

NSString * const kSCMMoveFrameToCenterKeyEquivalent		= @"t";

NSString * const kSCMNextEpisodeKeyEquivalent			= @".";
NSString * const kSCMPrevEpisodeKeyEquivalent			= @",";

NSString * const kSCMResetFrameScaleRatioKeyEquivalent	= @"t";

NSString * const kSCMScaleFrameLargerKeyEquivalent		= @"=";
NSString * const kSCMScaleFrameSmallerKeyEquivalent		= @"-";

NSString * const kSCMScaleFrameLarger2KeyEquivalent		= @"=";
NSString * const kSCMScaleFrameSmaller2KeyEquivalent	= @"-";

NSString * const kSCMMirrorKeyEquivalent				= @"m";
NSString * const kSCMFlipKeyEquivalent					= @"f";

NSString * const kSCMWindowZoomHalfSizeKeyEquivalent    = @"`";
NSString * const kSCMWindowZoomToOrgSizeKeyEquivalent	= @"1";
NSString * const kSCMWindowZoomDblSizeKeyEquivalent		= @"2";
NSString * const kSCMWindowFitToScreenKeyEquivalent		= @"3";

NSString * const kSCMSpeedUpKeyEquivalent				= @"]";
NSString * const kSCMSpeedDownKeyEquivalent				= @"[";
NSString * const kSCMSpeedResetKeyEquivalent			= @"\\";

NSString * const kSCMAudioDelayPlusKeyEquivalent		= @"]";
NSString * const kSCMAudioDelayMinusKeyEquivalent		= @"[";
NSString * const kSCMAudioDelayResetKeyEquivalent		= @"\\";

NSString * const kSCMSubDelayPlusKeyEquivalent			= @"]";
NSString * const kSCMSubDelayMinusKeyEquivalent			= @"[";
NSString * const kSCMSubDelayResetKeyEquivalent			= @"\\";

NSString * const kSCMABLoopSetStartKeyEquivalent        = @"b";
NSString * const kSCMABLoopSetReturnKeyEquivalent       = @"n";
NSString * const kSCMABLoopSetCancelKeyEquivalent       = @"h";

NSString * const kSCMGotoSnapshotFolderKeyEquivalent    = @"g";
