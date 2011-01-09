/*
 * MPlayerX - TitleView.m
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

#import "TitleView.h"
#import "CocoaAppendix.h"

static NSString * const kStringDots = @"...";
static NSRect trackRect;

@implementation TitleView

@synthesize title;

+(void) initialize
{
	trackRect = NSMakeRect(0, 0, 70, 23);
}

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
    if (self) {
		title = nil;
		titleAttr = [[NSDictionary alloc]
					 initWithObjectsAndKeys:
					 [NSColor whiteColor], NSForegroundColorAttributeName,
					 [NSFont titleBarFontOfSize:12], NSFontAttributeName,
					 nil];

		tbCornerLeft	= [[NSImage imageNamed:@"titlebar-corner-left.png"] retain];
		tbCornerRight	= [[NSImage imageNamed:@"titlebar-corner-right.png"] retain];
		tbMiddle		= [[NSImage imageNamed:@"titlebar-middle.png"] retain];

		imgCloseActive	 = [[NSImage imageNamed:@"close-active.tiff"] retain];
		imgCloseInactive = [[NSImage imageNamed:@"close-inactive-disabled.tiff"] retain];
		imgCloseRollover = [[NSImage imageNamed:@"close-rollover.tiff"] retain];
		
		imgMiniActive	 = [[NSImage imageNamed:@"minimize-active.tiff"] retain];
		imgMiniInactive	 = [[NSImage imageNamed:@"minimize-inactive-disabled.tiff"] retain];
		imgMiniRollover	 = [[NSImage imageNamed:@"minimize-rollover.tiff"] retain];
		
		imgZoomActive	 = [[NSImage imageNamed:@"zoom-active.tiff"] retain];
		imgZoomInactive	 = [[NSImage imageNamed:@"zoom-inactive-disabled.tiff"] retain];
		imgZoomRollover	 = [[NSImage imageNamed:@"zoom-rollover.tiff"] retain];

		closeButton = [[NSButton alloc] initWithFrame:NSMakeRect( 4, 0, 22, 22)];
		miniButton  = [[NSButton alloc] initWithFrame:NSMakeRect(25, 0, 22, 22)];
		zoomButton  = [[NSButton alloc] initWithFrame:NSMakeRect(46, 0, 22, 22)];
		
		[closeButton setButtonType:NSSwitchButton];
		[closeButton setImage:imgCloseActive];
		[closeButton setImagePosition:NSImageOnly];
		[closeButton setBordered:NO];		
		[closeButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
		[closeButton setContinuous:NO];

		[miniButton setButtonType:NSSwitchButton];
		[miniButton setImage:imgMiniActive];
		[miniButton setImagePosition:NSImageOnly];
		[miniButton setBordered:NO];
		[miniButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
		[miniButton setContinuous:NO];
		
		[zoomButton setButtonType:NSSwitchButton];
		[zoomButton setImage:imgZoomActive];
		[zoomButton setImagePosition:NSImageOnly];
		[zoomButton setBordered:NO];
		[zoomButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
		[zoomButton setContinuous:NO];
		
		mouseEntered = NO;
	}
    return self;
}

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[title release];
	[titleAttr release];
	
	[closeButton release];
	[miniButton release];
	[zoomButton release];
	
	[tbCornerLeft release];
	[tbCornerRight release];
	[tbMiddle release];
	
	[imgCloseActive release];
	[imgCloseInactive release];
	[imgCloseRollover release];
	
	[imgMiniActive release];
	[imgMiniInactive release];
	[imgMiniRollover release];
	
	[imgZoomActive release];
	[imgZoomInactive release];
	[imgZoomRollover release];

	[super dealloc];
}

-(void) awakeFromNib
{
	[self addSubview:closeButton];
	[self addSubview:miniButton];
	[self addSubview:zoomButton];
	
	[closeButton setTarget:[self window]];
	[miniButton setTarget:[self window]];
	[zoomButton setTarget:[self window]];
	
	[closeButton setAction:@selector(performClose:)];
	[miniButton setAction:@selector(performMiniaturize:)];
	[zoomButton setAction:@selector(performZoom:)];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidBecomKey:)
												 name:NSWindowDidBecomeKeyNotification
											   object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidResignKey:)
												 name:NSWindowDidResignKeyNotification
											   object:[self window]];
}

-(BOOL) acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL) acceptsFirstResponder { return YES; }

-(void) mouseUp:(NSEvent *)theEvent
{
	if ([theEvent clickCount] == 2) {
		[[self window] performMiniaturize:self];
	}
}

-(void) mouseMoved:(NSEvent *)theEvent
{
	BOOL mouseIn = NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], trackRect);
	
	if (mouseIn != mouseEntered) {
		// 状态发生变化
		mouseEntered = mouseIn;
		
		if (mouseEntered) {
			// entered
			[closeButton setImage:imgCloseRollover];
			[miniButton setImage:imgMiniRollover];
			[zoomButton setImage:imgZoomRollover];			
		} else {
			// exited
			if ([[self window] isKeyWindow]) {
				[closeButton setImage:imgCloseActive];
				[miniButton setImage:imgMiniActive];
				[zoomButton setImage:imgZoomActive];
			} else {
				[closeButton setImage:imgCloseInactive];
				[miniButton setImage:imgMiniInactive];
				[zoomButton setImage:imgZoomInactive];				
			}
		}
	}
}

- (void)drawRect:(NSRect)dirtyRect
{	
	NSSize leftSize = [tbCornerLeft size];
	NSSize rightSize = [tbCornerRight size];
	NSSize titleSize = [self bounds].size;
	NSPoint drawPos;
	
	drawPos.x = 0;
	drawPos.y = 0;
	
	dirtyRect.origin.x = 0;
	dirtyRect.origin.y = 0;

	dirtyRect.size = leftSize;
	[tbCornerLeft drawAtPoint:drawPos fromRect:dirtyRect operation:NSCompositeCopy fraction:1.0];
	
	drawPos.x = titleSize.width - rightSize.width;
	dirtyRect.size = rightSize;
	[tbCornerRight drawAtPoint:drawPos fromRect:dirtyRect operation:NSCompositeCopy fraction:1.0];
	
	dirtyRect.size = [tbMiddle size];
	[tbMiddle drawInRect:NSMakeRect(leftSize.width, 0, titleSize.width-leftSize.width-rightSize.width, titleSize.height)
				fromRect:dirtyRect
			   operation:NSCompositeCopy
				fraction:1.0];

	if (title) {
		NSMutableString *renderStr = [title mutableCopy];
		NSSize dotSize = [kStringDots sizeWithAttributes:titleAttr];
		NSSize strSize = [renderStr sizeWithAttributes:titleAttr];
		float widthMax = titleSize.width - 80;
		
		if (strSize.width > widthMax) {
			// the title less than 3 characters should be never longer than widMax,
			// so it is safe to delete the first three chars, without checking
			[renderStr deleteCharactersInRange:NSMakeRange(0, 2)];
			
			while (dotSize.width + strSize.width > widthMax) {
				[renderStr deleteCharactersInRange:NSMakeRange(0, 1)];
				strSize = [renderStr sizeWithAttributes:titleAttr];
			}
			[renderStr insertString:kStringDots	atIndex:0];
		}

		dirtyRect.size = [renderStr sizeWithAttributes:titleAttr];
		
		drawPos.x = MAX(70, (titleSize.width -dirtyRect.size.width)/2);
		drawPos.y = (titleSize.height - dirtyRect.size.height)/2;
		
		[renderStr drawAtPoint:drawPos withAttributes:titleAttr];
		[renderStr release];
	}
}

-(void) windowDidBecomKey:(NSNotification*) notif
{
	[closeButton setImage:imgCloseActive];
	[miniButton setImage:imgMiniActive];
	[zoomButton setImage:imgZoomActive];
}

-(void) windowDidResignKey:(NSNotification*) notif
{
	[closeButton setImage:imgCloseInactive];
	[miniButton setImage:imgMiniInactive];
	[zoomButton setImage:imgZoomInactive];
}

@end
