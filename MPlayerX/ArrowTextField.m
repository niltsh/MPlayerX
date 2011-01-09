/*
 * MPlayerX - ArrowTextField.m
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

#import "ArrowTextField.h"


@implementation ArrowTextField

@synthesize stepValue;

-(id) init
{
	self = [super init];
	
	if (self) {
		stepValue = 0;
	}
	return self;
}

-(BOOL) textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	// When use up/down arrow, to step the value
	if (aSelector == @selector(moveUp:)) {
		[self setFloatValue: [self floatValue] + stepValue];
		[self.target performSelector: self.action withObject: self];
		return YES;
	}
	else if (aSelector == @selector(moveDown:)) {
		[self setFloatValue: [self floatValue] - stepValue];
		[self.target performSelector: self.action withObject: self];
		return YES;
	}
	return [self tryToPerform:aSelector with:aTextView];
}
@end
