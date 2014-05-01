/*
 * MPlayerX - KeyCode.h
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

extern NSString * const kSCMToggleLockAspectRatioKeyEquivalent;

extern NSString * const kSCMResetLockAspectRatioKeyEquivalent;
#define kSCMResetLockAspectRatioKeyEquivalentModifierFlagMask	(NSShiftKeyMask)

extern NSString * const kSCMVideoTunerPanelKeyEquivalent;

extern NSString * const kSCMToggleLetterBoxKeyEquivalent;

extern NSString * const kSCMSpeedUpKeyEquivalent;
extern NSString * const kSCMSpeedDownKeyEquivalent;
extern NSString * const kSCMSpeedResetKeyEquivalent;

extern NSString * const kSCMAudioDelayPlusKeyEquivalent;
extern NSString * const kSCMAudioDelayMinusKeyEquivalent;
extern NSString * const kSCMAudioDelayResetKeyEquivalent;
#define kSCMAudioDelayKeyEquivalentModifierFlagMask				(NSAlternateKeyMask)

extern NSString * const kSCMSubDelayPlusKeyEquivalent;
extern NSString * const kSCMSubDelayMinusKeyEquivalent;
extern NSString * const kSCMSubDelayResetKeyEquivalent;
#define kSCMSubDelayKeyEquivalentModifierFlagMask				(NSCommandKeyMask)


#define kSCMFFMpegHandleStreamShortCurKey	(NSCommandKeyMask)

extern NSString * const kSCMWindowSizeIncKeyEquivalent;
#define kSCMWindowSizeIncKeyEquivalentModifierFlagMask	(NSCommandKeyMask|NSAlternateKeyMask)
extern NSString * const kSCMWindowSizeDecKeyEquivalent;
#define kSCMWindowSizeDecKeyEquivalentModifierFlagMask	(NSCommandKeyMask|NSAlternateKeyMask)

extern NSString * const kSCMShowMediaInfoKeyEquivalent;

extern NSString * const kSCMEqualizerPanelKeyEquivalent;

#define kSCMMoveToTrashKeyEquivalent					(NSBackspaceCharacter)
#define kSCMMoveToTrashKeyEquivalentModifierFlagMask	(NSCommandKeyMask)

extern NSString * const kSCMMoveFrameToCenterKeyEquivalent;

extern NSString * const kSCMNextEpisodeKeyEquivalent;
extern NSString * const kSCMPrevEpisodeKeyEquivalent;

#define kSCMScaleFrameKeyEquivalentModifierFlagMask		(NSAlternateKeyMask)

extern NSString * const kSCMResetFrameScaleRatioKeyEquivalent;
#define kSCMResetFrameScaleRatioKeyEquivalentModifierFlagMask	(NSShiftKeyMask)

#define kSCMDragFullScrFrameModifierFlagMask					(NSAlternateKeyMask)

/**
 * ctrl + = has bug, always fallback to =
 */
extern NSString * const kSCMScaleFrameLargerKeyEquivalent;
#define kSCMScaleFrameLargerKeyEquivalentModifierFlagMask	(NSAlternateKeyMask)
extern NSString * const kSCMScaleFrameSmallerKeyEquivalent;
#define kSCMScaleFrameSmallerKeyEquivalentModifierFlagMask	(NSAlternateKeyMask)

extern NSString * const kSCMScaleFrameLarger2KeyEquivalent;
#define kSCMScaleFrameLarger2KeyEquivalentModifierFlagMask	(NSAlternateKeyMask|NSShiftKeyMask)
extern NSString * const kSCMScaleFrameSmaller2KeyEquivalent;
#define kSCMScaleFrameSmaller2KeyEquivalentModifierFlagMask	(NSAlternateKeyMask|NSShiftKeyMask)

extern NSString * const kSCMMirrorKeyEquivalent;
#define kSCMMirrorKeyEquivalentModifierFlagMask		(NSAlternateKeyMask)
extern NSString * const kSCMFlipKeyEquivalent;
#define kSCMFlipKeyEquivalentModifierFlagMask		(NSAlternateKeyMask)

extern NSString * const kSCMWindowZoomHalfSizeKeyEquivalent;
#define kSCMWindowZoomHalfSizeKeyEquivalentModifierFlagMask		(NSCommandKeyMask)
extern NSString * const kSCMWindowZoomToOrgSizeKeyEquivalent;
#define kSCMWindowZoomToOrgSizeKeyEquivalentModifierFlagMask	(NSCommandKeyMask)
extern NSString * const kSCMWindowZoomDblSizeKeyEquivalent;
#define kSCMWindowZoomDblSizeKeyEquivalentModifierFlagMask		(NSCommandKeyMask)
extern NSString * const kSCMWindowFitToScreenKeyEquivalent;
#define kSCMWindowFitToScreenKeyEquivalentModifierFlagMask		(NSCommandKeyMask)

#define kSCMRotateKeyEquivalentModifierFlagMask					(NSAlternateKeyMask)

extern NSString * const kSCMABLoopSetStartKeyEquivalent;
extern NSString * const kSCMABLoopSetReturnKeyEquivalent;
extern NSString * const kSCMABLoopSetCancelKeyEquivalent;

extern NSString * const kSCMGotoSnapshotFolderKeyEquivalent;
#define kSCMGotoSnapshotFolderKeyEquivalentModifierFlagMask     (NSCommandKeyMask|NSShiftKeyMask)
