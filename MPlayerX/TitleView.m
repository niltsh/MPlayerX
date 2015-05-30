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
#import <QuartzCore/CIFilter.h>

static NSString * const kStringDots = @"...";

@implementation TitleView

@synthesize title;
@synthesize closeButton;
@synthesize miniButton;
@synthesize zoomButton;

-(BOOL) allowsVibrancy
{
  static int allow = -1;
  if (allow == -1) {
    NSOperatingSystemVersion ver = [[NSProcessInfo processInfo] operatingSystemVersion];
    allow = (ver.majorVersion == 10 && ver.minorVersion >=10);
  }
  return allow;
}

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    // [[NSUserDefaults standardUserDefaults] addSuiteNamed:NSGlobalDomain];
    self.material = NSVisualEffectMaterialDark;
    self.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    self.state = NSVisualEffectStateActive;
    
    
    title = nil;
    titleAttr = [[NSDictionary alloc]
                 initWithObjectsAndKeys:
                 [NSColor whiteColor], NSForegroundColorAttributeName,
                 [NSFont titleBarFontOfSize:0], NSFontAttributeName,
                 nil];
    
    tbCornerLeft	= [[NSImage imageNamed:@"titlebar-corner-left"] retain];
    tbCornerRight	= [[NSImage imageNamed:@"titlebar-corner-right"] retain];
    tbMiddle		= [[NSImage imageNamed:@"titlebar-middle"] retain];
    
    fsButton = nil;
    if (MPXGetSysVersion().minorVersion >= kMPXSysVersionLion && MPXGetSysVersion().minorVersion < kMPXSysVersionYosemite) {
      fsButton = [NSWindow standardWindowButton:NSWindowFullScreenButton
                                   forStyleMask:NSBorderlessWindowMask];
      [fsButton setAutoresizingMask:NSViewMinXMargin|NSViewMaxYMargin];
    }
    
    closeButton = [NSWindow standardWindowButton: NSWindowCloseButton
                                    forStyleMask:NSBorderlessWindowMask];
    [closeButton setFrameOrigin:NSMakePoint(8, 4)];
    miniButton = [NSWindow standardWindowButton:NSWindowMiniaturizeButton
                                   forStyleMask:NSBorderlessWindowMask];
    [miniButton setFrameOrigin:NSMakePoint(29, 4)];
    zoomButton = [NSWindow standardWindowButton:NSWindowZoomButton
                                   forStyleMask:NSBorderlessWindowMask];
    [zoomButton setFrameOrigin:NSMakePoint(50, 4)];
    
    NSTrackingArea *const trackingArea = [[NSTrackingArea alloc] initWithRect:NSMakeRect(8, 4, 42+zoomButton.frame.size.width, zoomButton.frame.size.height) options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
  }
  return self;
}

-(void) dealloc
{
  [title release];
  [titleAttr release];
  
  [closeButton release];
  [miniButton release];
  [zoomButton release];
  
  [tbCornerLeft release];
  [tbCornerRight release];
  [tbMiddle release];
  
  [fsButton release];
  
  [super dealloc];
}

-(void) awakeFromNib
{
  [self addSubview:closeButton];
  [self addSubview:miniButton];
  [self addSubview:zoomButton];
  
  if (fsButton) {
    [self addSubview:fsButton];
    [fsButton setFrameOrigin:NSMakePoint([self bounds].size.width - 22,0)];
  }
}

//-(BOOL) acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL) acceptsFirstResponder { return YES; }


-(void) mouseUp:(NSEvent *)theEvent
{
  if ([theEvent clickCount] == 2) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AppleMiniaturizeOnDoubleClick"]) {
      [[self window] performMiniaturize:self];
    }
  }
}

- (void)mouseEntered:(NSEvent *)event
{
  [[self window] makeFirstResponder:self];
  [super mouseEntered:event];
  mouseInside = YES;
  [self setNeedsDisplayForStandardWindowButtons];
}

- (void)mouseExited:(NSEvent *)event
{
  [super mouseExited:event];
  mouseInside = NO;
  [self setNeedsDisplayForStandardWindowButtons];
}

- (BOOL)_mouseInGroup:(NSButton *)button
{
  return mouseInside;
}

- (void) flagsChanged:(NSEvent *)event
{
  [self setNeedsDisplayForStandardWindowButtons];
}

- (void)setNeedsDisplayForStandardWindowButtons
{
  [closeButton setNeedsDisplay];
  [miniButton setNeedsDisplay];
  [zoomButton setNeedsDisplay];
  if (fsButton) {
    [fsButton setNeedsDisplay];
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
  if (self.allowsVibrancy) {
    [super drawRect:dirtyRect];
    return;
  }
  
  NSSize leftSize = [tbCornerLeft size];
  NSSize rightSize = [tbCornerRight size];
  NSSize titleSize = [self bounds].size;
  NSPoint drawPos;
  
  drawPos.x = 0;
  drawPos.y = 0;
  
  dirtyRect.origin.x = 0;
  dirtyRect.origin.y = 0;
  
  if (!self.allowsVibrancy) {
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

  }
  
  
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

@end
