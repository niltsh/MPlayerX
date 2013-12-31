/*
 * MPlayerX - PlayerWindow.m
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

#import "PlayerWindow.h"
#import "TitleView.h"
#import "CocoaAppendix.h"
#import "KeyCode.h"

NSString * const kMPXAccessibilityPlayerWindowDesc		= @"PlayerWindow";
NSString * const kMPXAccessibilityWindowFrameAttribute	= @"AXMPXWindowFrame";

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
	if (MPXGetSysVersion() < kMPXSysVersionLion) {
		// 如果不是Lion
		[self setCollectionBehavior:NSWindowCollectionBehaviorManaged];
	} else {
		// 如果是Lion以上
		[self setCollectionBehavior:NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorFullScreenPrimary];
	}

	[self setContentMinSize:NSMakeSize(480, 360)];
	
	NSRect scrnRC = [[self screen] visibleFrame];
	NSRect winRC  = [self frame];
	scrnRC.origin.x += (scrnRC.size.width - winRC.size.width) / 2;
	scrnRC.origin.y += (scrnRC.size.height-winRC.size.height) / 2;
	[self setFrameOrigin:scrnRC.origin];
}

-(BOOL) canBecomeKeyWindow { return YES;}
-(BOOL) canBecomeMainWindow { return YES;}
-(BOOL) acceptsFirstResponder { return YES; }

-(void) setTitle:(NSString *)aString
{
	[titlebar setTitle:aString];
	[titlebar setNeedsDisplay:YES];
}

-(NSString*) title
{
	return [titlebar title];
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
	if ([self delegate]) {
		NSRect frm = [[self delegate] windowWillUseStandardFrame:self defaultFrame:[[self screen] visibleFrame]];
		[self setFrame:frm display:YES animate:YES];
	} else {
		[self zoom:sender];		
	}
}

-(void) performMiniaturize:(id)sender
{
	[self miniaturize:sender];
}

-(void) performClose:(id)sender
{
	[self close];
}

// 当全屏时，鼠标点击屏幕右上角的图标返回全屏的时候
// 会直接激发window的toggleFullScreen函数，这样时不OK的
-(void) toggleFullScreenReal:(id)sender
{
	[super toggleFullScreen:sender];
}

-(void) toggleFullScreen:(id)sender
{
	[self postEvent:[NSEvent makeKeyDownEvent:kSCMFullScrnKeyEquivalent modifierFlags:kSCMFullscreenKeyEquivalentModifierFlagMask]
			atStart:YES];
}

#pragma mark Accessibility

-(NSArray*) accessibilityAttributeNames
{
	NSArray* ret = [super accessibilityAttributeNames];
	if (ret && (![ret containsObject:NSAccessibilitySubroleAttribute])) {
		ret = [ret arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilitySubroleAttribute, kMPXAccessibilityWindowFrameAttribute, nil]];
	}
	return ret;
}

-(id) accessibilityAttributeValue:(NSString*)attr
{
	id ret;
	
	if ([attr isEqualToString:NSAccessibilityCloseButtonAttribute]) {
		ret = [titlebar closeButton];
		
	} else if ([attr isEqualToString:NSAccessibilityMinimizeButtonAttribute]) {
		ret = [titlebar miniButton];
		
	} else if ([attr isEqualToString:NSAccessibilityZoomButtonAttribute]) {
		ret = [titlebar zoomButton];
		
	} else if ([attr isEqualToString:NSAccessibilityDescriptionAttribute]) {
		ret = kMPXAccessibilityPlayerWindowDesc;
		
	} else if ([attr isEqualToString:NSAccessibilitySubroleAttribute]) {
		ret = NSAccessibilityStandardWindowSubrole;
		
	} else if ([attr isEqualToString:kMPXAccessibilityWindowFrameAttribute]) {
		ret = [NSValue valueWithRect:[self frame]];

	} else {
		ret = [super accessibilityAttributeValue:attr];
	}
	return ret;
}

-(BOOL)accessibilityIsAttributeSettable:(NSString*)attr
{
	BOOL ret;
	if ([attr isEqualToString:NSAccessibilityCloseButtonAttribute] ||
		[attr isEqualToString:NSAccessibilityMinimizeButtonAttribute] ||
		[attr isEqualToString:NSAccessibilityZoomButtonAttribute] ||
		[attr isEqualToString:NSAccessibilityDescriptionAttribute] ||
		[attr isEqualToString:NSAccessibilitySubroleAttribute]) {
		// set unsettable
		ret = NO;
	} else if (([attr isEqualToString:NSAccessibilityPositionAttribute] || [attr isEqualToString:NSAccessibilitySizeAttribute] || [attr isEqualToString:kMPXAccessibilityWindowFrameAttribute]) &&
			   [[self contentView] respondsToSelector:@selector(accessibilitySetValue:forAttribute:)]) {
		// settable
		ret = YES;
	} else {
		ret = [super accessibilityIsAttributeSettable:attr];
	}
	return ret;
}

-(void)accessibilitySetValue:(id)value forAttribute:(NSString *)attr
{
	if (([attr isEqualToString:NSAccessibilityPositionAttribute] || [attr isEqualToString:NSAccessibilitySizeAttribute] || [attr isEqualToString:kMPXAccessibilityWindowFrameAttribute]) &&
		[[self contentView] respondsToSelector:@selector(accessibilitySetValue:forAttribute:)]) {
		[[self contentView] accessibilitySetValue:value forAttribute:attr];
	} else {
		[super accessibilitySetValue:value forAttribute:attr];
	}
}

-(BOOL) accessibilityIsIgnored {return NO;}
@end
