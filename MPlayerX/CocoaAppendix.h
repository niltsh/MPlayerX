/*
 * MPlayerX - CocoaAppendix.h
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

#import <Cocoa/Cocoa.h>

#define kMPXSysVersionLion			 (7)
#define kMPXSysVersionMavericks  (9)
#define kMPXSysVersionYosemite    (10)

extern NSString * const kMPCStringMPlayerX;

#define SAFERELEASE(x)		{if(x) {[x release];x = nil;}}

void MPLog(NSString *format, ...);
void MPSetLogEnable(BOOL en);

NSOperatingSystemVersion MPXGetSysVersion();

BOOL shouldUseOldFullScreenMethod();

@interface NSMenu (CharsetListAppend)
-(void) appendCharsetList;
@end

@interface NSMenu (FontListAppend)
-(NSMenuItem*) getFontItemFromURL:(CFURLRef)url;
-(NSMenuItem*) getFontItemFromFamilyName:(CFStringRef)name;
@end

@interface NSColor (MPXAdditional)
-(uint32) hexValue;
@end

@interface NSString (MPXAdditional)
-(unsigned int)hexValue;
@end

@interface NSEvent (MPXAdditional)
+(NSEvent*) makeKeyDownEvent:(NSString*)str modifierFlags:(NSUInteger)flags;
@end

@interface NSFileManager (MPXAdditional)
+(NSString*) UserPath:(NSSearchPathDirectory)dir WithSuffix:(NSString*)suffix;
@end

@interface NSObject (MPXAdditional)
-(void) showAlertPanelModal:(NSString*) str;
@end

NSImage* MPCreateNSImageFromCIImage(CIImage *ciImage);
