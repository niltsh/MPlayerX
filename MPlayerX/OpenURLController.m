/*
 * MPlayerX - OpenURLController.m
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
#import "LocalizedStrings.h"
#import "OpenURLController.h"
#import "PlayerController.h"

NSString * const kBookmarkURLKey	= @"Bookmark:URL";

NSString * const kStringURLSchemaHttp	= @"http";
NSString * const kStringURLSchemaFtp	= @"ftp";
NSString * const kStringURLSchemaMms	= @"mms";
NSString * const kStringURLSchemaRtsp	= @"rtsp";

@implementation OpenURLController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithBool:YES], kUDKeyFFMpegHandleStream,
	  nil]];
}

-(void) initURLList:(NSDictionary*)list
{
	[urlBox removeAllItems];
	
	NSArray *urls = [list objectForKey:kBookmarkURLKey];

	if (urls) {
		[urlBox addItemsWithObjectValues:urls];
	}
	
	[urlBox addItemWithObjectValue:kMPXStringURLPanelClearMenu];
}

-(void) addUrl:(NSString*)urlString
{
	NSInteger idx = [urlBox indexOfItemWithObjectValue:urlString];
	
	if (idx != 0) {
		// 如果不存在，或者不在第一位的话
		if (idx != NSNotFound) {
			// 本来就有这个string就删除这个string，然后添加到第一位
			[urlBox removeItemAtIndex:idx];
		}

		[urlBox insertItemWithObjectValue:urlString atIndex:0];	
	}
}

-(void) syncToBookmark:(NSMutableDictionary*)bmk
{
	NSArray *urls = [urlBox objectValues];
	
	[bmk setObject:[urls subarrayWithRange:NSMakeRange(0, [urls count]-1)] forKey:kBookmarkURLKey];
}

-(IBAction) urlSelected:(id)sender
{
	if ([sender indexOfSelectedItem] == ([[sender objectValues] count]-1)) {
		[sender removeAllItems];
		[sender addItemWithObjectValue:kMPXStringURLPanelClearMenu];
		[sender setStringValue:@""];
	}
}

-(IBAction) openURL:(id) sender
{
	// since this is a modal method, it is safe to set the cmdOptionalText
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyFFMpegHandleStream]) {
		[cmdOptionalText setStringValue:kMPXStringUseMPlayerHandleStream];
	} else {
		[cmdOptionalText setStringValue:kMPXStringUseFFMpegHandleStream];
	}

	if ([NSApp runModalForWindow:openURLPanel] == NSFileHandlingPanelOKButton) {
		// 现在mplayer的在线播放的功能不是很稳定，经常freeze，因此先禁用这个功能
		[playerController loadFiles:[NSArray arrayWithObject:[urlBox stringValue]] fromLocal:NO];
	}
}

-(IBAction) confirmed:(id) sender
{
	NSURL *url = [NSURL URLWithString:[urlBox stringValue]];

	NSString *scheme = [[url scheme] lowercaseString];
	
	if (scheme && ([scheme isEqualToString:kStringURLSchemaHttp] || [scheme isEqualToString:kStringURLSchemaFtp] || 
				   [scheme isEqualToString:kStringURLSchemaRtsp] || [scheme isEqualToString:kStringURLSchemaMms])) {
		// 先修正URL
		[urlBox setStringValue:[[url standardizedURL] absoluteString]];
		// 退出Modal模式
		[NSApp stopModalWithCode:NSFileHandlingPanelOKButton];
		// 隐藏窗口
		[openURLPanel orderOut:self];
	} else {
		NSBeginAlertSheet(kMPXStringError, kMPXStringOK, nil, nil, openURLPanel, nil, nil, nil, nil, kMPXStringURLNotSupported);
	}
}

-(IBAction) canceled:(id) sender
{
	[NSApp abortModal];
	[openURLPanel orderOut:self];
}

@end
