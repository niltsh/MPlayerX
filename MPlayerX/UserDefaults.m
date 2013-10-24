/*
 * MPlayerX - UserDefaults.h
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
#import "UserDefaults.h"

////////////////////////////UserDefaults defination/////////////////////////////////
NSString * const kUDKeyVolume								= @"volume";
NSString * const kUDKeyOnTopMode							= @"OnTopMode";
NSString * const kUDKeyCtrlUIAutoHideTime					= @"CtrlUIAutoHideTime";
NSString * const kUDKeySpeedStep							= @"SpeedStepIncre";
NSString * const kUDKeySeekStepL							= @"SeekStepTimeL";
NSString * const kUDKeySeekStepR							= @"SeekStepTimeR";
NSString * const kUDKeySeekStepU							= @"SeekStepTimeU";
NSString * const kUDKeySeekStepB							= @"SeekStepTimeB";
NSString * const kUDKeyVolumeStep							= @"VolumeStep";
NSString * const kUDKeyAutoPlayNext							= @"AutoPlayNext";
NSString * const kUDKeySubFontPath							= @"SubFontPath";
NSString * const kUDKeySnapshotFormat                       = @"SnapshotFormat";
NSString * const kUDKeySnapshotSavePath						= @"SnapshotSavePath";
NSString * const kUDKeyStartByFullScreen					= @"StartByFullScreen";
NSString * const kUDKeySubDelayStepTime						= @"SubDelayStepTime";
NSString * const kUDKeyAudioDelayStepTime					= @"AudioDelayStepTime";
NSString * const kUDKeyPrefer64bitMPlayer					= @"Prefer64bitMPlayer";
NSString * const kUDKeySubScale								= @"SubScale";
NSString * const kUDKeySubScaleStepValue					= @"SubScaleStepValue";
NSString * const kUDKeySwitchTimeHintPressOnAbusolute		= @"TimeHintPrsOnAbs";
NSString * const kUDKeyTimeTextAltTotal						= @"TimeTextAltTotal";
NSString * const kUDKeyQuitOnClose							= @"QuitOnClose";
NSString * const kUDKeySubFontColor							= @"SubFontColor";
NSString * const kUDKeySubFontBorderColor					= @"SubFontBorderColor";
NSString * const kUDKeyCtrlUIBackGroundAlpha				= @"CtrlUIBackGroundAlpha";
NSString * const kUDKeyForceIndex							= @"ForceIndex";
NSString * const kUDKeySubFileNameRule						= @"SubFileNameRule";
NSString * const kUDKeyDTSPassThrough						= @"DTSPassThrough";
NSString * const kUDKeyAC3PassThrough						= @"AC3PassThrough";
NSString * const kUDKeyShowOSD								= @"ShowOSD";
NSString * const kUDKeyOSDFontSizeMax						= @"OSDFontSizeMax";
NSString * const kUDKeyOSDFontSizeMin						= @"OSDFontSizeMin";
NSString * const kUDKeyOSDFrontColor						= @"OSDFrontColor";
NSString * const kUDKeyOSDAutoHideTime						= @"OSDAutoHideTime";
NSString * const kUDKeyThreadNum							= @"NumberOfThreads";
NSString * const kUDKeyUseEmbeddedFonts						= @"UseEmbeddedFonts";
NSString * const kUDKeyCacheSize							= @"CacheSize";
NSString * const kUDKeyPreferIPV6							= @"PreferIPV6";
NSString * const kUDKeyCacheSizeLocalMinLimit				= @"CacheSizeLocalMinLimit";
NSString * const kUDKeyCacheSizeLocalTime					= @"CacheSizeLocalTime";
NSString * const kUDKeyFullScreenKeepOther					= @"FullScreenKeepOther";
NSString * const kUDKeyLetterBoxMode						= @"LetterBoxMode";
NSString * const kUDKeyLetterBoxModeAlt						= @"LetterBoxModeAlt";
NSString * const kUDKeyLetterBoxHeight						= @"LetterBoxHeight";
NSString * const kUDKeyVideoTunerStepValue					= @"VideoTunerStepValue";
NSString * const kUDKeyARKeyRepeatTimeInterval				= @"ARKeyRepeatTimeInterval";
NSString * const kUDKeyARKeyRepeatTimeIntervalLong			= @"ARKeyRepeatTimeIntervalLong";
NSString * const kUDKeyPlayWhenOpened						= @"PlayWhenOpened";
NSString * const kUDKeyTextSubtitleCharsetConfidenceThresh	= @"TextSubCharsetConfidenceThresh";
NSString * const kUDKeyTextSubtitleCharsetManual			= @"TextSubCharsetManual";
NSString * const kUDKeyTextSubtitleCharsetFallback			= @"TextSubCharsetFallback";
NSString * const kUDKeyOverlapSub							= @"OverlapSub";
NSString * const kUDKeyRtspOverHttp							= @"RtspOverHttp";
NSString * const kUDKeyFFMpegHandleStream					= @"FFMpegHandleStream";
NSString * const kUDKeyMixToStereoMode						= @"MixToSterMode";
NSString * const kUDKeyAutoResume							= @"AutoResume";
NSString * const kUDKeyHideTitlebar							= @"HideTitlebar";
NSString * const kUDKeyAlwaysHideDockInFullScrn				= @"AlwaysHideDockInFullScrn";
NSString * const kUDKeyLogMode								= @"LogMode";
NSString * const kUDKeyImgEnhanceMethod						= @"ImgEnhMethod";
NSString * const kUDKeyDeIntMethod							= @"DeIntMethod";
NSString * const kUDKeyExtraOptions							= @"ExtraOptions";
NSString * const kUDKeyEQSettings							= @"EQSettings";
NSString * const kUDKeyAutoSaveEQSettings					= @"ASEQS";
NSString * const kUDKeyVTSettings							= @"VTSettings";
NSString * const kUDKeyAutoSaveVTSettings					= @"ASVTS";
NSString * const kUDKeySubAlign								= @"SubAlign";
NSString * const kUDKeySubBorderWidth						= @"SubBorderWidth";
NSString * const kUDKeyDisableHScrollSeek					= @"DisableHScrollSeek";
NSString * const kUDKeyDisableVScrollVol					= @"DisableVScrollVol";
NSString * const kUDKeyLBAutoHeightInFullScrn				= @"LBAutoHeightInFullScrn";
NSString * const kUDKeyNoDispSub							= @"NoDispSub";
NSString * const kUDKeyCloseWndOnEsc						= @"CloseWndOnEsc";
NSString * const kUDKeyPlayWhenEnterFullScrn				= @"PlayWhenEnterFullScrn";
NSString * const kUDKeySupportAppleRemote					= @"SupportAppleRemote";
NSString * const kUDKeyAutoDetectSPDIF						= @"AutoDetectSPDIF";
NSString * const kUDKeyAssSubMarginV						= @"AssSubMarginV";
NSString * const kUDKeyDontResizeWhenContinuousPlay			= @"DontResizeWhenContinuousPlay";
NSString * const kUDKeyEnableMediaKeyTap					= @"EnableMediaKeyTap";
NSString * const kUDKeyResizeControlBar						= @"ResizeControlBar";
NSString * const kUDKeyInitialFrameSizeRatio				= @"InitialFrameSizeRatio";
NSString * const kUDKeyDisableLastStopBookmark				= @"DisableLastStopBookmark";
NSString * const kUDKeyEnableOpenRecentMenu					= @"EnableOpenRecentMenu";
NSString * const kUDKeyOldFullScreenMethod					= @"OldFullScreenMethod2";
NSString * const kUDKeyAlwaysUseSecondaryScreen				= @"AlwaysUseSecondaryScreen";
NSString * const kUDKeyClickTogPlayPause                    = @"ClickTogPlayPause";
NSString * const kUDKeyARUseSysVol                          = @"ARUseSysVol";
NSString * const kUDKeyARMenuKeyTogTimeDisp                 = @"ARMenuKeyTogTimeDisp";
NSString * const kUDKeyAnimateFullScreen                    = @"AnimateFullScreenDeprecated";
NSString * const kUDKeyPauseShowTime                        = @"PauseShowTime";
NSString * const kUDKeyControlUIDetectMouseExit             = @"ControlUIDetectMouseExit";
NSString * const kUDKeyResumedShowTime                      = @"ResumedShowTime";
NSString * const kUDKeyEnableHWAccel                        = @"EnableHWAccel2";
NSString * const kUDKeyControlUICenterYRatio                = @"ControlUICenterYRatio";
NSString * const kUDKeyShowRealRemainingTime                = @"ShowRealRemainingTime";
NSString * const kUDKeyFFmpegRealCodecThreadFix             = @"FFmpegRealCodecThreadFix";

NSString * const kUDKeySelectedPrefView						= @"SelectedPrefView";
NSString * const kUDKeyCloseWindowWhenStopped				= @"CloseOnStopped";
NSString * const kUDKeyResizeStep							= @"ResizeStep";
NSString * const kUDKeyFrameScaleStep						= @"FrameScaleStep";
NSString * const kUDKeyThreeFingersPinchThreshRatio			= @"TFPThreshRatio";
NSString * const kUDKeyFourFingersPinchThreshRatio			= @"FFPThreshRatio";
NSString * const kUDKeyFontFallbackList                     = @"FontFallbackList";
NSString * const kUDKeyKBSeekStepPeriod                     = @"KBSeekStepPeriod";
NSString * const kUDKeyThreeFingersSwipeThreshRatio			= @"TFSThreshRatio";

NSString * const kUDKeyPinPMode								= @"PinPMode";
