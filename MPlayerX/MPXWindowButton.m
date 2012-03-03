/*
 * MPlayerX - MPXWindowButton.m
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

#import "MPXWindowButton.h"

NSString * const kMPXAccessibilityCloseButtonDesc		= @"closeButton";
NSString * const kMPXAccessibilityMinimizeButtonDesc	= @"minimizeButton";
NSString * const kMPXAccessibilityZoomButtonDesc		= @"zoomButton";

@implementation MPXWindowButton

@synthesize windowButtonType;

-(id) initWithFrame:(NSRect)frame type:(MPXWindowButtonType)type
{
	self = [super initWithFrame:frame];
	
	if (self) {
		windowButtonType = type;

		[self setButtonType:NSMomentaryChangeButton];
		[self setImagePosition:NSImageOnly];
		[self setBordered:NO];
		[self setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
		[self setContinuous:NO];
	}
	return self;
}

+(Class) cellClass
{
	return [MPXWindowButtonCell class];
}

#pragma mark Accessibility

-(void) accessibilityPerformAction: (NSString*)theActionName
{
	if ([theActionName isEqualToString: NSAccessibilityPressAction]) {
		if ([self isEnabled]) {
			[self performClick: nil];
		}
	} else {
		[super accessibilityPerformAction: theActionName];
	}
}

@end

@implementation MPXWindowButtonCell

-(NSArray*) accessibilityAttributeNames
{
	NSArray *ret = [super accessibilityAttributeNames];
	
	if ([[self controlView] respondsToSelector:@selector(windowButtonType)]) {
		// the control view is the MPXWindowButton
		if (ret && (![ret containsObject:NSAccessibilitySubroleAttribute])) {
			ret = [ret arrayByAddingObject:NSAccessibilitySubroleAttribute];
		}
		if (ret && ([(MPXWindowButton*)[self controlView] windowButtonType] == kMPXWindowCloseButtonType) &&
			(![ret containsObject:NSAccessibilityEditedAttribute])) {
			ret = [ret arrayByAddingObject:NSAccessibilityEditedAttribute];
		}
	}
	return ret;
}

-(id) accessibilityAttributeValue: (NSString*)attr
{
	id ret;
	
	if ([[self controlView] respondsToSelector:@selector(windowButtonType)]) {
		
		MPXWindowButtonType type = [(MPXWindowButton*)[self controlView] windowButtonType];
		
		if ([attr isEqualToString:NSAccessibilitySubroleAttribute]) {	
			switch (type) {
				case kMPXWindowCloseButtonType:
					ret = NSAccessibilityCloseButtonSubrole;
					break;
				case kMPXWindowMinimizeButtonType:
					ret = NSAccessibilityMinimizeButtonSubrole;
					break;
				case kMPXWindowZoomButtonType:
					ret = NSAccessibilityZoomButtonSubrole;
					break;
				default:
					ret = NSAccessibilityUnknownSubrole;
					break;
			}
		} else if ([attr isEqualToString:NSAccessibilityDescriptionAttribute]) {
			switch (type) {
				case kMPXWindowCloseButtonType:
					ret = kMPXAccessibilityCloseButtonDesc;
					break;
				case kMPXWindowMinimizeButtonType:
					ret = kMPXAccessibilityMinimizeButtonDesc;
					break;
				case kMPXWindowZoomButtonType:
					ret = kMPXAccessibilityZoomButtonDesc;
					break;
				default:
					ret = @"";
					break;
			}
		} else if ([attr isEqualToString:NSAccessibilityEditedAttribute]) {
			ret = [NSNumber numberWithBool:NO];

		} else {
			ret = [super accessibilityAttributeValue:attr];
		}
	} else {
		ret = [super accessibilityAttributeValue:attr];
	}
	return ret;
}

- (BOOL)accessibilityIsAttributeSettable: (NSString*)attr
{
	BOOL ret;
	
	if ([attr isEqualToString:NSAccessibilitySubroleAttribute] ||
		[attr isEqualToString:NSAccessibilityEditedAttribute]) {
		ret = NO;
	} else {
		ret = [super accessibilityIsAttributeSettable: attr];
	}
	return ret;
}

-(BOOL) accessibilityIsIgnored {return NO;}
@end
