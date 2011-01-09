/*
 * MPlayerX - PlayerWindow.m
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

#import "PlayerWindow.h"
#import "TitleView.h"

@implementation PlayerWindow

-(id) initWithContentRect:(NSRect)contentRect 
				styleMask:(NSUInteger)aStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)flag
{
	
	self = [super initWithContentRect:contentRect
							styleMask:NSBorderlessWindowMask
							  backing:bufferingType
								defer:flag];
	if (self) {
	}
	return self;
}

-(void) awakeFromNib
{
	[self setHasShadow:YES];
	[self setCollectionBehavior:NSWindowCollectionBehaviorManaged];
	
	[self setContentMinSize:NSMakeSize(480, 360)];
	[self setContentSize:NSMakeSize(480, 360)];

	NSRect scrnRC = [[self screen] frame];
	NSRect winRC  = [self frame];
	winRC.origin.x = (scrnRC.size.width - winRC.size.width) / 2;
	winRC.origin.y = (scrnRC.size.height-winRC.size.height) / 2;
	[self setFrameOrigin:winRC.origin];
}

-(BOOL) canBecomeKeyWindow { return YES;}
-(BOOL) canBecomeMainWindow { return YES;}
-(BOOL) acceptsFirstResponder { return YES; }

-(void) setTitle:(NSString *)aString
{
	[titlebar setTitle:aString];
	[titlebar setNeedsDisplay:YES];
}

-(BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
	if ((action == @selector(performClose:)) ||
		(action == @selector(performMiniaturize:)) ||
		(action == @selector(performZoom:))) {
		return YES;
	}
	return YES;
}

-(void) performZoom:(id)sender
{
	[self zoom:sender];
}

-(void) performMiniaturize:(id)sender
{
	[self miniaturize:sender];
}

-(void) performClose:(id)sender
{
	[self close];
}
@end
