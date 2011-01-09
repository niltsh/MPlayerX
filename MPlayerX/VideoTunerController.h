/*
 * MPlayerX - VideoTunerController.h
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

@interface VideoTunerController : NSObject
{
	BOOL nibLoaded;
	
	CIFilter *colorFilter;
	CIFilter *nrFilter;
	CIFilter *gammaFilter;
	CIFilter *hueFilter;

	CALayer *layer;

	IBOutlet NSWindow *VTWin;
	IBOutlet NSSlider *sliderBrightness;
	IBOutlet NSSlider *sliderSaturation;
	IBOutlet NSSlider *sliderContrast;
	IBOutlet NSSlider *sliderNR;
	IBOutlet NSSlider *sliderSharpness;
	IBOutlet NSSlider *sliderGamma;
	IBOutlet NSSlider *sliderHue;
	
	IBOutlet NSButton *brInc;
	IBOutlet NSButton *brDec;
	IBOutlet NSButton *satInc;
	IBOutlet NSButton *satDec;
	IBOutlet NSButton *conInc;
	IBOutlet NSButton *conDec;
	IBOutlet NSButton *nrInc;
	IBOutlet NSButton *nrDec;
	IBOutlet NSButton *shpInc;
	IBOutlet NSButton *shpDec;
	IBOutlet NSButton *gmInc;
	IBOutlet NSButton *gmDec;
	IBOutlet NSButton *hueInc;
	IBOutlet NSButton *hueDec;

	IBOutlet NSMenuItem *menuVTPanel;
}

-(void) setLayer:(CALayer*)l;

-(IBAction) showUI:(id)sender;

-(void) resetFilters:(id)sender;

-(IBAction) setFilterParameters:(id)sender;

-(IBAction) stepFilterParameters:(id)sender;
@end
