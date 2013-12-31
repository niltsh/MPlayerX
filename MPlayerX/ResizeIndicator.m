/*
 * MPlayerX - ResizeIndicator.m
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

#import "ResizeIndicator.h"


@implementation ResizeIndicator

-(void) awakeFromNib
{
	im = [[NSImage imageNamed: @"resizeindicator"] retain];
	imRect = NSMakeRect(0, 0, [im size].width, [im size].height);
}

- (void)drawRect:(NSRect)dirtyRect
{
	// 让图片画在view的右下角
	[im drawAtPoint:NSMakePoint([self bounds].size.width - imRect.size.width, 0) fromRect:imRect operation:NSCompositeSourceOver fraction:1];
}

- (void)dealloc {
  [im release];
  [super dealloc];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event 
{ return YES; }

@end
