/*
 * MPlayerX - HueSliderCell.m
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

#import "HueSliderCell.h"

@implementation HueSliderCell

-(id)init {
	
	self = [super init];
	
	if(self) {
		hueGradient = [[NSGradient alloc] 
					   initWithColors:[NSArray arrayWithObjects:
									   [NSColor cyanColor], [NSColor blueColor], [NSColor magentaColor], [NSColor redColor],
									   [NSColor yellowColor], [NSColor greenColor], [NSColor cyanColor], nil]];
	}
	
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	
	self = [super initWithCoder: aDecoder];
	
	if(self) {
		
		if([aDecoder containsValueForKey: @"themeKey"]) {
			
			hueGradient = [aDecoder decodeObjectForKey:@"themeKey"];
			
		} else {
			hueGradient = [[NSGradient alloc] 
						   initWithColors:[NSArray arrayWithObjects:
										   [NSColor cyanColor], [NSColor blueColor], [NSColor magentaColor], [NSColor redColor],
										   [NSColor yellowColor], [NSColor greenColor], [NSColor cyanColor], nil]];
		}		
	}
	
	return self;
}

-(void)encodeWithCoder: (NSCoder *)coder {
	
	[super encodeWithCoder: coder];
	[coder encodeObject: hueGradient forKey: @"themeKey"];
}

-(void)dealloc {
	
	[hueGradient release];

	[super dealloc];
}

- (void)drawHorizontalBarInFrame:(NSRect)frame {

	
	// Adjust frame based on ControlSize
	switch ([self controlSize]) {
			
		case NSRegularControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				if([self tickMarkPosition] == NSTickMarkBelow) {
					
					frame.origin.y += 4;
				} else {
					
					frame.origin.y += frame.size.height - 10;
				}
			} else {
				
				frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2.5f);
			}
			
			frame.origin.x += 2.5f;
			frame.origin.y += 0.5f;
			frame.size.width -= 5;
			frame.size.height = 5;
			break;
			
		case NSSmallControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				if([self tickMarkPosition] == NSTickMarkBelow) {
					
					frame.origin.y += 2;
				} else {
					
					frame.origin.y += frame.size.height - 8;
				}
			} else {
				
				frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2.5f);
			}
			
			frame.origin.x += 0.5f;
			frame.origin.y += 0.5f;
			frame.size.width -= 1;
			frame.size.height = 5;
			break;
			
		case NSMiniControlSize:
			
			if([self numberOfTickMarks] != 0) {
				
				if([self tickMarkPosition] == NSTickMarkBelow) {
					
					frame.origin.y += 2;
				} else {
					
					frame.origin.y += frame.size.height - 6;
				}
			} else {
				
				frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2);
			}
			
			frame.origin.x += 0.5f;
			frame.origin.y += 0.5f;
			frame.size.width -= 1;
			frame.size.height = 3;
			break;
	}
	
	//Draw Bar
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: frame xRadius: 2 yRadius: 2];
	
	[hueGradient drawInBezierPath:path angle:0.0];
	if([self isEnabled]) {
		
		// [[[[BGThemeManager keyedManager] themeForKey: self.themeKey] sliderTrackColor] set];
		// [path fill];
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
		[path stroke];
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledSliderTrackColor] set];
		[path fill];
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledStrokeColor] set];
		[path stroke];
	}
}
@end
