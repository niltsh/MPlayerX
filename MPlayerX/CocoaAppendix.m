/*
 * MPlayerX - CocoaAppendix.m
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

#import "CocoaAppendix.h"
#import "LocalizedStrings.h"

static BOOL logEnable = NO;

void MPLog(NSString *format, ...)
{
	if (logEnable) {
		va_list pl;
		va_start(pl, format);
		
		NSLogv(format, pl);

		va_end(pl);
	}
}

void MPSetLogEnable(BOOL en)
{
	logEnable = en;
}

@implementation NSColor (MPXAdditional)
-(uint32) hexValue
{
	NSColor *col = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	return ((((uint32)(255 * [col redComponent]))  <<24) + 
			(((uint32)(255 * [col greenComponent]))<<16) + 
			(((uint32)(255 * [col blueComponent])) <<8)  +
			((uint32)(255 * (1-[col alphaComponent]))));
}
@end

@implementation NSMenu (CharsetListAppend)

-(void) appendCharsetList
{
	NSMenuItem *mItem;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncUTF8];
	[mItem setTag:kCFStringEncodingUTF8];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncUTF16BE];
	[mItem setTag:kCFStringEncodingUTF16BE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncUTF16LE];
	[mItem setTag:kCFStringEncodingUTF16LE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncUTF32BE];
	[mItem setTag:kCFStringEncodingUTF32BE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncUTF32LE];
	[mItem setTag:kCFStringEncodingUTF32LE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_6];
	[mItem setTag:kCFStringEncodingISOLatinArabic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1256];
	[mItem setTag:kCFStringEncodingWindowsArabic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacArabic];
	[mItem setTag:kCFStringEncodingMacArabic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_4];
	[mItem setTag:kCFStringEncodingISOLatin4];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_13];
	[mItem setTag:kCFStringEncodingISOLatin7];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1257];
	[mItem setTag:kCFStringEncodingWindowsBalticRim];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_14];
	[mItem setTag:kCFStringEncodingISOLatin8];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacCeltic];
	[mItem setTag:kCFStringEncodingMacCeltic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_2];
	[mItem setTag:kCFStringEncodingISOLatin2];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_16];
	[mItem setTag:kCFStringEncodingISOLatin10];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1250];
	[mItem setTag:kCFStringEncodingWindowsLatin2];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacCentralEuro];
	[mItem setTag:kCFStringEncodingMacCentralEurRoman];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncGB18030];
	[mItem setTag:kCFStringEncodingGB_18030_2000];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc2022_CN];
	[mItem setTag:kCFStringEncodingISO_2022_CN];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncEUC_CN];
	[mItem setTag:kCFStringEncodingEUC_CN];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin936];
	[mItem setTag:kCFStringEncodingDOSChineseSimplif];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacCNSimp];
	[mItem setTag:kCFStringEncodingMacChineseSimp];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncBIG5];
	[mItem setTag:kCFStringEncodingBig5];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncBIG5_HKSCS];
	[mItem setTag:kCFStringEncodingBig5_HKSCS_1999];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncEUC_TW];
	[mItem setTag:kCFStringEncodingEUC_TW];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin950];
	[mItem setTag:kCFStringEncodingDOSChineseTrad];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacCNTrad];
	[mItem setTag:kCFStringEncodingMacChineseTrad];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_5];
	[mItem setTag:kCFStringEncodingISOLatinCyrillic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1251];
	[mItem setTag:kCFStringEncodingWindowsCyrillic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacCyrillic];
	[mItem setTag:kCFStringEncodingMacCyrillic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncKOI8_R];
	[mItem setTag:kCFStringEncodingKOI8_R];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncKOI8_U];
	[mItem setTag:kCFStringEncodingKOI8_U];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_7];
	[mItem setTag:kCFStringEncodingISOLatinGreek];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1253];
	[mItem setTag:kCFStringEncodingWindowsGreek];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacGreek];
	[mItem setTag:kCFStringEncodingMacGreek];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_8];
	[mItem setTag:kCFStringEncodingISOLatinHebrew];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1255];
	[mItem setTag:kCFStringEncodingWindowsHebrew];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacHebrew];
	[mItem setTag:kCFStringEncodingMacHebrew];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncShift_JIS];
	[mItem setTag:kCFStringEncodingShiftJIS];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc2022_JP];
	[mItem setTag:kCFStringEncodingISO_2022_JP];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncEUC_JP];
	[mItem setTag:kCFStringEncodingEUC_JP];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin932];
	[mItem setTag:kCFStringEncodingDOSJapanese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacJpn];
	[mItem setTag:kCFStringEncodingMacJapanese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc2022_KR];
	[mItem setTag:kCFStringEncodingISO_2022_KR];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncEUC_KR];
	[mItem setTag:kCFStringEncodingEUC_KR];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin949];
	[mItem setTag:kCFStringEncodingDOSKorean];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacKor];
	[mItem setTag:kCFStringEncodingMacKorean];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_3];
	[mItem setTag:kCFStringEncodingISOLatin3];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_11];
	[mItem setTag:kCFStringEncodingISOLatinThai];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin874];
	[mItem setTag:kCFStringEncodingDOSThai];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacThai];
	[mItem setTag:kCFStringEncodingMacThai];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_9];
	[mItem setTag:kCFStringEncodingISOLatin5];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1254];
	[mItem setTag:kCFStringEncodingWindowsLatin5];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacTur];
	[mItem setTag:kCFStringEncodingMacTurkish];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1258];
	[mItem setTag:kCFStringEncodingWindowsVietnamese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacViet];
	[mItem setTag:kCFStringEncodingMacVietnamese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_1];
	[mItem setTag:kCFStringEncodingISOLatin1];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEnc8859_15];
	[mItem setTag:kCFStringEncodingISOLatin9];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncWin1252];
	[mItem setTag:kCFStringEncodingWindowsLatin1];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:kMPXStringEncMacWestEuro];
	[mItem setTag:kCFStringEncodingMacRoman];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[pool drain];
}
@end

@implementation NSString (MPXAdditional)

-(unsigned int)hexValue
{
	const char *pst = [self UTF8String];
	unsigned int res = 0;
	
	if ((*pst == '0') && ((pst[1] == 'x') || (pst[1] == 'X'))) {
		pst += 2;
	}
	while (*pst) {
		res <<= 4;
		if ((*pst >= '0') && (*pst <= '9')) {
			res += (*pst - '0');
		} else if ((*pst >= 'a') && (*pst <= 'f')) {
			res += (*pst - 'a' + 10);
		} else if ((*pst >= 'A') && (*pst <= 'F')) {
			res += (*pst - 'A' + 10);
		} else {
			res = 0;
			break;
		}
		++pst;
	}
	return res;
}
@end

@implementation NSEvent (MPXAdditional)
+(NSEvent*) makeKeyDownEvent:(NSString*)str modifierFlags:(NSUInteger)flags
{
	return [NSEvent keyEventWithType:NSKeyDown
							location:NSMakePoint(0, 0)
					   modifierFlags:flags
						   timestamp:0
						windowNumber:0
							 context:nil
						  characters:str
		 charactersIgnoringModifiers:str
						   isARepeat:NO
							 keyCode:0];
}
@end

