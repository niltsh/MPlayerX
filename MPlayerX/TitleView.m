/*
 * MPlayerX - TitleView.m
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

#import "TitleView.h"
#import "CocoaAppendix.h"
#import "MPXWindowButton.h"

static NSString * const kStringDots = @"...";
static NSRect trackRect;

@interface TitleView (TitleViewInternal)
-(void) windowDidBecomKey:(NSNotification*) notif;
-(void) windowDidResignKey:(NSNotification*) notif;
@end

@implementation TitleView

@synthesize title;
@synthesize closeButton;
@synthesize miniButton;
@synthesize zoomButton;

+(void) initialize
{
	trackRect = NSMakeRect(0, 0, 70, 23);
}

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
    if (self) {
		// [[NSUserDefaults standardUserDefaults] addSuiteNamed:NSGlobalDomain];

		title = nil;
		titleAttr = [[NSDictionary alloc]
					 initWithObjectsAndKeys:
					 [NSColor whiteColor], NSForegroundColorAttributeName,
					 [NSFont titleBarFontOfSize:0], NSFontAttributeName,
					 nil];

		tbCornerLeft	= [[NSImage imageNamed:@"titlebar-corner-left"] retain];
		tbCornerRight	= [[NSImage imageNamed:@"titlebar-corner-right"] retain];
		tbMiddle		= [[NSImage imageNamed:@"titlebar-middle"] retain];

		if (MPXGetSysVersion() < kMPXSysVersionLion) {
			// in snow leopard
			if ([[NSUserDefaults standardUserDefaults] integerForKey:@"AppleAquaColorVariant"] == 6) {
				imgCloseActive	 = [[NSImage imageNamed:@"close-active-graphite.tiff"] retain];
				imgCloseInactive = [[NSImage imageNamed:@"close-inactive-disabled-graphite.tiff"] retain];
				imgCloseRollover = [[NSImage imageNamed:@"close-rollover-graphite.tiff"] retain];
				
				imgMiniActive	 = [[NSImage imageNamed:@"minimize-active-graphite.tiff"] retain];
				imgMiniInactive	 = [[NSImage imageNamed:@"minimize-inactive-disabled-graphite.tiff"] retain];
				imgMiniRollover	 = [[NSImage imageNamed:@"minimize-rollover-graphite.tiff"] retain];
				
				imgZoomActive	 = [[NSImage imageNamed:@"zoom-active-graphite.tiff"] retain];
				imgZoomInactive	 = [[NSImage imageNamed:@"zoom-inactive-disabled-graphite.tiff"] retain];
				imgZoomRollover	 = [[NSImage imageNamed:@"zoom-rollover-graphite.tiff"] retain];	
			} else {
				imgCloseActive	 = [[NSImage imageNamed:@"close-active.tiff"] retain];
				imgCloseInactive = [[NSImage imageNamed:@"close-inactive-disabled.tiff"] retain];
				imgCloseRollover = [[NSImage imageNamed:@"close-rollover.tiff"] retain];
				
				imgMiniActive	 = [[NSImage imageNamed:@"minimize-active.tiff"] retain];
				imgMiniInactive	 = [[NSImage imageNamed:@"minimize-inactive-disabled.tiff"] retain];
				imgMiniRollover	 = [[NSImage imageNamed:@"minimize-rollover.tiff"] retain];
				
				imgZoomActive	 = [[NSImage imageNamed:@"zoom-active.tiff"] retain];
				imgZoomInactive	 = [[NSImage imageNamed:@"zoom-inactive-disabled.tiff"] retain];
				imgZoomRollover	 = [[NSImage imageNamed:@"zoom-rollover.tiff"] retain];	
			}
			
			fsButton = nil;
			imgFSActive = nil;
			imgFSRollver = nil;
		} else {
			// in lion
			if ([[NSUserDefaults standardUserDefaults] integerForKey:@"AppleAquaColorVariant"] == 6) {
				// graphite theme
				imgCloseActive   = [[NSImage imageNamed:@"close-active-graphite-lion"] retain];
				imgCloseInactive = [[NSImage imageNamed:@"close-inactive-disabled-graphite-lion"] retain];
				imgCloseRollover = [[NSImage imageNamed:@"close-rollover-graphite-lion"] retain];
				
				imgMiniActive	= [[NSImage imageNamed:@"minimize-active-graphite-lion"] retain];
				imgMiniInactive = [[NSImage imageNamed:@"minimize-inactive-disabled-graphite-lion"] retain];
				imgMiniRollover = [[NSImage imageNamed:@"minimize-rollover-graphite-lion"] retain];
				
				imgZoomActive	= [[NSImage imageNamed:@"zoom-active-graphite-lion"] retain];
				imgZoomInactive = [[NSImage imageNamed:@"zoom-inactive-disabled-graphite-lion"] retain];
				imgZoomRollover = [[NSImage imageNamed:@"zoom-rollover-graphite-lion"] retain];
			} else {
				imgCloseActive	 = [[NSImage imageNamed:@"close-active-lion"] retain];
				imgCloseInactive = [[NSImage imageNamed:@"close-inactive-disabled-lion"] retain];
				imgCloseRollover = [[NSImage imageNamed:@"close-rollover-lion"] retain];
				
				imgMiniActive	 = [[NSImage imageNamed:@"minimize-active-lion"] retain];
				imgMiniInactive	 = [[NSImage imageNamed:@"minimize-inactive-disabled-lion"] retain];
				imgMiniRollover	 = [[NSImage imageNamed:@"minimize-rollover-lion"] retain];
				
				imgZoomActive	 = [[NSImage imageNamed:@"zoom-active-lion"] retain];
				imgZoomInactive	 = [[NSImage imageNamed:@"zoom-inactive-disabled-lion"] retain];
				imgZoomRollover	 = [[NSImage imageNamed:@"zoom-rollover-lion"] retain];
			}
			// read the image
			imgFSActive = [[NSImage imageNamed:@"fullscreen-active-lion"] retain];
			imgFSRollver = [[NSImage imageNamed:@"fullscreen-rollover-lion"] retain];
			// 
			fsButton = [[MPXWindowButton alloc] initWithFrame:NSMakeRect(4, 0, 22, 22) type:kMPXWindowFullscreenButtonType];
			[fsButton setImage:imgFSActive];
			[fsButton setAutoresizingMask:NSViewMinXMargin|NSViewMaxYMargin];
		}

		closeButton = [[MPXWindowButton alloc] initWithFrame:NSMakeRect( 4, 0, 22, 22) type:kMPXWindowCloseButtonType];
		miniButton  = [[MPXWindowButton alloc] initWithFrame:NSMakeRect(25, 0, 22, 22) type:kMPXWindowMinimizeButtonType];
		zoomButton  = [[MPXWindowButton alloc] initWithFrame:NSMakeRect(46, 0, 22, 22) type:kMPXWindowZoomButtonType];
		
		[closeButton setImage:imgCloseActive];
		[miniButton setImage:imgMiniActive];
		[zoomButton setImage:imgZoomActive];
		
		mouseEntered = NO;
		fsBtnEntered = NO;
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

	[fsButton release];
	[imgFSActive release];
	[imgFSRollver release];

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
	
	if (fsButton) {
		[self addSubview:fsButton];
		[fsButton setTarget:[self window]];
		[fsButton setAction:@selector(toggleFullScreen:)];
		
		NSRect rc = [fsButton bounds];
		rc.origin.x = [self bounds].size.width - 22;
		[fsButton setFrame:rc];
	}

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
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AppleMiniaturizeOnDoubleClick"]) {
			[[self window] performMiniaturize:self];
		}
	}
}

-(void) mouseMoved:(NSEvent *)theEvent
{
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	BOOL mouseIn = NSPointInRect(pt, trackRect);
	
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
	
	if (fsButton) {
		mouseIn = NSPointInRect(pt, fsButton.frame);
		if (mouseIn != fsBtnEntered) {
			fsBtnEntered = mouseIn;
			if (fsBtnEntered) {
				[fsButton setImage:imgFSRollver];
			} else {
				[fsButton setImage:imgFSActive];
			}
		}
	}
}

-(void) resetPosition
{
    NSRect rcWin = [[self superview] frame];
    CGFloat ht = self.bounds.size.height;

    rcWin.origin.x = 0;
    rcWin.origin.y = rcWin.size.height - ht;
    rcWin.size.height = ht;

    [self setFrame:rcWin];
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
