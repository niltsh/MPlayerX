/*
 * MPlayerX - TimeSliderCell.m
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
			
			frame.origin.x += 6.0f;
			frame.origin.y -= 2.0f;
			frame.size.width -= 12.0f;
			frame.size.height = 8.0f;
			break;
		default:
			[super drawHorizontalBarInFrame:frame];
			return;
	}
	
	//Draw Bar
	NSBezierPath *path = [[NSBezierPath alloc] init];
	
	[path appendBezierPathWithRoundedRect:frame xRadius:4 yRadius:4];
	
	if([self isEnabled]) {
		[[NSColor colorWithDeviceWhite:0.04 alpha:0.20] set];
		[path fill];
		
		[[NSColor colorWithDeviceWhite:0.50 alpha:0.20] set];
		[path stroke];
	} else {
		[[NSColor colorWithDeviceWhite:0.04 alpha:0.20] set];
		[path fill];
	}
	[path release];
}

#define TIMESLIDER_EFFECTIVE_X_OFFSET       (7.0f)
#define TIMESLIDER_EFFECTIVE_WIDTH_OFFSET   (14.0f)

- (void)drawHorizontalKnobInFrame:(NSRect)frame {
	
	NSRect rcBounds = [[self controlView] bounds];
	NSBezierPath *path = nil, *dot = nil;
    NSRect dotRc;
	
	switch ([self controlSize]) {
			
		case NSSmallControlSize:
            // 这里为什么要将画界面的区域缩小，
            // 如果不缩小的话，通过slider得到的floatValue和实际绘画的区域对不上
            // 也就是说，实际上floatValue的取值是考虑了一定的margin得到的值
            // 绘画的时候要考虑到这部分margin进行绘画
			rcBounds.origin.y = rcBounds.origin.y + (((rcBounds.origin.y + rcBounds.size.height) /2) - 2.5f);
			rcBounds.origin.x += TIMESLIDER_EFFECTIVE_X_OFFSET;
			rcBounds.origin.y -= 2.0f;
			rcBounds.size.width -= TIMESLIDER_EFFECTIVE_WIDTH_OFFSET;
			rcBounds.size.height = 8.0f;

            if ([self maxValue]) {
                rcBounds.size.width *= ([self floatValue]/[self maxValue]);
                rcBounds.size.width = MAX(rcBounds.size.width, 1);
            } else {
                rcBounds.size.width = 1.0;
            }

			path = [[NSBezierPath alloc] init];
			[path appendBezierPathWithRoundedRect:rcBounds xRadius:4 yRadius:4];

			if([self isEnabled]) {
				[[NSColor colorWithDeviceWhite:0.96 alpha:1.0] set];
			} else {
				[[NSColor colorWithDeviceWhite:0.3 alpha:1.0] set];
			}
            [path fill];

			[[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
			[path stroke];
			[path release];

            dotRc = NSMakeRect(rcBounds.size.width - 0.5, rcBounds.origin.y + 2.0, 4, 4);

            if (dotRc.origin.x >= 5.5f) {
                dot  = [[NSBezierPath alloc] init];
                [dot appendBezierPathWithOvalInRect:dotRc];
                [[NSColor blackColor] set];
                [dot fill];
                [dot release];
            }
            
			break;
		default:
			[super drawHorizontalKnobInFrame:frame];
			break;
	}
}

-(NSRect) effectiveRect
{
    NSRect ret = [[self controlView] frame];
    ret.origin.x += TIMESLIDER_EFFECTIVE_X_OFFSET;
    ret.size.width -= TIMESLIDER_EFFECTIVE_WIDTH_OFFSET;
    return ret;
}
@end
