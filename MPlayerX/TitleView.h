/*
 * MPlayerX - TitleView.h
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


@interface TitleView : NSVisualEffectView
{
	NSButton *closeButton;
	NSButton *miniButton;
	NSButton *zoomButton;
	NSButton *fsButton;
	
	NSImage *tbCornerLeft;
	NSImage *tbCornerRight;
	NSImage *tbMiddle;

	NSString *title;
	NSDictionary *titleAttr;
	
	BOOL mouseInside;
}

@property(retain, readwrite) NSString *title;

@property(readonly) NSButton *closeButton;
@property(readonly) NSButton *miniButton;
@property(readonly) NSButton *zoomButton;

-(void) resetPosition;
-(BOOL) allowsVibrancy;
-(void) resetButtons;
@end
