/*
 * MPlayerX - DisplayLayer.h
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <OpenGL/gl.h> 
#import "coredef.h"

// 这个值必须小于0，内部实际上会用0做比较
#define kDisplayAscpectRatioInvalid		(-1)

#define IsDisplayLayerAspectValid(x)	(x > 0)

@interface DisplayLayer : CAOpenGLLayer
{
	CVOpenGLBufferRef *bufRefs;
	NSUInteger bufTotal;
	NSInteger frameNow;
	
	CVOpenGLTextureCacheRef cache;

	DisplayFormat fmt;
	BOOL fillScreen;
	CGFloat externalAspectRatio;
	
	BOOL positionOffset;
	CGRect renderRatio;
	
	BOOL flagFillScrnChanged;
	BOOL flagAspectRatioChanged;
	BOOL flagPositionOffsetChanged;
	BOOL refitBounds;
}

@property (readwrite, assign) BOOL fillScreen;

-(NSSize) displaySize;
-(CGFloat) aspectRatio;
-(void) setExternalAspectRatio:(CGFloat)ar;

-(int) startWithFormat:(DisplayFormat)displayFormat buffer:(char**)data total:(NSUInteger)num;
-(void) draw:(NSUInteger)frameNum;
-(void) stop;

-(CIImage*) snapshot;

-(void) setPositionOffset:(BOOL)offset;
-(void) setPositoinOffsetRatio:(CGPoint) ratio;
-(CGPoint) positionOffsetRatio;

-(void) adujustToFitBounds;

@end
