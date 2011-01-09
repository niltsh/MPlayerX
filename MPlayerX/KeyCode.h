/*
 * MPlayerX - KeyCode.h
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

#define kSCMSwitchTimeHintKeyModifierMask	(NSFunctionKeyMask)

extern NSString * const kSCMVolumeUpKeyEquivalent;
extern NSString * const kSCMVolumeDownKeyEquivalent;
extern NSString * const kSCMSwitchAudioKeyEquivalent;
extern NSString * const kSCMSwitchSubKeyEquivalent;
extern NSString * const kSCMSnapShotKeyEquivalent;
extern NSString * const kSCMMuteKeyEquivalent;
extern NSString * const kSCMPlayPauseKeyEquivalent;
extern NSString * const kSCMSwitchVideoKeyEquivalent;

extern NSString * const kSCMFullScrnKeyEquivalent;
#define kSCMFullscreenKeyEquivalentModifierFlagMask				(NSCommandKeyMask)

extern NSString * const kSCMFillScrnKeyEquivalent;
extern NSString * const kSCMAcceControlKeyEquivalent;

extern NSString * const kSCMSubScaleIncreaseKeyEquivalent;
#define kSCMSubScaleIncreaseKeyEquivalentModifierFlagMask		(NSCommandKeyMask)
extern NSString * const kSCMSubScaleDecreaseKeyEquivalent;
#define kSCMSubScaleDecreaseKeyEquivalentModifierFlagMask		(NSCommandKeyMask)

extern NSString * const kSCMPlayFromLastStoppedKeyEquivalent;
#define kSCMPlayFromLastStoppedKeyEquivalentModifierFlagMask	(NSShiftKeyMask)

#define kSCMDragAudioBalanceModifierFlagMask					(NSAlternateKeyMask)

extern NSString * const kSCMToggleLockAspectRatioKeyEquivalent;

extern NSString * const kSCMResetLockAspectRatioKeyEquivalent;
#define kSCMResetLockAspectRatioKeyEquivalentModifierFlagMask	(NSShiftKeyMask)

extern NSString * const kSCMVideoTunerPanelKeyEquivalent;
#define kSCMVideoTunerPanelKeyEquivalentModifierFlagMask		(NSControlKeyMask)

extern NSString * const kSCMToggleLetterBoxKeyEquivalent;

#define kSCMPlaybackSpeedUpShortcutKey		(']')
#define kSCMPlaybackSpeedDownShortcutKey	('[')
#define kSCMPlaybackSpeedResetShortcutKey	('\\')

#define kSCMAudioDelayPlusShortcutKey		(']')
#define kSCMAudioDelayMinusShortcutKey		('[')
#define kSCMAudioDelayResetShortbutKey		('\\')

#define kSCMSubDelayPlusShortcutKey			(']')
#define kSCMSubDelayMinusShortcutKey		('[')
#define kSCMSubDelayResetShortcutKey		('\\')

#define kSCMFFMpegHandleStreamShortCurKey	(NSCommandKeyMask)

extern NSString * const kSCMWindowSizeIncKeyEquivalent;
#define kSCMWindowSizeIncKeyEquivalentModifierFlagMask	(NSCommandKeyMask|NSShiftKeyMask)
extern NSString * const kSCMWindowSizeDecKeyEquivalent;
#define kSCMWindowSizeDecKeyEquivalentModifierFlagMask	(NSCommandKeyMask|NSShiftKeyMask)

extern NSString * const kSCMShowMediaInfoKeyEquivalent;

extern NSString * const kSCMEqualizerPanelKeyEquivalent;
#define kSCMEqualizerPanelKeyEquivalentModifierFlagMask		(NSControlKeyMask)

extern NSString * const kMPCStringMPlayerX;

#define kSCMMoveToTrashKeyEquivalent					(NSBackspaceCharacter)
#define kSCMMoveToTrashKeyEquivalentModifierFlagMask	(NSCommandKeyMask)

extern NSString * const kSCMMoveFrameToCenterKeyEquivalent;
