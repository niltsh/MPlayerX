/*
 * MPlayerX - OpenURLController.m
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

#import "UserDefaults.h"
#import "LocalizedStrings.h"
#import "OpenURLController.h"
#import "PlayerController.h"
#import "CocoaAppendix.h"
#import "def.h"

NSString * const kBookmarkURLKey	= @"Bookmark:URL";

NSString * const kStringURLSchemaHttp	= @"http";
NSString * const kStringURLSchemaHttps	= @"https";
NSString * const kStringURLSchemaFtp	= @"ftp";
NSString * const kStringURLSchemaMms	= @"mms";
NSString * const kStringURLSchemaRtsp	= @"rtsp";
NSString * const kStringURLSchemaRtp	= @"rtp";
NSString * const kStringURLSchemaUdp	= @"udp";

@implementation OpenURLController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithBool:YES], kUDKeyFFMpegHandleStream,
	  nil]];
}

-(id) init
{
    self = [super init];
    if (self) {
        yt = [[YTDL alloc] initWithBinPath:[[[NSBundle mainBundle] URLForResource:@"ytdl" withExtension:nil] path]];
        [yt setDelegate:self];
    }
    return self;
}

-(void) dealloc
{
    [yt release];
    [super dealloc];
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

-(void) awakeFromNib
{
    // the panel should ontop of player window
    [openURLPanel setLevel:NSTornOffMenuWindowLevel];
}

-(void) addCurrentURLToMenu
{
    NSString *urlString = [urlBox stringValue];

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
    // shoe the panel
    [openURLPanel makeKeyAndOrderFront:self];
}

-(IBAction) confirmed:(id) sender
{
	NSURL *url = [NSURL URLWithString:[[urlBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];

	NSString *scheme = [[url scheme] lowercaseString];
	
	if (scheme && ([scheme isEqualToString:kStringURLSchemaHttp] || [scheme isEqualToString:kStringURLSchemaFtp] || 
                   [scheme isEqualToString:kStringURLSchemaRtsp] || [scheme isEqualToString:kStringURLSchemaMms] ||
                   [scheme isEqualToString:kStringURLSchemaHttps]|| [scheme isEqualToString:kStringURLSchemaRtp] ||
                   [scheme isEqualToString:kStringURLSchemaUdp])) {
        // 先修正URL
        [urlBox setStringValue:[[url standardizedURL] absoluteString]];
        
        if (([scheme isEqualToString:kStringURLSchemaHttp] || [scheme isEqualToString:kStringURLSchemaHttps]) &&
            ([[url host] isEqualToString:@"www.youtube.com"] || [[url host] isEqualToString:@"www.xvideos.com"])) {
            MPLog(@"try to open: %@", [url host]);
            
            // prepare the UI
            [cancelParseButton setEnabled:YES];
            [urlParseMessage setStringValue:kMPXStringStartToParseURL];
            [progIndicator startAnimation:self];
            
            // show the sheet
            [NSApp beginSheet:urlParsingSheet
               modalForWindow:openURLPanel
                modalDelegate:nil
               didEndSelector:nil
                  contextInfo:NULL];
            
            // try to get the real URL
            [yt getInfoFromURL:[urlBox stringValue] type:kYTDLInfoTypeURL];
        } else {
            // 隐藏窗口
            [openURLPanel orderOut:self];
            // try to play the file
            [playerController loadFiles:[NSArray arrayWithObject:[urlBox stringValue]] fromLocal:NO];
            // add current URL to menu
            [self addCurrentURLToMenu];
        }
	} else {
		NSBeginAlertSheet(kMPXStringError, kMPXStringOK, nil, nil, openURLPanel, nil, nil, nil, nil, @"%@", kMPXStringURLNotSupported);
	}
}

-(IBAction) canceled:(id) sender
{
	[openURLPanel orderOut:self];
}

-(IBAction) cancelParsing:(id)sender
{
    // disble the button to avoid clicked more than once
    [cancelParseButton setEnabled:NO];
    
    [yt cancel];
    
    [progIndicator stopAnimation:self];
    
    [NSApp endSheet:urlParsingSheet];
    [urlParsingSheet orderOut:self];
}

-(void) processYTDLResult:(NSString*)urlString
{
    [progIndicator stopAnimation:self];
    [NSApp endSheet:urlParsingSheet];
    [urlParsingSheet orderOut:self];
    
    if (urlString) {
        // there is a url so try to play it
        [openURLPanel orderOut:self];
        [playerController loadFiles:[NSArray arrayWithObject:urlString] fromLocal:NO];
        
        // add current URL to menu
        [self addCurrentURLToMenu];
        
        // try to get the media title
        [yt getInfoFromURL:[urlBox stringValue] type:kYTDLInfoTypeTitle];
    } else {
        // there no url
    }
}

-(void) ytdl:(id)obj gotInfo:(NSDictionary *)info
{
    if ([[info objectForKey:kYTDLInfoTypeKey] unsignedIntegerValue] == kYTDLInfoTypeURL) {
        // got the url
        [cancelParseButton setEnabled:NO];
        
        if ([[info objectForKey:kYTDLInfoIsErrorKey] boolValue]) {
            // some error
            [urlParseMessage setStringValue:[NSString stringWithFormat:kMPXStringParseURLErrorFmt, [info objectForKey:kYTDLInfoContentKey]]];
            [progIndicator stopAnimation:self];
            
            [self performSelector:@selector(processYTDLResult:) 
                       withObject:nil
                       afterDelay:2.0
                          inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
        } else {
            // not error
            [urlParseMessage setStringValue:kMPXStringGotURL];
            
            [self performSelector:@selector(processYTDLResult:) 
                       withObject:[info objectForKey:kYTDLInfoContentKey]
                       afterDelay:1.0
                          inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
        }
    } else if ([[info objectForKey:kYTDLInfoTypeKey] unsignedIntegerValue] == kYTDLInfoTypeTitle) {
        if ([info objectForKey:kYTDLInfoContentKey]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMPCRemoteMediaInfoNotification
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [info objectForKey:kYTDLInfoContentKey], kMPCRemoteMediaInfoTitleKey,
                                                                        nil]];
        }
    }
}
@end
