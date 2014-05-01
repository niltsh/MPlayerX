/*
 * MPlayerX - DisplayLayer.m
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

#import "DisplayLayer.h"
#import "CocoaAppendix.h"

#define SAFEFREE(x)						{if(x){free(x); x = NULL;}}
#define SAFERELEASETEXTURECACHE(x)		{if(x){CVOpenGLTextureCacheRelease(x); x=NULL;}}
#define SAFERELEASEOPENGLBUFFER(x)		{if(x){CVOpenGLBufferRelease(x); x=NULL;}}
#define SAFERELEASETEXTURE(x)			{if(x){CVOpenGLTextureRelease(x);x=NULL;}}

@interface DisplayLayer (DisplayLayerInternal)
-(void) reshape;
@end

@implementation DisplayLayer

@synthesize mirror;
@synthesize flip;
@synthesize refitBounds;

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

		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		
		[self setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
		[self setAsynchronous:NO];
		// The layer could not be Opaque, since it wil cover
		// the root layer for logo display
		// [self setOpaque:YES];
		
		[CATransaction commit];

		positionOffset = NO;
		scaleEnabled = NO;
		renderRatio = CGRectMake(0, 0, 1, 1);

		flagFillScrnChanged = YES;
		flagAspectRatioChanged = YES;
		flagPositionOffsetChanged = YES;
		flagScaleChanged = YES;
		refitBounds = NO;
		
		mirror = NO;
		flip = NO;
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
        CIImage *org = [CIImage imageWithCVImageBuffer:bufRefs[frameNow]];
        CIImage *dst = org;
        float inputRatio = [self originalAspectRatio] * [org extent].size.height / [org extent].size.width;
        
        if (fabsf(inputRatio - 1) >= 0.001) {
            // if there are huge error between fmt.ratio and width/height, which means SAR != 1
            CIFilter *scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
            [scaleFilter setValue:org forKey:@"inputImage"];
            [scaleFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputScale"];
            [scaleFilter setValue:[NSNumber numberWithFloat:inputRatio] forKey:@"inputAspectRatio"];
            
            dst = [scaleFilter valueForKey:@"outputImage"];
        }
        return dst;
	}
	return nil;
}

-(NSSize) displaySize
{
	NSSize sz;
	
	// 如果SAR != 1，那么得到扩大的显示尺寸
	if (fmt.width <= fmt.height * fmt.aspect) {
		sz.height = fmt.height;
		sz.width  = fmt.height * fmt.aspect;
	} else {
		sz.width  = fmt.width;
		sz.height = fmt.width / fmt.aspect;
	}

	return sz;
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

-(CGFloat) originalAspectRatio
{
	return fmt.aspect;
}

-(CGFloat) externalAspectRatio
{
	return externalAspectRatio;
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

-(void) enablePositionOffset:(BOOL)offset
{
	positionOffset = offset;
	flagPositionOffsetChanged = YES;
}

-(void) enableScale:(BOOL)en
{
	scaleEnabled = en;
	flagScaleChanged = YES;
}

-(void) setScaleRatio:(CGSize) ratio
{
	renderRatio.size = ratio;
	flagScaleChanged = YES;
}

-(CGSize) scaleRatio
{
	return renderRatio.size;
}

-(void) reshape
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	if (flagFillScrnChanged || flagAspectRatioChanged || flagScaleChanged || refitBounds) {
		MPLog(@"as fil changed");
		CGRect rc = self.superlayer.bounds;
		CGFloat sAspect = [self aspectRatio];
		
		if (((sAspect * rc.size.height) > rc.size.width) == fillScreen) {
			rc.size.width = round(rc.size.height * sAspect);
		} else {
			rc.size.height = round(rc.size.width / sAspect);
		}
		
		if (scaleEnabled) {
			rc.size.width *= renderRatio.size.width;
			rc.size.height *= renderRatio.size.height;
		}
		
		self.bounds = CGRectIntegral(rc);
		
		flagAspectRatioChanged = NO;
		flagFillScrnChanged = NO;
		flagScaleChanged = NO;
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
	[CATransaction commit];	
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
                
                // FIXME: here frame size is used to guess the color space of the image
                CVBufferSetAttachment(bufRefs[bufTotal],
                                      kCVImageBufferYCbCrMatrixKey,
                                      ((fmt.width >= 1280) || (fmt.height > 576))?(kCVImageBufferYCbCrMatrix_ITU_R_709_2):(kCVImageBufferYCbCrMatrix_ITU_R_601_4),
                                      kCVAttachmentMode_ShouldPropagate);
            }
		}
		flagAspectRatioChanged = YES;
	}
	[self setOpaque:YES];
	return (bufRefs)?0:1;
}

-(void) draw:(NSUInteger)frameNum
{
	frameNow = frameNum;
	[self display];
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
		
		// 这里不能清除externalAspectRatio
		// 因为有可能在一次播放过程中出现多次start，stop
		// 用户强制设定了externalAspectRaio的时候，即使多次start，stop也不应该重置externalAspectRatio
		// 因此应该在外部重置

		[self setNeedsDisplay];
	}
	[self setOpaque:NO];
}

//////////////////////////////////////OpenGLLayer inherent/////////////////////////////////////
-(CGLContextObj) copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
	GLint i = 1;

	CGLContextObj ctx = [super copyCGLContextForPixelFormat:pf];

	MPLog(@"ctx:%d", (ctx != 0));
	MPLog(@"pfrc:%d", CGLGetPixelFormatRetainCount(pf));
	
	CGLLockContext(ctx);

	CGLSetParameter(ctx, kCGLCPSwapInterval, &i);
	
	// CGLEnable(ctx, kCGLCEMPEngine);

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

			GLfloat cornerX, cornerY;
			
			cornerX = (mirror)?(-1):(1);
			cornerY = (flip)?(-1):(1);
			
			CGLLockContext(glContext);	
			CGLSetCurrentContext(glContext);
			
			GLenum target = CVOpenGLTextureGetTarget(tex);

			glEnable(target);
			glBindTexture(target, CVOpenGLTextureGetName(tex));
			
			glBegin(GL_QUADS);
			
			// 直接计算layer需要的尺寸
			glTexCoord2f(		 0,			 0);	glVertex2f(-cornerX,  cornerY);
			glTexCoord2f(		 0, fmt.height);	glVertex2f(-cornerX, -cornerY);
			glTexCoord2f(fmt.width, fmt.height);	glVertex2f( cornerX, -cornerY);
			glTexCoord2f(fmt.width,			 0);	glVertex2f( cornerX,  cornerY);
			
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
	[self reshape];
	[super display];
}

-(void) layoutSublayers
{
	/*
	 Called when the layer requires layout.
	 Discussion
	 The default implementation invokes the layout manager method layoutSublayersOfLayer:,
	 if a layout manager is specified and it implements that method.
	 Subclasses can override this method to provide their own layout algorithm,
	 which must set the frame of each sublayer.
	 
	 This is called when met with onLayout event,
	 since I don't have any sublayer, I could ignore this function.
	 */
}
@end
