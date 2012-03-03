/*
 * MPlayerX - VideoTunerController.m
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
#import "VideoTunerController.h"
#import <Quartz/Quartz.h>
#import "PlayerController.h"
#import "CocoaAppendix.h"

#define kCIStepBase							(100000.0)

#define kAutoSaveVTSettingsLifeNone			(0)		/**< 只要开始播放就reset */
#define kAutoSaveVTSettingsLifeAPN			(1)		/**< 不是APN的时候reset */
#define kAutoSaveVTSettingsLifeApplication	(2)		/**< 程序关闭时reset */
#define kAutoSaveVTSettingsLifeUserDefaults	(3)		/**< 不reset */

NSString * const kCIInputNoiseLevelKey	= @"inputNoiseLevel";
NSString * const kCIInputPowerKey		= @"inputPower";

NSString * const kCILayerBrightnessKeyPath	= @"filters.colorFilter.inputBrightness";
NSString * const kCILayerSaturationKeyPath	= @"filters.colorFilter.inputSaturation";
NSString * const kCILayerContrastKeyPath	= @"filters.colorFilter.inputContrast";
NSString * const kCILayerNoiseLevelKeyPath	= @"filters.nrFilter.inputNoiseLevel";
NSString * const kCILayerSharpnessKeyPath	= @"filters.nrFilter.inputSharpness";
NSString * const kCILayerGammaKeyPath		= @"filters.gammaFilter.inputPower";
NSString * const kCILayerHueAngleKeyPath	= @"filters.hueFilter.inputAngle";

NSString * const kCILayerBrightnessEnabledKeyPath	= @"filters.colorFilter.enabled";
NSString * const kCILayerSaturationEnabledKeyPath	= @"filters.colorFilter.enabled";
NSString * const kCILayerContrastEnabledKeyPath		= @"filters.colorFilter.enabled";
NSString * const kCILayerNoiseLevelEnabledKeyPath	= @"filters.nrFilter.enabled";
NSString * const kCILayerSharpnesEnabledKeyPath		= @"filters.nrFilter.enabled";
NSString * const kCILayerGammaEnabledKeyPath		= @"filters.gammaFilter.enabled";
NSString * const kCILayerHueAngleEnabledKeyPath		= @"filters.hueFilter.enabled";

@interface VideoTunerController (Internal)
-(void) playBackStopped:(NSNotification*)notif;
-(void) playBackFinalized:(NSNotification*)notif;
-(void) loadParameters;
-(void) saveParameters;
-(NSArray*) makeFilterChains;
@end

@implementation VideoTunerController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:0.01], kUDKeyVideoTunerStepValue,
					   [NSNumber numberWithInt:kAutoSaveVTSettingsLifeAPN], kUDKeyAutoSaveVTSettings,
					   nil]];
}

-(id) init
{
	self = [super init];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];

		nibLoaded = NO;		
		layer = nil;
		
		enableStrDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 kCILayerBrightnessEnabledKeyPath, kCILayerBrightnessKeyPath,
						 kCILayerSaturationEnabledKeyPath, kCILayerSaturationKeyPath,
						 kCILayerContrastEnabledKeyPath, kCILayerContrastKeyPath,
						 kCILayerNoiseLevelEnabledKeyPath, kCILayerNoiseLevelKeyPath,
						 kCILayerSharpnesEnabledKeyPath, kCILayerSharpnessKeyPath,
						 kCILayerGammaEnabledKeyPath, kCILayerGammaKeyPath,
						 kCILayerHueAngleEnabledKeyPath, kCILayerHueAngleKeyPath,
						 nil];
	}
	return self;
}

-(void) dealloc
{
	layer = nil;

	[enableStrDict release];

	[super dealloc];
}

-(void) awakeFromNib
{
	if (!nibLoaded) {
		[menuVTPanel setKeyEquivalent:kSCMVideoTunerPanelKeyEquivalent];

		if ([ud integerForKey:kUDKeyAutoSaveVTSettings] != kAutoSaveVTSettingsLifeUserDefaults) {
			[ud removeObjectForKey:kUDKeyVTSettings];
		}
		
		[self loadParameters];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackFinalized:)
													 name:kMPCPlayFinalizedNotification object:playerController];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackStopped:)
													 name:kMPCPlayStoppedNotification object:playerController];

	}
}

-(NSArray*) makeFilterChains
{
	CIFilter *colorFilter;
	CIFilter *nrFilter;
	CIFilter *gammaFilter;
	CIFilter *hueFilter;
	
	colorFilter = [CIFilter filterWithName:@"CIColorControls"];
	[colorFilter setName:@"colorFilter"];
	[colorFilter setEnabled:NO];
	
	nrFilter = [CIFilter filterWithName:@"CINoiseReduction"];
	[nrFilter setName:@"nrFilter"];
	[nrFilter setEnabled:NO];
	
	gammaFilter = [CIFilter filterWithName:@"CIGammaAdjust"];
	[gammaFilter setName:@"gammaFilter"];
	[gammaFilter setEnabled:NO];
	
	hueFilter = [CIFilter filterWithName:@"CIHueAdjust"];
	[hueFilter setName:@"hueFilter"];
	[hueFilter setEnabled:NO];
	
	NSDictionary *dict = [ud dictionaryForKey:kUDKeyVTSettings];
	if (dict) {
		[colorFilter setValue:[dict objectForKey:kCILayerBrightnessKeyPath] forKey:kCIInputBrightnessKey];
		[colorFilter setValue:[dict objectForKey:kCILayerSaturationKeyPath] forKey:kCIInputSaturationKey];
		[colorFilter setValue:[dict objectForKey:kCILayerContrastKeyPath] forKey:kCIInputContrastKey];
		[nrFilter setValue:[dict objectForKey:kCILayerNoiseLevelKeyPath] forKey:kCIInputNoiseLevelKey];
		[nrFilter setValue:[dict objectForKey:kCILayerSharpnessKeyPath] forKey:kCIInputSharpnessKey];
		[gammaFilter setValue:[dict objectForKey:kCILayerGammaKeyPath] forKey:kCIInputPowerKey];
		[hueFilter setValue:[dict objectForKey:kCILayerHueAngleKeyPath] forKey:kCIInputAngleKey];
	} else {
		[colorFilter setValue:[NSNumber numberWithDouble:0] forKey:kCIInputBrightnessKey];
		[colorFilter setValue:[NSNumber numberWithDouble:1] forKey:kCIInputSaturationKey];
		[colorFilter setValue:[NSNumber numberWithDouble:1] forKey:kCIInputContrastKey];
		[nrFilter setValue:[NSNumber numberWithDouble:0] forKey:kCIInputNoiseLevelKey];
		[nrFilter setValue:[NSNumber numberWithDouble:0] forKey:kCIInputSharpnessKey];
		[gammaFilter setValue:[NSNumber numberWithDouble:1] forKey:kCIInputPowerKey];
		[hueFilter setValue:[NSNumber numberWithDouble:0] forKey:kCIInputAngleKey];		
	}
	return [NSArray arrayWithObjects:gammaFilter, hueFilter, colorFilter, nrFilter, nil];
}

-(void) loadParameters
{
	// 从UserDefaults读出，加载到modal
	if (layer) {
		NSDictionary *dict = [ud dictionaryForKey:kUDKeyVTSettings];
	
		if (dict) {
			// 有这个UD的话，就读出然后设置Layer
			if (!layer.filters) {
				[layer setFilters:[self makeFilterChains]];
			}
			
			// the "enable Key Path" and "Value Key Path" will all be save into UserDefaults
			for (id keyPath in dict) {
				[layer setValue:[dict objectForKey:keyPath] forKeyPath:keyPath];
			}
		} else {
			// 如果UD没有这个设置，那就重置filters
			layer.filters = nil;
		}
	}
}

-(void) saveParameters
{
	// 从modal读出，保存到UserDefaults
	if (layer) {
		if (layer.filters) {
		
			// 如果filters里面有东西，那就读出来，存到UD里面
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

			NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithCapacity:16];
			
			NSNumber *val = nil;
			NSString *enaStr = nil;
			
			for (NSString *keyPath in enableStrDict) {
				// 先读enabled
				enaStr = [enableStrDict objectForKey:keyPath];
				
				val = [layer valueForKeyPath:enaStr];
				
				if (val) {
					[settings setObject:val forKey:enaStr];
					
					// 有enabled的话，再读具体的数字
					val = [layer valueForKeyPath:keyPath];
					if (val) {
						[settings setObject:val forKey:keyPath];
					}
					// MPLog(@"%@ = %@", keyPath, val);
				} else {
					[settings setObject:[NSNumber numberWithBool:NO] forKey:enaStr];
				}
			}
			
			[ud setObject:settings forKey:kUDKeyVTSettings];
			
			[settings release];
			
			[pool drain];
		} else {
			// 没有filters的话，就什么也不要了
			[ud removeObjectForKey:kUDKeyVTSettings];
		}
	}
}

-(IBAction)showUI:(id)sender
{
	if (!nibLoaded) {
		nibLoaded = YES;
		
		///////////////////////////// 加载bundle /////////////////////////////
		[NSBundle loadNibNamed:@"VideoTuner" owner:self];
		
		[brInc setBordered:NO];
		[brDec setBordered:NO];
		[satInc setBordered:NO];
		[satDec setBordered:NO];
		[conInc setBordered:NO];
		[conDec setBordered:NO];
		[nrInc setBordered:NO];
		[nrDec setBordered:NO];
		[shpInc setBordered:NO];
		[shpDec setBordered:NO];
		[gmInc setBordered:NO];
		[gmDec setBordered:NO];
		[hueInc setBordered:NO];
		[hueDec setBordered:NO];
		
		///////////////////////////// 建立控件之间的连接 /////////////////////////////
		[[sliderBrightness cell] setRepresentedObject:kCILayerBrightnessKeyPath];
		[[sliderSaturation cell] setRepresentedObject:kCILayerSaturationKeyPath];
		[[sliderContrast cell] setRepresentedObject:kCILayerContrastKeyPath];
		[[sliderNR cell] setRepresentedObject:kCILayerNoiseLevelKeyPath];
		[[sliderSharpness cell] setRepresentedObject:kCILayerSharpnessKeyPath];
		[[sliderGamma cell] setRepresentedObject:kCILayerGammaKeyPath];
		[[sliderHue cell] setRepresentedObject:kCILayerHueAngleKeyPath];
		
		[sliderBrightness sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];
		[sliderSaturation sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];
		[sliderContrast sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];
		[sliderNR sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];
		[sliderSharpness sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];
		[sliderGamma sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];
		[sliderHue sendActionOn:NSLeftMouseDownMask|NSLeftMouseDraggedMask];

		[[brInc cell]  setRepresentedObject:sliderBrightness];
		[[brDec cell]  setRepresentedObject:sliderBrightness];
		[[satInc cell] setRepresentedObject:sliderSaturation];
		[[satDec cell] setRepresentedObject:sliderSaturation];
		[[conInc cell] setRepresentedObject:sliderContrast];
		[[conDec cell] setRepresentedObject:sliderContrast];
		[[nrInc cell]  setRepresentedObject:sliderNR];
		[[nrDec cell]  setRepresentedObject:sliderNR];
		[[shpInc cell] setRepresentedObject:sliderSharpness];
		[[shpDec cell] setRepresentedObject:sliderSharpness];
		[[gmInc cell]  setRepresentedObject:sliderGamma];
		[[gmDec cell]  setRepresentedObject:sliderGamma];
		[[hueInc cell] setRepresentedObject:sliderHue];
		[[hueDec cell] setRepresentedObject:sliderHue];

		///////////////////////////// 设定min，max，step /////////////////////////////
		double step, max, min, stepRatio;
		
		stepRatio = [[NSUserDefaults standardUserDefaults] floatForKey:kUDKeyVideoTunerStepValue];
		
		// 这些值是系统默认值，我懒得用代码实现，直接hardcoding了
		/* http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html
		 */

		// kCIInputBrightnessKey
		min = -0.75;
		max = 0.75;
		step = (max - min) * stepRatio;
		[sliderBrightness setMinValue:min];
		[sliderBrightness setMaxValue:max];
		[brInc setTag:((NSInteger)( step*kCIStepBase))];
		[brDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		// kCIInputSaturationKey
		min = 0;
		max = 2;
		step = (max - min) * stepRatio;
		[sliderSaturation setMinValue:min];
		[sliderSaturation setMaxValue:max];
		[satInc setTag:((NSInteger)( step*kCIStepBase))];
		[satDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		// kCIInputContrastKey
		min = 0.25;
		max = 4;
		step = (max - min) * stepRatio;
		[sliderContrast setMinValue:min];
		[sliderContrast setMaxValue:max];
		[conInc setTag:((NSInteger)( step*kCIStepBase))];
		[conDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		// kCIInputNoiseLevelKey
		min = 0;
		max = 0.1;
		step = (max - min) * stepRatio;
		[sliderNR setMinValue:min];
		[sliderNR setMaxValue:max];
		[nrInc setTag:((NSInteger)( step*kCIStepBase))];
		[nrDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		// kCIInputSharpnessKey
		min = 0;
		max = 2;
		step = (max - min) * stepRatio;
		[sliderSharpness setMinValue:min];
		[sliderSharpness setMaxValue:max];
		[shpInc setTag:((NSInteger)( step*kCIStepBase))];
		[shpDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		// kCIInputPowerKey
		min = 0.1;
		max = 3;
		step = (max - min) * stepRatio;
		[sliderGamma setMinValue:min];
		[sliderGamma setMaxValue:max];
		[gmInc setTag:((NSInteger)( step*kCIStepBase))];
		[gmDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		// kCIInputAngleKey
		min = -3.14;
		max = 3.14;
		step = (max - min) * stepRatio;
		[sliderHue setMinValue:min];
		[sliderHue setMaxValue:max];
		[hueInc setTag:((NSInteger)( step*kCIStepBase))];
		[hueDec setTag:((NSInteger)(-step*kCIStepBase))];

		///////////////////////////// 加载 控件的值 /////////////////////////////
		if (layer && layer.filters) {
			// 如果layer有效的话，就从layer加载
			[sliderBrightness setDoubleValue:[[layer valueForKeyPath:kCILayerBrightnessKeyPath] doubleValue]];
			[sliderSaturation setDoubleValue:[[layer valueForKeyPath:kCILayerSaturationKeyPath] doubleValue]];
			[sliderContrast setDoubleValue:[[layer valueForKeyPath:kCILayerContrastKeyPath] doubleValue]];
			[sliderNR setDoubleValue:[[layer valueForKeyPath:kCILayerNoiseLevelKeyPath] doubleValue]];
			[sliderSharpness setDoubleValue:[[layer valueForKeyPath:kCILayerSharpnessKeyPath] doubleValue]];
			[sliderGamma setDoubleValue:[[layer valueForKeyPath:kCILayerGammaKeyPath] doubleValue]];
			[sliderHue setDoubleValue:[[layer valueForKeyPath:kCILayerHueAngleKeyPath] doubleValue]];
		} else {
			// 如果layer还不存在，那就从UD加载
			NSDictionary *dict = [ud dictionaryForKey:kUDKeyVTSettings];

			if (dict) {
				[sliderBrightness setDoubleValue:[[dict objectForKey:kCILayerBrightnessKeyPath] doubleValue]];
				[sliderSaturation setDoubleValue:[[dict objectForKey:kCILayerSaturationKeyPath] doubleValue]];
				[sliderContrast setDoubleValue:[[dict objectForKey:kCILayerContrastKeyPath] doubleValue]];
				[sliderNR setDoubleValue:[[dict objectForKey:kCILayerNoiseLevelKeyPath] doubleValue]];
				[sliderSharpness setDoubleValue:[[dict objectForKey:kCILayerSharpnessKeyPath] doubleValue]];
				[sliderGamma setDoubleValue:[[dict objectForKey:kCILayerGammaKeyPath] doubleValue]];
				[sliderHue setDoubleValue:[[dict objectForKey:kCILayerHueAngleKeyPath] doubleValue]];
			} else {
				// 这些值是系统默认值，我懒得用代码实现，直接hardcoding了，正轨途径应该使用kCIAttributeIdentity
				/* http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html
				 */
				[sliderBrightness setDoubleValue:0.00];
				[sliderSaturation setDoubleValue:1.00];
				[sliderContrast setDoubleValue:1.00];
				[sliderNR setDoubleValue:0.00];
				[sliderSharpness setDoubleValue:0.00];
				[sliderGamma setDoubleValue:1.00];
				[sliderHue setDoubleValue:0.00];
			}
		}

		[VTWin setLevel:NSMainMenuWindowLevel];
	}
	
	if ([VTWin isVisible]) {
		[VTWin orderOut:self];
	} else {
		[VTWin orderFront:self];
	}
}

-(void) resetFilters:(id)sender
{
	if (layer) {
		// 实现Lazy loading
		layer.filters = nil;
	}
	
	[ud removeObjectForKey:kUDKeyVTSettings];
	
	if (nibLoaded) {
		[sliderBrightness setDoubleValue:0.00];
		[sliderSaturation setDoubleValue:1.00];
		[sliderContrast setDoubleValue:1.00];
		[sliderNR setDoubleValue:0.00];
		[sliderSharpness setDoubleValue:0.00];
		[sliderGamma setDoubleValue:1.00];
		[sliderHue setDoubleValue:0.00];
	}
}

-(IBAction) setFilterParameters:(id)sender
{
	if (layer) {
		// Lazy loading
		if (!layer.filters) {
			[layer setFilters:[self makeFilterChains]];
		}
		
		NSString *keyPath = [[sender cell] representedObject];
		NSString *enaStr = [enableStrDict objectForKey:keyPath];
		
		if (![[layer valueForKeyPath:enaStr] boolValue]) {
			[layer setValue:[NSNumber numberWithBool:YES] forKeyPath:enaStr];
		}

		[layer setValue:[NSNumber numberWithDouble:[sender doubleValue]] forKeyPath:keyPath];
		//MPLog(@"%@=%f", [[sender cell] representedObject], [sender doubleValue]);
		
		[self saveParameters];
	}
}

-(IBAction) stepFilterParameters:(id)sender
{
	// 得到Slider
	NSSlider *obj = [[sender cell] representedObject];
	
	[obj setFloatValue:[obj floatValue] + (((float)[sender tag])/kCIStepBase)];

	[self setFilterParameters:obj];
}

-(void) setLayer:(CALayer*)l
{
	if (layer) {
		[layer setFilters:nil];
	}
	layer = l;

	[self loadParameters];
}

-(void) playBackStopped:(NSNotification*)notif
{
	if ([ud integerForKey:kUDKeyAutoSaveVTSettings] == kAutoSaveVTSettingsLifeNone) {
		// 播放停止，但是不知道是不是APN
		// 因此只有在 总是reset 的时候reset
		[self resetFilters:nil];
	}
}

-(void) playBackFinalized:(NSNotification*)notif
{
	if ([ud integerForKey:kUDKeyAutoSaveVTSettings] == kAutoSaveVTSettingsLifeAPN) {
		// 在 非APN的时候reset选项时
		// 因为 APN的话，是不会有Finalized的notification
		// 因此只要收到这个notification就可以reset
		[self resetFilters:nil];
	}
}

@end
