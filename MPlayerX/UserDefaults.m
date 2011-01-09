/*
 * MPlayerX - UserDefaults.h
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

#import <Cocoa/Cocoa.h>
#import "UserDefaults.h"

////////////////////////////UserDefaults defination/////////////////////////////////
NSString * const kUDKeyVolume				= @"volume";
NSString * const kUDKeyOnTopMode			= @"OnTopMode";
NSString * const kUDKeyCtrlUIAutoHideTime	= @"CtrlUIAutoHideTime";
NSString * const kUDKeySpeedStep			= @"SpeedStepIncre";
NSString * const kUDKeySeekStepLR			= @"SeekStepTimeLR";
NSString * const kUDKeySeekStepUB			= @"SeekStepTimeUB";
NSString * const kUDKeyVolumeStep			= @"VolumeStep";
NSString * const kUDKeyAutoPlayNext			= @"AutoPlayNext";
NSString * const kUDKeyAPNFuzzy				= @"APNFuzzy";
NSString * const kUDKeySubFontPath			= @"SubFontPath";
NSString * const kUDKeySnapshotSavePath		= @"SnapshotSavePath";
NSString * const kUDKeyStartByFullScreen	= @"StartByFullScreen";
NSString * const kUDKeySubDelayStepTime		= @"SubDelayStepTime";
NSString * const kUDKeyAudioDelayStepTime	= @"AudioDelayStepTime";
NSString * const kUDKeyPrefer64bitMPlayer	= @"Prefer64bitMPlayer";
NSString * const kUDKeyEnableMultiThread	= @"EnableMultiThread";
NSString * const kUDKeySubScale				= @"SubScale";
NSString * const kUDKeySubScaleStepValue	= @"SubScaleStepValue";
NSString * const kUDKeySwitchTimeHintPressOnAbusolute	= @"TimeHintPrsOnAbs";
NSString * const kUDKeyTimeTextAltTotal		= @"TimeTextAltTotal";
NSString * const kUDKeyQuitOnClose			= @"QuitOnClose";
NSString * const kUDKeySubFontColor			= @"SubFontColor";
NSString * const kUDKeySubFontBorderColor	= @"SubFontBorderColor";
NSString * const kUDKeyCtrlUIBackGroundAlpha= @"CtrlUIBackGroundAlpha";
NSString * const kUDKeyForceIndex			= @"ForceIndex";
NSString * const kUDKeySubFileNameRule		= @"SubFileNameRule";
NSString * const kUDKeyDTSPassThrough		= @"DTSPassThrough";
NSString * const kUDKeyAC3PassThrough		= @"AC3PassThrough";
NSString * const kUDKeyShowOSD				= @"ShowOSD";
NSString * const kUDKeyOSDFontSizeMax		= @"OSDFontSizeMax";
NSString * const kUDKeyOSDFontSizeMin		= @"OSDFontSizeMin";
NSString * const kUDKeyOSDFrontColor		= @"OSDFrontColor";
NSString * const kUDKeyOSDAutoHideTime		= @"OSDAutoHideTime";
NSString * const kUDKeyThreadNum			= @"NumberOfThreads";
NSString * const kUDKeyUseEmbeddedFonts		= @"UseEmbeddedFonts";
NSString * const kUDKeyCacheSize			= @"CacheSize";
NSString * const kUDKeyPreferIPV6			= @"PreferIPV6";
NSString * const kUDKeyCachingLocal			= @"CachingLocal";
NSString * const kUDKeyFullScreenKeepOther	= @"FullScreenKeepOther";
NSString * const kUDKeyLetterBoxMode		= @"LetterBoxMode";
NSString * const kUDKeyLetterBoxModeAlt		= @"LetterBoxModeAlt";
NSString * const kUDKeyLetterBoxHeight		= @"LetterBoxHeight";
NSString * const kUDKeyVideoTunerStepValue	= @"VideoTunerStepValue";
NSString * const kUDKeyARKeyRepeatTimeInterval				= @"ARKeyRepeatTimeInterval";
NSString * const kUDKeyARKeyRepeatTimeIntervalLong			= @"ARKeyRepeatTimeIntervalLong";
NSString * const kUDKeyPlayWhenOpened						= @"PlayWhenOpened";
NSString * const kUDKeyTextSubtitleCharsetConfidenceThresh	= @"TextSubCharsetConfidenceThresh";
NSString * const kUDKeyTextSubtitleCharsetManual			= @"TextSubCharsetManual";
NSString * const kUDKeyTextSubtitleCharsetFallback			= @"TextSubCharsetFallback";
NSString * const kUDKeyOverlapSub				= @"OverlapSub";
NSString * const kUDKeyRtspOverHttp				= @"RtspOverHttp";
NSString * const kUDKeyFFMpegHandleStream		= @"FFMpegHandleStream";
NSString * const kUDKeyMixToStereoMode			= @"MixToSterMode";
NSString * const kUDKeyAutoResume				= @"AutoResume";
NSString * const kUDKeyHideTitlebar				= @"HideTitlebar";
NSString * const kUDKeyAlwaysHideDockInFullScrn	= @"AlwaysHideDockInFullScrn";
NSString * const kUDKeyLogMode					= @"LogMode";
NSString * const kUDKeyImgEnhanceMethod			= @"ImgEnhMethod";
NSString * const kUDKeyDeIntMethod				= @"DeIntMethod";
NSString * const kUDKeyAutoShowLBInFullScr		= @"AutoShowLBInFullScr";
NSString * const kUDKeyAutoFSLBMode				= @"AutoFSLBMode";
NSString * const kUDKeyExtraOptions				= @"ExtraOptions";

NSString * const kUDKeySelectedPrefView			= @"SelectedPrefView";
NSString * const kUDKeyHelpURL					= @"HelpURL";
NSString * const kUDKeyCloseWindowWhenStopped	= @"CloseOnStopped";
NSString * const kUDKeyResizeStep				= @"ResizeStep";

NSString * const kUDKeyAutoSaveVTSettings		= @"ASVTS";
NSString * const kUDKeyAutoSaveEQSettings		= @"ASEQS";
NSString * const kUDKeyPinPMode					= @"PinPMode";
