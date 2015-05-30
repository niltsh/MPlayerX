//
//  BGHUDButtonCell.m
//  BGHUDAppKit
//
//  Created by BinaryGod on 5/25/08.
//
//  Copyright (c) 2008, Tim Davis (BinaryMethod.com, binary.god@gmail.com)
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//		Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//
//		Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation and/or
//	other materials provided with the distribution.
//
//		Neither the name of the BinaryMethod.com nor the names of its contributors
//	may be used to endorse or promote products derived from this software without
//	specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS AS IS AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
//	OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
//	POSSIBILITY OF SUCH DAMAGE.

#import "BGHUDButtonCell.h"


@implementation BGHUDButtonCell

#pragma mark Draw Functions

@synthesize themeKey;

-(id)init {
	
	self = [super init];
	
	if(self) {
		
		self.themeKey = @"gradientTheme";
		buttonType = 0;
	}
	
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	
	self = (BGHUDButtonCell *)[super initWithCoder: aDecoder];
	
	if(self) {
		
		if([aDecoder containsValueForKey: @"themeKey"]) {
			
			self.themeKey = [aDecoder decodeObjectForKey: @"themeKey"];
		} else {
			
			self.themeKey = @"gradientTheme";
		}
		
		if([aDecoder containsValueForKey: @"BGButtonType"]) {
			
			buttonType = [aDecoder decodeIntegerForKey: @"BGButtonType"];
		} else {
			
			buttonType = 0;
		}
	}
	
	return self;
}

-(void)encodeWithCoder: (NSCoder *)coder {
	
	[super encodeWithCoder: coder];
	
	[coder encodeObject: self.themeKey forKey: @"themeKey"];
	[coder encodeInt: (int)buttonType forKey: @"BGButtonType"];
}

-(id)copyWithZone:(NSZone *) zone {
	
	BGHUDButtonCell *copy = [super copyWithZone: zone];
	
	copy->themeKey = nil;
	[copy setThemeKey: [self themeKey]];
	
	return copy;
}

- (void)setButtonType:(NSButtonType)aType {

	buttonType = aType;	
	[super setButtonType: aType];
}

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	// Make sure our own height is right, and not using
	// a NSMatrix parents height.
  [super drawWithFrame:cellFrame inView:controlView];
  return;
#if 0
	cellFrame.size.height = [self cellSize].height;
	
	switch ([self bezelStyle]) {
			
		case NSTexturedRoundedBezelStyle:
			
			[self drawTexturedRoundedButtonInFrame: cellFrame];
			break;
			
		case NSRoundRectBezelStyle:
			
			[self drawRoundRectButtonInFrame: cellFrame];
			break;
			
		case NSSmallSquareBezelStyle:
			
			[self drawSmallSquareButtonInFrame: cellFrame];
			break;
			
		case NSRoundedBezelStyle:
			
			[self drawRoundedButtonInFrame: cellFrame];
			break;
			
		case NSRecessedBezelStyle:
			[self drawRecessedButtonInFrame: cellFrame];
			break;
        default:
            break;
	}
	
	if(buttonType == NSSwitchButton || buttonType == NSRadioButton) {
		
		if([self imagePosition] != NSNoImage) {
			
			[self drawImage: [self image] withFrame: cellFrame inView: [self controlView]];
		}
	}
#endif
}

-(NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
	
	NSRect textRect = frame;
	
	// Adjust Text Rect based on control type and size
	if(buttonType != NSSwitchButton && buttonType != NSRadioButton) {
		
		textRect.origin.x += 5;
		textRect.size.width -= 10;
		textRect.size.height -= 2;
	}
	
	NSMutableAttributedString *newTitle = [title mutableCopy];
	
	//If button is set to show alternate title then
	//display alternate title
	if([self showsStateBy] == 0 && [self highlightsBy] == 1) {
		
		if([self isHighlighted]) {
			
			if([self alternateTitle]) {
				
				[newTitle setAttributedString: [self attributedAlternateTitle]];
			}
		}
	}
	
	//If button is set to show alternate title then
	//display alternate title
	if([self showsStateBy] == 1 && [self highlightsBy] == 3) {
		
		if([self state] == 1) {
			
			if([self alternateTitle]) {
				
				[newTitle setAttributedString: [self attributedAlternateTitle]];
			}
		}
	}
	
	//Make sure we aren't trying to edit an
	//empty string.
	if([newTitle length] > 0) {
		
		[newTitle beginEditing];
		
		// Removed so Shadows could be used
		// TODO: Find out why I had this in here in the first place, no cosmetic difference
		/*[newTitle removeAttribute: NSShadowAttributeName
							range: NSMakeRange(0, [newTitle length])];*/
		
		//Set text color based on button enabled state.
		if([self isEnabled]) {
			
			[newTitle addAttribute: NSForegroundColorAttributeName
							 value: [[[BGThemeManager keyedManager] themeForKey: self.themeKey] textColor]
							 range: NSMakeRange(0, [newTitle length])];
		} else {
			
			[newTitle addAttribute: NSForegroundColorAttributeName
							 value: [[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledTextColor]
							 range: NSMakeRange(0, [newTitle length])];
		}
		
		[newTitle endEditing];
		
		//Make the super class do the drawing
		[super drawTitle: newTitle withFrame: textRect inView: controlView];
	}
	
	[newTitle release];
	return textRect;
}

-(void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView {
	
	if([image isTemplate]) {
		
		[super drawImage: image withFrame: frame inView: controlView];
	} else {
		
		if(buttonType == NSSwitchButton) {
			
			[self drawCheckInFrame: frame isRadio: NO];		
		} else if(buttonType == NSRadioButton) {
			
			[self drawCheckInFrame: frame isRadio: YES];
		} else {
			
			//Setup per State and Highlight Settings
			if([self showsStateBy] == 0 && [self highlightsBy] == 1) {
				
				if([self isHighlighted]) {
					
					if([self alternateImage]) {
						
						image = [self alternateImage];
					}
				}
			}
			
			if([self showsStateBy] == 1 && [self highlightsBy] == 3) {
				
				if([self state] == 1) {
					
					if([self alternateImage]) {
						
						image = [self alternateImage];
					}
				}
			}
			
			//Calculate Image Position
			NSRect imageRect = frame;
			imageRect.size.height = [image size].height;
			imageRect.size.width = [image size].width;
			imageRect.origin.y += (frame.size.height /2) - (imageRect.size.height /2);
			
			//Setup Position
			switch ([self imagePosition]) {
					
				case NSImageLeft:
					
					imageRect.origin.x += 5;
					break;
					
				case NSImageOnly:
					
					imageRect.origin.x += (frame.size.width /2) - (imageRect.size.width /2);
					break;
					
				case NSImageRight:
					
					imageRect.origin.x = ((frame.origin.x + frame.size.width) - imageRect.size.width) - 5;
					break;
					
				case NSImageBelow:
					
					break;
					
				case NSImageAbove:
					
					break;
					
				case NSImageOverlaps:
					
					break;
					
				default:
					
					imageRect.origin.x += 5;
					break;
			}
			
      [image lockFocusFlipped: YES];
			
			//Draw the image based on enabled state
			if([self isEnabled]) {
				
				[image drawInRect: imageRect fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: [[[BGThemeManager keyedManager] themeForKey: self.themeKey] alphaValue]];
			} else {
				[image drawInRect: imageRect fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: [[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledAlphaValue]];
			}
			
		}
	}
}

-(void)drawTexturedRoundedButtonInFrame:(NSRect)frame {
	
	//Adjust Rect so strokes are true and
	//shadows are visible
	frame.origin.x += 1.5f;
	frame.origin.y += 0.5f;
	frame.size.width -= 3;
	frame.size.height -= 4;
	
	//Adjust Rect based on ControlSize so that
	//my controls match as closely to apples
	//as possible.
	switch ([self controlSize]) {
			
		case NSRegularControlSize:
			
			frame.origin.y += 1;
			break;
			
		case NSSmallControlSize:
			
			//frame.origin.y += 3;
			//frame.size.height += 2;
			break;
			
		case NSMiniControlSize:
			
			//frame.origin.y += 5;
			//frame.size.height += 1;
			break;
	}
	
	//Draw Outer-most ring
	NSBezierPath *path = [[NSBezierPath alloc] init];
	[path appendBezierPathWithRoundedRect: frame xRadius: 4.0f yRadius: 4.0f];
	
	//Save Graphics State
	[NSGraphicsContext saveGraphicsState];
	
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] dropShadow] set];
	}
	
	//Draw Dark Border
	[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] darkStrokeColor] set];
	[path setLineWidth: 1.0f];
	[path stroke];
	
	//Restore Graphics State
	[NSGraphicsContext restoreGraphicsState];
	
	if([self isEnabled]) {
		
		//Draw Background
		if(([self showsStateBy] == 12 && [self highlightsBy] == 14) ||
		   ([self showsStateBy] == 12 && [self highlightsBy] == 12)) {
			
			if([self state] == 1) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] highlightGradient] drawInBezierPath: path angle: 90];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalGradient] drawInBezierPath: path angle: 90];
			}
		} else {
			
			if([self isHighlighted]) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] pushedGradient] drawInBezierPath: path angle: 90];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalGradient] drawInBezierPath: path angle: 90];
			}
		}
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledNormalGradient] drawInBezierPath: path angle: 90];
	}
	
	//Draw Border
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	}
	
	[path setLineWidth: 1.0f];
	[path stroke];
	
	//path = nil;
	[path release];
	
	if([self imagePosition] != NSImageOnly) {
		
		[self drawTitle: [self attributedTitle] withFrame: frame inView: [self controlView]];
	}
	
	if([self imagePosition] != NSNoImage) {
		
		[self drawImage: [self image] withFrame: frame inView: [self controlView]];
	}
}

-(void)drawRoundRectButtonInFrame:(NSRect)frame {
	
	//Adjust Rect so strokes are true and
	//shadows are visible
	frame.origin.x += 1.5f;
	frame.size.width -= 3;
	
	//Adjust Rect based on ControlSize so that
	//my controls match as closely to apples
	//as possible.
	switch ([self controlSize]) {
			
		case NSRegularControlSize:
			
			frame.size.height -= 3;
			break;
			
		case NSSmallControlSize:
			
			frame.size.height -= 3;
			break;
			
		case NSMiniControlSize:
			
			frame.origin.y += 1;
			frame.size.height -= 5;
			break;
	}
	
	//Create Path
	NSBezierPath *path = [[NSBezierPath alloc] init];
	
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMinX(frame) + BGCenterY(frame), NSMidY(frame) + 0.5f)
									 radius: BGCenterY(frame)
								 startAngle: 90
								   endAngle: 270];
	
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMaxX(frame) - BGCenterY(frame), NSMidY(frame) + 0.5f)
									 radius: BGCenterY(frame)
								 startAngle: 270
								   endAngle: 90];
	
	[path closePath];
	[NSGraphicsContext saveGraphicsState];
	
	//Draw dark border color
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] dropShadow] set];
	}
	[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] darkStrokeColor] set];
	[path stroke];
	
	[NSGraphicsContext restoreGraphicsState];
	
	if([self isEnabled]) {
		
		if(([self showsStateBy] == 12 && [self highlightsBy] == 14) ||
		   ([self showsStateBy] == 12 && [self highlightsBy] == 12)) {
			
			if([self state] == 1) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] highlightGradient] drawInBezierPath: path angle: 90];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalGradient] drawInBezierPath: path angle: 90];
			}
		} else {
			
			if([self isHighlighted]) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] pushedGradient] drawInBezierPath: path angle: 90];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalGradient] drawInBezierPath: path angle: 90];
			}
		}
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledNormalGradient] drawInBezierPath: path angle: 90];
	}
	
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	}
	[path setLineWidth: 1.0f];
	[path stroke];
	
	[path release];
	
	if([self imagePosition] != NSImageOnly) {
		
		NSRect textFrame = frame;
		textFrame.origin.y += 1;
		
		[self drawTitle: [self attributedTitle] withFrame: textFrame inView: [self controlView]];
	}
	
	if([self imagePosition] != NSNoImage) {
		
		[self drawImage: [self image] withFrame: frame inView: [self controlView]];
	}
}

-(void)drawSmallSquareButtonInFrame:(NSRect)frame {
	
	//Adjust Rect so strokes are true and
	//shadows are visible
	frame.origin.x += 1.5f;
	frame.origin.y += 0.5f;
	frame.size.width -= 3;
	frame.size.height = [[self controlView] bounds].size.height - 3;
	
	//Draw Outer-most ring
	NSBezierPath *path = [[NSBezierPath alloc] init];
	[path appendBezierPathWithRect: frame];
	
	[NSGraphicsContext saveGraphicsState];
	
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] dropShadow] set];
	}
	
	[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] darkStrokeColor] set];
	[path setLineWidth: 1.0f];
	[path stroke];
	
	[NSGraphicsContext restoreGraphicsState];
	
	//Draw Background
	if([self isEnabled]) {
		
		if(([self showsStateBy] == 12 && [self highlightsBy] == 14) ||
		   ([self showsStateBy] == 12 && [self highlightsBy] == 12)) {
			
			if([self state] == 1) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] highlightComplexGradient] drawInBezierPath: path angle: 90];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalComplexGradient] drawInBezierPath: path angle: 90];
			}
		} else {
			
			if([self isHighlighted]) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] pushedComplexGradient] drawInBezierPath: path angle: 90];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalComplexGradient] drawInBezierPath: path angle: 90];
			}
		}
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledNormalComplexGradient] drawInBezierPath: path angle: 90];
	}
	
	//Draw Border
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	}
	[path setLineWidth: 1.0f];
	[path stroke];
	
	[path release];
	
	if([self imagePosition] != NSImageOnly) {
		
		[self drawTitle: [self attributedTitle] withFrame: frame inView: [self controlView]];
	}
	
	if([self imagePosition] != NSNoImage) {
		
		[self drawImage: [self image] withFrame: frame inView: [self controlView]];
	}
}

-(void)drawRoundedButtonInFrame:(NSRect)frame {
	
	NSRect textFrame;
	
	//Adjust Rect so strokes are true and
	//shadows are visible
	frame.origin.x += .5f;
	frame.origin.y += .5f;
	frame.size.height -= 1;
	frame.size.width -= 1;
	
	//Adjust Rect based on ControlSize so that
	//my controls match as closely to apples
	//as possible.
	switch ([self controlSize]) {
		default: // Silence uninitialized variable warnings for textFrame fields.
		case NSRegularControlSize:
			
			frame.origin.x += 4;
			frame.origin.y += 4;
			frame.size.width -= 8;
			frame.size.height -= 12;
			
			textFrame = frame;
			break;
			
		case NSSmallControlSize:
			
			frame.origin.x += 4;
			frame.origin.y += 4;
			frame.size.width -= 8;
			frame.size.height -= 11;
			
			textFrame = frame;
			textFrame.origin.y += 1;
			break;
			
		case NSMiniControlSize:
			
			frame.origin.y -= 1;
			
			textFrame = frame;
			textFrame.origin.y += 1;
			break;
	}
	
	//Create Path
	NSBezierPath *path = [[NSBezierPath alloc] init];
	
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMinX(frame) + BGCenterY(frame), NSMidY(frame) + 0.5f)
									 radius: BGCenterY(frame)
								 startAngle: 90
								   endAngle: 270];
	
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMaxX(frame) - BGCenterY(frame), NSMidY(frame) + 0.5f)
									 radius: BGCenterY(frame) 
								 startAngle: 270 
								   endAngle: 90];
	
	[path closePath];
	
	if([self isEnabled]) {
		
		if(([self showsStateBy] == 12 && [self highlightsBy] == 14) ||
		   ([self showsStateBy] == 12 && [self highlightsBy] == 12)) {
			
			if([self state] == 1) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] highlightSolidFill] set];
				[path fill];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalSolidFill] set];
				[path fill];
			}
		} else {
			
			if([self isHighlighted]) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] pushedSolidFill] set];
				[path fill];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalSolidFill] set];
				[path fill];
			}
		}
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledNormalSolidFill] set];
	}
	
	[path release];
	
	if([self imagePosition] != NSImageOnly) {
		
		[self drawTitle: [self attributedTitle] withFrame: textFrame inView: [self controlView]];
	}
	
	if([self imagePosition] != NSNoImage) {
		
		[self drawImage: [self image] withFrame: frame inView: [self controlView]];
	}
}

-(void)drawCheckInFrame:(NSRect)frame isRadio:(BOOL)radio{
	
	//Adjust by .5 so lines draw true
	frame.origin.x += .5f;
	frame.origin.y += .5f;
	
	if([[[self controlView] className] isEqualToString: @"NSMatrix"]) {
		
		NSMatrix* matrix = (NSMatrix*)[self controlView];
		frame.origin.y += (BGCenterY([matrix bounds]) / [matrix numberOfRows]) - BGCenterY(frame);
		//frame.origin.x += 40;
		
	} else if(![[[[self controlView] superclass] className] isEqualToString: @"BGHUDTableView"] &&
			  ![[[[self controlView] superclass] className] isEqualToString: @"BGHUDOutlineView"] &&
			  ![[[self controlView] className] isEqualToString: @"BGHUDTableView"] &&
			  ![[[self controlView] className] isEqualToString: @"BGHUDOutlineView"]) {
		
		frame.origin.y += (BGCenterY([[self controlView] bounds]) - BGCenterY(frame));
	}
	
	// Create Check Rect
	NSRect innerRect = frame;
	NSRect textRect = frame;
	
	//Make adjustments based on ControlSize
	//Set checkbox size
	if([self controlSize] == NSRegularControlSize) {
		
		innerRect.size.height = 12;
		innerRect.size.width = 13;
		innerRect.origin.y += 2;
		
	} else if([self controlSize] == NSSmallControlSize) {
		
		innerRect.size.height = 10;
		innerRect.size.width = 11;
		innerRect.origin.y += 3;
		
	} else {
		
		innerRect.size.height = 8;
		innerRect.size.width = 9;
		innerRect.origin.y += 5;
	}
	
	if(radio) {
		
		innerRect.size.height = innerRect.size.width;
	}
	
	// Determine Horizontal Placement
	switch ([self imagePosition]) {
			
		case NSImageLeft:
			
			//Make adjustments to horizontal placement
			//Create Text Rect so text is drawn properly
			if([self controlSize] == NSRegularControlSize) {
				
				innerRect.origin.x += 2;
				textRect.size.width -= (NSMaxX(innerRect) + 5);
				textRect.origin.x = (NSMaxX(innerRect) + 5);
				textRect.origin.y -= 2;
				
			} else if([self controlSize] == NSSmallControlSize) {
				
				innerRect.origin.x += 3;
				textRect.size.width -= (NSMaxX(innerRect) + 6);
				textRect.origin.x = (NSMaxX(innerRect) + 6);
				textRect.origin.y -= 1;
				
			} else {
				
				innerRect.origin.x += 4;
				textRect.size.width -= (NSMaxX(innerRect) + 4);
				textRect.origin.x = (NSMaxX(innerRect) + 4);
			}
			
			break;
			
		case NSImageOnly:
			
			//Adjust slightly so lines draw true, and center really is
			//center
			if([self controlSize] == NSRegularControlSize) {
				
				innerRect.origin.x -= .5f;
			} else if([self controlSize] == NSMiniControlSize) {
				
				innerRect.origin.x += .5f;
			}
			
			innerRect.origin.x += BGCenterX(frame) - BGCenterX(innerRect);
			break;
			
		case NSImageRight:
			
			if([self controlSize] == NSRegularControlSize) {
				
				innerRect.origin.x = (NSWidth(frame) - NSWidth(innerRect) - 1.5f) ;
				textRect.origin.x += 2;
				textRect.size.width = (NSMinX(innerRect) - NSMinX(textRect) - 5);
				textRect.origin.y -= 2;
				
			} else if([self controlSize] == NSSmallControlSize) {
				
				innerRect.origin.x = (NSWidth(frame) - NSWidth(innerRect) - 1.5f);
				textRect.origin.x += 2;
				textRect.size.width = (NSMinX(innerRect) - NSMinX(textRect) - 5);
				textRect.origin.y -= 1;
				
			} else {
				
				innerRect.origin.x = (NSWidth(frame) - NSWidth(innerRect) - 1.5f);
				textRect.origin.x += 2;
				textRect.size.width = (NSMinX(innerRect) - NSMinX(textRect) - 5);
			}
			
			break;
			
		default:
      break;
	}
	
	// Create Rounded Rect Path
	NSBezierPath *path = [[NSBezierPath alloc] init];
	
	if(radio) {
		
		[path appendBezierPathWithOvalInRect: innerRect];
	} else {
		
		[path appendBezierPathWithRoundedRect: innerRect xRadius: 2 yRadius: 2];
	}
	
	[NSGraphicsContext saveGraphicsState];
	
	//Draw Shadow
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] dropShadow] set];
	}
	[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] darkStrokeColor] set];
	[path stroke];
	
	[NSGraphicsContext restoreGraphicsState];
	
	// Determine Fill Color and Alpha Values
	if([self isEnabled]) {
		
		if([self isHighlighted]) {
			
			[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] highlightGradient] drawInBezierPath: path angle: 90];
		} else {
			
			[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalGradient] drawInBezierPath: path angle: 90];
		}
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledNormalGradient] drawInBezierPath: path angle: 90];
	}
	
	// Draw Border
	if([self isEnabled]) {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	} else {
		
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
	}
	[path setLineWidth: 1.0f];
	[path stroke];
	
	[path release];
	
	// Draw Glyphs for On/Off/Mixed States
	switch ([self state]) {
			
		case NSMixedState:
			
			path = [[NSBezierPath alloc] init];
			NSPoint pointsMixed[2];
			
			pointsMixed[0] = NSMakePoint(NSMinX(innerRect) + 3, NSMidY(innerRect));
			pointsMixed[1] = NSMakePoint(NSMaxX(innerRect) - 3, NSMidY(innerRect));
			
			[path appendBezierPathWithPoints: pointsMixed count: 2];
			
			if([self isEnabled]) {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
			} else {
				
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
			}
			
			[path setLineWidth: 2.0f];
			[path stroke];
			
			[path release];
			
			break;
			
		case NSOnState:
			
			if(radio) {
				
				if([self controlSize] == NSRegularControlSize) {
					
					innerRect.origin.x += 4;
					innerRect.origin.y += 4;
					innerRect.size.width -= 8;
					innerRect.size.height -= 8;
					
				} else if([self controlSize] == NSSmallControlSize) {
					
					innerRect.origin.x += 3.5f;
					innerRect.origin.y += 3.5f;
					innerRect.size.width -= 7;
					innerRect.size.height -= 7;
					
				} else {
					
					innerRect.origin.x += 3;
					innerRect.origin.y += 3;
					innerRect.size.width -= 6;
					innerRect.size.height -= 6;
				}
				
				
				path = [[NSBezierPath alloc] init];
				[path appendBezierPathWithOvalInRect: innerRect];
				
				if([self isEnabled]) {
					
					[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
				} else {
					
					[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
				}
				[path fill];
				
				[path release];
			} else {
				
				path = [[NSBezierPath alloc] init];
				NSPoint pointsOn[4];
				
				pointsOn[0] = NSMakePoint(NSMinX(innerRect) + 3, NSMidY(innerRect) - 2);
				pointsOn[1] = NSMakePoint(NSMidX(innerRect), NSMidY(innerRect) + 2);
				pointsOn[2] = NSMakePoint(NSMidX(innerRect), NSMidY(innerRect) + 2);
				pointsOn[3] = NSMakePoint(NSMinX(innerRect) + NSWidth(innerRect) - 1, NSMinY(innerRect) - 2);
				
				[path appendBezierPathWithPoints: pointsOn count: 4];
				
				if([self isEnabled]) {
					
					[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
				} else {
					
					[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] strokeColor] set];
				}
				
				if([self controlSize] == NSMiniControlSize) {
					
					[path setLineWidth: 1.5f];
				} else {
					
					[path setLineWidth: 2.0f];
				}
				
				[path stroke];
				
				[path release];
			}
			
			break;
	}
	
	if([self imagePosition] != NSImageOnly) {
		
		if([self attributedTitle]) {
			
			[self drawTitle: [self attributedTitle] withFrame: textRect inView: [self controlView]];
		}
	}
}

-(void)drawRecessedButtonInFrame:(NSRect)frame {//This part is not implemented so good as the codes from Timothy Davis, but we do need that
	NSRect textFrame;
	
	//Adjust Rect so strokes are true and
	//shadows are visible
	frame.origin.x += .5f;
	frame.origin.y += .5f;
	frame.size.height -= 1;
	frame.size.width -= 1;
	
	//Adjust Rect based on ControlSize so that
	//my controls match as closely to apples
	//as possible.
	switch ([self controlSize]) {
		default: // Silence uninitialized variable warnings for textFrame fields.
		case NSRegularControlSize:
			
			frame.origin.x += 1;
			frame.origin.y += 1;
			frame.size.width -= 2;
			frame.size.height -= 4;
			
			textFrame = frame;
			break;
			
		case NSSmallControlSize:
			
			frame.origin.x += 1;
			frame.origin.y += 1;
			frame.size.width -= 2;
			frame.size.height -= 3;
			
			textFrame = frame;
			textFrame.origin.y += 1;
			break;
			
		case NSMiniControlSize:
			
			frame.origin.y -= 1;
			
			textFrame = frame;
			textFrame.origin.y += 1;
			break;
	}	
	//Create Path
	NSBezierPath *path = [[NSBezierPath alloc] init];
	
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMinX(frame) + BGCenterY(frame), NSMidY(frame) + 0.5f)
									 radius: BGCenterY(frame)
								 startAngle: 90
								   endAngle: 270];
	
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMaxX(frame) - BGCenterY(frame), NSMidY(frame) + 0.5f)
									 radius: BGCenterY(frame) 
								 startAngle: 270 
								   endAngle: 90];
	
	[path closePath];
	
	if([self isEnabled]) {
		if([self state] == 1) {
			[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] pushedSolidFill] set];
			[path fill];
			isMouseIn = NO;
		}
		else {
			if(isMouseIn){
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] highlightSolidFill] set];
				[path fill];
			}
			else {
				[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] normalSolidFill] set];
				[path fill];
			}
		}
	}
	else {
		[[[[BGThemeManager keyedManager] themeForKey: self.themeKey] disabledNormalSolidFill] set];
	}
	
	[path release];
	
	if([self imagePosition] != NSImageOnly) {
		[self drawTitle: [self attributedTitle] withFrame: textFrame inView: [self controlView]];
	}
	
	if([self imagePosition] != NSNoImage) {
		[self drawImage: [self image] withFrame: frame inView: [self controlView]];
	}
}

- (void)mouseEntered:(NSEvent *)event{
	if ([self bezelStyle] == NSRecessedBezelStyle) {
		isMouseIn = YES;
		[self setHighlighted:YES];
	}
}
- (void)mouseExited:(NSEvent *)event{
	if ([self bezelStyle] == NSRecessedBezelStyle) {
		isMouseIn = NO;
		[self setHighlighted:NO];
	}
}
#pragma mark -
#pragma mark Helper Methods

-(void)dealloc {
	
	[themeKey release];
	[super dealloc];
}

-(void)setValue:(id) value forKey:(NSString *) key {
	
	if([key isEqualToString: @"inspectedType"]) {
		
		if([(NSNumber *)value intValue] == 2) {
			
			buttonType = NSSwitchButton;
		} else if([(NSNumber *)value intValue] == 3) {
			
			buttonType = NSRadioButton;
		} else {
			
			buttonType = 0;
		}
	}
	
	[super setValue: value forKey: key];
}

#pragma mark -

@end
