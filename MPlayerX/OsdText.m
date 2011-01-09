/*
 * MPlayerX - OsdText.m
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

#import "UserDefaults.h"
#import "OsdText.h"

#define kOSDAutoHideTimeInterval	(5)

#define kOSDFontSizeMinDefault		(24)
#define kOSDFontSizeMaxDefault		(48)

@implementation OsdText

@synthesize active;
@synthesize owner;
@synthesize frontColor;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithFloat:kOSDFontSizeMaxDefault], kUDKeyOSDFontSizeMax,
	  [NSNumber numberWithFloat:kOSDFontSizeMinDefault], kUDKeyOSDFontSizeMin,
	  [NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]], kUDKeyOSDFrontColor,
	  [NSNumber numberWithFloat:kOSDAutoHideTimeInterval], kUDKeyOSDAutoHideTime,
	  nil]];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];
		
		fontSizeMin = [ud floatForKey:kUDKeyOSDFontSizeMin];
		fontSizeMax = [ud floatForKey:kUDKeyOSDFontSizeMax];

		// mapping height of 300 px to font size Min
		//         height of 900 px to font size Max
		// 300 * ratio + offset = Min
		// 900 * ratio + offset = Max
		// so
		// ratio  = (  Max - Min) / 600
		// offset = (3*Min - Max) / 2
		fontSizeRatio = (fontSizeMax - fontSizeMin) / 600.0;
		fontSizeOffset = (3*fontSizeMin - fontSizeMax) / 2.0;

		active = NO;

		autoHideTimeInterval = 0;
		autoHideTimer = nil;
		shouldHide = YES;
		owner = kOSDOwnerOther;
		
		frontColor = [[NSUnarchiver unarchiveObjectWithData:[ud objectForKey:kUDKeyOSDFrontColor]] retain];

		shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(1.0, -1.0)];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow setShadowBlurRadius:8];
		
		[self setAlphaValue:0];
		[self setSelectable:NO];
		[self setAllowsEditingTextAttributes:YES];
		[self setDrawsBackground:NO];
		[self setBezeled:NO];
		
		[self setAutoHideTimeInterval:[ud floatForKey:kUDKeyOSDAutoHideTime]];
	}
	return self;
}

-(void) dealloc
{
	if (autoHideTimer) {
		[autoHideTimer invalidate];
	}
	[frontColor release];
	[shadow release];

	[super dealloc];
}

-(void) setAutoHideTimeInterval:(NSTimeInterval)ti
{
	if (autoHideTimer) {
		[autoHideTimer invalidate];
		autoHideTimer = nil;
	}
	if (ti > 0) {
		autoHideTimeInterval = ti;
		autoHideTimer = [NSTimer timerWithTimeInterval:autoHideTimeInterval/2
												target:self
											  selector:@selector(tryToHide)
											  userInfo:nil
											   repeats:YES];
		NSRunLoop *rl = [NSRunLoop mainRunLoop];
		[rl addTimer:autoHideTimer forMode:NSDefaultRunLoopMode];
		[rl addTimer:autoHideTimer forMode:NSModalPanelRunLoopMode];
		[rl addTimer:autoHideTimer forMode:NSEventTrackingRunLoopMode];
	}
}

-(void) tryToHide
{
	if (shouldHide) {
		[self.animator setAlphaValue:0];
	} else {
		shouldHide = YES;
	}
}

-(void) setStringValue:(NSString *)aString owner:(OSDOWNER)ow updateTimer:(BOOL)ut
{
	if (active) {
		if (ut || ([self alphaValue] > 0 && (ow == owner))) {
			// 如果是更新timer，那么意味着onwer要更换
			// 如果不更新，那么在self没有隐藏，并且owner一直的情况下更新
			if (!aString) {
				// 如果是nil，那么就用现在的值
				aString = [self stringValue];
			}

			NSSize sz = [[self superview] bounds].size;
			
			float fontSize = MIN(fontSizeMax, MAX(fontSizeMin, (sz.height*fontSizeRatio) + fontSizeOffset));

			NSFont *font = [NSFont systemFontOfSize:fontSize];
			
			NSDictionary *attrDict = [[NSDictionary alloc] initWithObjectsAndKeys:
									  font, NSFontAttributeName,
									  frontColor, NSForegroundColorAttributeName,
									  shadow, NSShadowAttributeName, nil];
			NSAttributedString *str = [[NSAttributedString alloc] initWithString:aString attributes:attrDict];
			[self setObjectValue:str];
			
			[self setAlphaValue:1];
			
			[str release];
			[attrDict release];			
		}
		if (ut) {
			// 如果更新Timer的话，那么更新owner
			owner = ow;
			shouldHide = NO;
		}
	}
}
@end
