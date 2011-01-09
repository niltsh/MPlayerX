/*
 * MPlayerX - TimeSliderCell.m
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

#import "TimeSliderCell.h"
#import "CocoaAppendix.h"

@implementation TimeSliderCell

@synthesize dragging;

-(id) initWithCoder:(NSCoder*) decoder
{
	self = [super initWithCoder:decoder];
	
	if (self) {
		dragging = NO;
		dragState = kTSDragStopped;
	}
	return self;
}

-(BOOL) startTrackingAt:(NSPoint)startPoint inView:(NSView*)controlView
{
	// MPLog(@"Start Trackinng");
	dragState = kTSDragStarted;
	
	return [super startTrackingAt:startPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	// MPLog(@"Stop Tracking\n");
	dragState = kTSDragStopped;
	
	[super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];	
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
	// MPLog(@"Conti Tracking\n");
	switch (dragState) {
		// stopped
		case kTSDragStopped:
			dragging = NO;
			break;
		// started
		case kTSDragStarted:
			dragState = kTSDragContinue;
			break;
		// continue
		default:
			dragging = YES;
			break;
	}
	
	return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
	
	if([self sliderType] == NSLinearSlider) {
		
		if(![self isVertical]) {
		
			[self drawHorizontalBarInFrame: aRect];
			return;
		} else {
			// [self drawVerticalBarInFrame: aRect];
		}
	} else {
		//Placeholder for when I figure out how to draw NSCircularSlider
	}
	[super drawBarInside:aRect flipped:flipped];
}

- (void)drawKnob:(NSRect)aRect {
	
	if([self sliderType] == NSLinearSlider) {
		
		if(![self isVertical]) {
			
			[self drawHorizontalKnobInFrame: aRect];
			return;
		} else {
			// [self drawVerticalKnobInFrame: aRect];
		}
	} else {
		//Place holder for when I figure out how to draw NSCircularSlider
	}
	[super drawKnob:aRect];
}

- (void)drawHorizontalBarInFrame:(NSRect)frame {
	
	// Adjust frame based on ControlSize
	switch ([self controlSize]) {
			
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
			frame.origin.y -= 2.0f;
			frame.size.width -= 1.0f;
			frame.size.height = 8.0f;
			break;
		default:
			[super drawHorizontalBarInFrame:frame];
			return;
	}
	
	//Draw Bar
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:4 yRadius:4];
	
	if([self isEnabled]) {
		[[NSColor colorWithDeviceWhite:0.04 alpha:0.20] set];
		[path fill];
		
		[[NSColor colorWithDeviceWhite:0.50 alpha:0.20] set];
		[path stroke];
	} else {
		[[NSColor colorWithDeviceWhite:0.04 alpha:0.20] set];
		[path fill];
	}
}

- (void)drawHorizontalKnobInFrame:(NSRect)frame {
	
	NSRect rcBounds = [[self controlView] bounds];
	NSBezierPath *path, *dot;
	
	switch ([self controlSize]) {
			
		case NSSmallControlSize:
			rcBounds.origin.y = rcBounds.origin.y + (((rcBounds.origin.y + rcBounds.size.height) /2) - 2.5f);
			rcBounds.origin.x += 0.5f;
			rcBounds.origin.y -= 2.0f;
			rcBounds.size.width -= 0.5f;
			rcBounds.size.height = 8.0f;
			
			rcBounds.size.width *= ([self floatValue]/[self maxValue]);
			
			path = [NSBezierPath bezierPathWithRoundedRect:rcBounds xRadius:4 yRadius:4];
			dot  = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(rcBounds.size.width - 6, rcBounds.origin.y + 2.0, 4, 4)];
			
			if([self isEnabled]) {
				[[NSColor colorWithDeviceWhite:0.96 alpha:1.0] set];
				[path fill];
			} else {
				[[NSColor colorWithDeviceWhite:0.3 alpha:1.0] set];
				[path fill];
			}
				
			[[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
			[path stroke];
			
			[[NSColor blackColor] set];
			[dot fill];
			break;
		default:
			[super drawHorizontalKnobInFrame:frame];
			break;
	}
}
@end
