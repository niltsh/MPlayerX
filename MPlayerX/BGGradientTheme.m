//
//  BGGradientTheme.m
//  BGHUDAppKit
//
//  Created by BinaryGod on 6/15/08.
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

#import "BGGradientTheme.h"


@implementation BGGradientTheme

-(NSGradient *)normalGradient {
	
	return [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.324f green: 0.331f blue: 0.347f alpha: [self alphaValue]],
			 (CGFloat)0, [NSColor colorWithDeviceRed: 0.245f green: 0.253f blue: 0.269f alpha: [self alphaValue]], .5f,
			 [NSColor colorWithDeviceRed: 0.206f green: 0.214f blue: 0.233f alpha: [self alphaValue]], .5f,
			 [NSColor colorWithDeviceRed: 0.139f green: 0.147f blue: 0.167f alpha: [self alphaValue]], 1.0f, nil] autorelease];
}

-(NSGradient *)pushedGradient {
	
	return [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.524f green: 0.531f blue: 0.547f alpha: [self alphaValue]],
			 (CGFloat)0, [NSColor colorWithDeviceRed: 0.445f green: 0.453f blue: 0.469f alpha: [self alphaValue]], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.406f green: 0.414f blue: 0.433f alpha: [self alphaValue]], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.339f green: 0.347f blue: 0.367f alpha: [self alphaValue]], (CGFloat)1.0f, nil] autorelease];
}

-(NSGradient *)highlightGradient {
	
	return [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.524f green: 0.531f blue: 0.547f alpha: [self alphaValue]],
			 (CGFloat)0, [NSColor colorWithDeviceRed: 0.445f green: 0.453f blue: 0.469f alpha: [self alphaValue]], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.406f green: 0.414f blue: 0.433f alpha: [self alphaValue]], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.339f green: 0.347f blue: 0.367f alpha: [self alphaValue]], (CGFloat)1.0f, nil] autorelease];
}

-(NSGradient *)knobColor {
	
	return [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.324f green: 0.331f blue: 0.347f alpha: 1.0f],
			 (CGFloat)0, [NSColor colorWithDeviceRed: 0.245f green: 0.253f blue: 0.269f alpha: 1.0f], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.206f green: 0.214f blue: 0.233f alpha: 1.0f], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.139f green: 0.147f blue: 0.167f alpha: 1.0f], (CGFloat)1.0f, nil] autorelease];
}

-(NSGradient *)highlightKnobColor {
	
	return [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.524f green: 0.531f blue: 0.547f alpha: 1.0f],
			 (CGFloat)0, [NSColor colorWithDeviceRed: 0.445f green: 0.453f blue: 0.469f alpha: 1.0f], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.406f green: 0.414f blue: 0.433f alpha: 1.0f], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.339f green: 0.347f blue: 0.367f alpha: 1.0f], (CGFloat)1.0f, nil] autorelease];
}

-(NSGradient *)disabledKnobColor {
	
	return [[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.324f green: 0.331f blue: 0.347f alpha: 1.0f],
			 (CGFloat)0, [NSColor colorWithDeviceRed: 0.245f green: 0.253f blue: 0.269f alpha: 1.0f], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.206f green: 0.214f blue: 0.233f alpha: 1.0f], (CGFloat).5,
			 [NSColor colorWithDeviceRed: 0.139f green: 0.147f blue: 0.167f alpha: 1.0f], (CGFloat)1.0f, nil] autorelease];
}

-(NSColor *)strokeColor {
	
	return [NSColor colorWithDeviceRed: 0.749f green: 0.761f blue: 0.788f alpha: 0.7f];
}

-(CGFloat)alphaValue {
	
	return 0.7f;
}

@end
