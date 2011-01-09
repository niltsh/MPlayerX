/*
 * MPlayerX - EqualizerController.h
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

@class PlayerController;

@interface EqualizerController : NSObject
{
	BOOL nibLoaded;
	NSArray *bars;
	
	IBOutlet PlayerController *playerController;
	
	IBOutlet NSPanel *EQPanel;
	IBOutlet NSMenuItem *menuEQPanel;
	IBOutlet NSSlider *sli30;
	IBOutlet NSSlider *sli60;
	IBOutlet NSSlider *sli125;
	IBOutlet NSSlider *sli250;
	IBOutlet NSSlider *sli500;
	IBOutlet NSSlider *sli1k;
	IBOutlet NSSlider *sli2k;
	IBOutlet NSSlider *sli4k;
	IBOutlet NSSlider *sli8k;
	IBOutlet NSSlider *sli16k;
}

-(IBAction) showUI:(id)sender;
-(IBAction) setEqualizer:(id)sender;
-(IBAction) resetEqualizer:(id)sender;

@end
