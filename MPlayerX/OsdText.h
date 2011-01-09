/*
 * MPlayerX - OsdText.h
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

typedef enum
{
	kOSDOwnerTime = 1,
	kOSDOwnerOther = 2
} OSDOWNER;

@interface OsdText : NSTextField
{
	NSUserDefaults *ud;

	BOOL active;
	BOOL shouldHide;
	NSColor *frontColor;
	NSShadow *shadow;
	
	OSDOWNER owner;
	
	float fontSizeMax;
	float fontSizeMin;
	float fontSizeRatio;
	float fontSizeOffset;

	NSTimer *autoHideTimer;
	NSTimeInterval autoHideTimeInterval;
}

@property (assign, readwrite, getter=isActive) BOOL active;
@property (readonly) OSDOWNER owner;
@property (retain, readwrite) NSColor *frontColor;

-(void) setAutoHideTimeInterval:(NSTimeInterval)ti;
-(void) setStringValue:(NSString *)aString owner:(OSDOWNER)ow updateTimer:(BOOL)ut;

@end
