/*
 * MPlayerX - DisplayLayer.m
 *
 * Copyright (C) 2009 - 2011, Zongyao QU
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

#import "DisplayLayer.h"
#import "CocoaAppendix.h"

#define SAFEFREE(x)						{if(x){free(x); x = NULL;}}
#define SAFERELEASETEXTURECACHE(x)		{if(x){CVOpenGLTextureCacheRelease(x); x=NULL;}}
#define SAFERELEASEOPENGLBUFFER(x)		{if(x){CVOpenGLBufferRelease(x); x=NULL;}}
#define SAFERELEASETEXTURE(x)			{if(x){CVOpenGLTextureRelease(x);x=NULL;}}

@implementation DisplayLayer

//////////////////////////////////////Init/Dealloc/////////////////////////////////////
- (id) init
{
	self = [super init];
	
	if (self) {
		bufRefs = NULL;
		bufTotal = 0;
		frameNow = -1;

		cache = NULL;

		memset(&fmt, 0, sizeof(fmt));
		fmt.aspect = kDisplayAscpectRatioInvalid;

		fillScreen = NO;
		externalAspectRatio = kDisplayAscpectRatioInvalid;

		// [self setMasksToBounds:YES];
		[self setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
		[self setDoubleSided:NO];
		[self setAsynchronous:NO];
		// The layer could not be Opaque, since it wil cover
		// the root layer for logo display
		// [self setOpaque:YES];
		
		positionOffset = NO;
		renderRatio = CGRectMake(0, 0, 1, 1);

		flagFillScrnChanged = YES;
		flagAspectRatioChanged = YES;
		flagPositionOffsetChanged = YES;
		refitBounds = YES;
	}
	return self;
}
-(id<CAAction>) actionForKey:(NSString *)event {return NULL;} // no animations for me

- (void)dealloc
{
	SAFERELEASETEXTURECACHE(cache);
	
	if (bufRefs) {
		for(;bufTotal>0;bufTotal--) {
			SAFERELEASEOPENGLBUFFER(bufRefs[bufTotal-1]);
		}
		free(bufRefs);
	}

	[super dealloc];
}

-(CIImage*) snapshot
{
	if (bufRefs && (frameNow >= 0)) {
		return [CIImage imageWithCVImageBuffer:bufRefs[frameNow]];
	}
	return nil;
}

-(NSSize) displaySize
{
	return NSMakeSize(fmt.width, fmt.height);
}

-(CGFloat) aspectRatio
{
	if (externalAspectRatio > 0) {
		return externalAspectRatio;
	} else if (fmt.aspect > 0) {
		return fmt.aspect;
	}
	return kDisplayAscpectRatioInvalid;
}

-(void) setExternalAspectRatio:(CGFloat)ar
{
	externalAspectRatio = (ar>0)?(ar):(kDisplayAscpectRatioInvalid);
	flagAspectRatioChanged = YES;
}

-(BOOL) fillScreen
{
	return fillScreen;
}

-(void) setFillScreen:(BOOL)fills
{
	fillScreen = fills;
	flagFillScrnChanged = YES;
}

-(CGPoint) positionOffsetRatio
{
	return renderRatio.origin;
}

-(void) setPositoinOffsetRatio:(CGPoint) ratio
{
	renderRatio.origin = ratio;
	flagPositionOffsetChanged = YES;
}

-(void) setPositionOffset:(BOOL)offset
{
	positionOffset = offset;
	flagPositionOffsetChanged = YES;
}

-(void) adujustToFitBounds
{
	refitBounds = YES;
}

/**
 * something about 3 methods below and this layer
 * 1. Now the layer is set as synchronous with setNeedsDisplay, 
 *    which means only the [setNeedsDisplay] is called,the layer
 *    will redraw itself.
 * 2. in [draw:frameNum], [setNeedsDisplay] was called, and this
 *    cause layer redraw once after one new frame is ready.
 * 3. [draw:frameNum] SHOULD be called NOT in the main thread, or
 *    that will block the UI or cause the playback stuttered.
 * 4. currently, [draw:frameNum] does be called in the thread rather
 *    than the main thread, since in CoreController, the Connection
 *    with mplayer-mt runs in the new thread, so actually the code runs
 *    fine now.
 * IN the future, setup a DisplayLink should be a better solution.
 */
-(int) startWithFormat:(DisplayFormat)displayFormat buffer:(char**)data total:(NSUInteger)num
{
	@synchronized(self) {
		fmt = displayFormat;

		if (data && (num > 0)) {
			CVReturn error;
			
			bufRefs = malloc(num * sizeof(CVOpenGLBufferRef));
			
			for (bufTotal=0; bufTotal<num; bufTotal++) {
				error = CVPixelBufferCreateWithBytes(NULL, fmt.width, fmt.height, fmt.pixelFormat, 
													 data[bufTotal], fmt.width * fmt.bytes, 
													 NULL, NULL, NULL, &bufRefs[bufTotal]);
				if (error != kCVReturnSuccess) {
					[self stop];
					MPLog(@"video buffer failed");
					break;
				}				
			}
		}
		flagAspectRatioChanged = YES;
	}
	return (bufRefs)?0:1;
}

-(void) draw:(NSUInteger)frameNum
{
	frameNow = frameNum;
	[self setNeedsDisplay];
}

-(void) stop
{
	@synchronized(self) {
		frameNow = -1;
		
		if (bufRefs) {
			for(;bufTotal>0;bufTotal--) {
				SAFERELEASEOPENGLBUFFER(bufRefs[bufTotal-1]);
			}
			free(bufRefs);
			bufRefs = NULL;
		}
		
		memset(&fmt, 0, sizeof(fmt));
		fmt.aspect = kDisplayAscpectRatioInvalid;
		flagAspectRatioChanged = YES;

		[self setNeedsDisplay];
	}
}

//////////////////////////////////////OpenGLLayer inherent/////////////////////////////////////
-(CGLPixelFormatObj) copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
	CGLPixelFormatObj px = NULL;
	GLint i;

	NSOpenGLPixelFormatAttribute attribs[] = {
        kCGLPFADoubleBuffer,
        kCGLPFAAccelerated,
        kCGLPFANoRecovery,
        kCGLPFAColorSize, 24,
        kCGLPFAAlphaSize, 8,
        kCGLPFADepthSize, 24,
        kCGLPFAWindow,
		kCGLPFADisplayMask, mask,
        0 };
	
	if (!((CGLChoosePixelFormat(attribs, &px, &i) == kCGLNoError) && px)) {
		MPLog(@"can't choose my pf");
		px = [super copyCGLPixelFormatForDisplayMask:mask];
	}
	return px;
}

-(CGLContextObj) copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
	GLint i = 1;

	CGLContextObj ctx = [super copyCGLContextForPixelFormat:pf];

	MPLog(@"ctx:%d", (ctx != 0));
	MPLog(@"pfrc:%d", CGLGetPixelFormatRetainCount(pf));
	
	CGLLockContext(ctx);

	CGLSetParameter(ctx, kCGLCPSwapInterval, &i);
	
	CGLEnable(ctx, kCGLCEMPEngine);

	SAFERELEASETEXTURECACHE(cache);
	CVReturn error = CVOpenGLTextureCacheCreate(NULL, NULL, ctx, pf, NULL, &cache);
	
	CGLUnlockContext(ctx);
	
	if(error != kCVReturnSuccess) {
		cache = NULL;
		MPLog(@"video cache create failed");
	}
	return ctx;
}

- (void)releaseCGLContext:(CGLContextObj)ctx
{
	SAFERELEASETEXTURECACHE(cache);

	[super releaseCGLContext:ctx];
}

- (void)drawInCGLContext:(CGLContextObj)glContext 
			 pixelFormat:(CGLPixelFormatObj)pixelFormat
			forLayerTime:(CFTimeInterval)timeInterval 
			 displayTime:(const CVTimeStamp *)timeStamp
{
	if (bufRefs && (frameNow >= 0)) {
	
		CVOpenGLTextureRef tex;
		
		CVReturn error = CVOpenGLTextureCacheCreateTextureFromImage(NULL, cache, bufRefs[frameNow], NULL, &tex);

		if (error == kCVReturnSuccess) {
			// draw

			CGLLockContext(glContext);	
			CGLSetCurrentContext(glContext);
			
			GLenum target = CVOpenGLTextureGetTarget(tex);

			glEnable(target);
			glBindTexture(target, CVOpenGLTextureGetName(tex));
			
			glBegin(GL_QUADS);
			
			// 直接计算layer需要的尺寸
			glTexCoord2f(		 0,			 0);	glVertex2f(-1,	 1);
			glTexCoord2f(		 0, fmt.height);	glVertex2f(-1,	-1);
			glTexCoord2f(fmt.width, fmt.height);	glVertex2f( 1,	-1);
			glTexCoord2f(fmt.width,			 0);	glVertex2f( 1,	 1);
			
			glEnd();
			
			glDisable(target);
			glFlush();

			CGLUnlockContext(glContext);

			CVOpenGLTextureRelease(tex);
			
			// This is the end of normal render routine
			return;
		}
	}
	
	// This is the routine when there is no content to render
	CGLLockContext(glContext);	
	CGLSetCurrentContext(glContext);
	
	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	glFlush();
	CGLUnlockContext(glContext);
}

-(void) display
{
	if (flagFillScrnChanged || flagAspectRatioChanged || refitBounds) {
		MPLog(@"as fil changed");
		CGRect rc = self.superlayer.bounds;
		CGFloat sAspect = [self aspectRatio];
		
		if (((sAspect * rc.size.height) > rc.size.width) == fillScreen) {
			rc.size.width = rc.size.height * sAspect;
		} else {
			rc.size.height = rc.size.width / sAspect;
		}
		
		self.bounds = rc;
		
		flagAspectRatioChanged = NO;
		flagFillScrnChanged = NO;
		refitBounds = NO;
	}
	
	if (flagPositionOffsetChanged) {
		MPLog(@"pos changed");
		CGRect rc = self.superlayer.bounds;
		CGPoint pt = CGPointMake(rc.size.width/2, rc.size.height/2);
		
		rc = self.bounds;
		
		if (positionOffset) {
			pt.x += rc.size.width  * renderRatio.origin.x;
			pt.y += rc.size.height * renderRatio.origin.y;
		}
		self.position = pt;
		
		flagPositionOffsetChanged = NO;
	}
	[super display];
}

@end
