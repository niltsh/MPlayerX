/*
 * MPlayerX - PrefController.h
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

@class PlayerController, RootLayerView, ControlUIView;

@interface PrefController : NSObject
{
	NSUserDefaults *ud;

	BOOL nibLoaded;
	NSArray *prefViews;
	
	IBOutlet NSWindow *prefWin;
	IBOutlet NSToolbar *prefToolbar;
	
	IBOutlet NSView *viewGeneral;
	IBOutlet NSView *viewVideo;
	IBOutlet NSView *viewAudio;
	IBOutlet NSView *viewSub;
	IBOutlet NSView *viewNetwork;
	IBOutlet NSView *viewAdvanced;
	
    IBOutlet PlayerController *playerController;
    IBOutlet RootLayerView *dispView;
	IBOutlet ControlUIView *controlUI;
	IBOutlet NSPopUpButton *charsetListPopup;
}

-(IBAction) showUI:(id)sender;
-(IBAction) switchViews:(id)sender;

-(IBAction) multiThreadChanged:(id)sender;
-(IBAction) onTopModeChanged:(id)sender;
-(IBAction) controlUIAppearanceChanged:(id)sender;
-(IBAction) osdSetChanged:(id)sender;
-(IBAction) checkCacheFormat:(id)sender;
-(IBAction) letterBoxModeChanged:(id)sender;
-(IBAction) subEncodingSchemeChanged:(id)sender;

@end
