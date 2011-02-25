/*
 * MPlayerX - AppController.m
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

#import "AppController.h"
#import "UserDefaults.h"
#import "CocoaAppendix.h"
#import <Sparkle/Sparkle.h>
#import "PlayerController.h"
#import "OpenURLController.h"
#import "LocalizedStrings.h"
#import "RootLayerView.h"

#define kSnapshotSaveDefaultPath	(@"~/Desktop")

/**
 * This is a sample of how to create a singleton object,
 * which could also work in Interface Builder
 *
 * - Declaration
 *   1. Nothing special but "+(AppController*) sharedAppController;" is enough,
 *      the return type of "id" would be better, but I prefer strict typing.
 *
 * - Implementation
 *    1. static AppController *sharedInstance = nil;
 *    2. static BOOL init_ed = NO;
 *       init_ed is to avoid [[ alloc] init] to initialize the static object again.
 *    3. +(AppController*) sharedAppController
 *    4. -(id) init
 *       The basic initialize method. this should be called only once.
 *    5. +(id) allocWithZone:(NSZone *)zone { return [[self sharedAppController] retain]; }
 *    6. -(id) copyWithZone:(NSZone*)zone { return self; }
 *    7. -(id) retain { return self; }
 *    8. -(NSUInteger) retainCount { return NSUIntegerMax; }
 *    9. -(void) release { }
 *   10. -(id) autorelease { return self; }
 *   11. -(void) dealloc
 *      
 */

NSString * const kMPCFMTBookmarkPath	= @"bookmarks.plist";
NSString * const kMPXFeedbackURL		= @"http://niltsh.github.com/MPlayerX/#contact";
NSString * const kMPXWikiURL			= @"https://github.com/niltsh/MPlayerX/wiki";

static AppController *sharedInstance = nil;
static BOOL init_ed = NO;

@implementation AppController

@synthesize bookmarks;
@synthesize supportVideoFormats;
@synthesize supportAudioFormats;
@synthesize supportSubFormats;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   @"http://mplayerx.googlecode.com/svn/trunk/update/appcast.xml", @"SUFeedURL",
					   [NSNumber numberWithBool:NO], kUDKeyLogMode,
					   kSnapshotSaveDefaultPath, kUDKeySnapshotSavePath,
					   nil]];

	MPSetLogEnable([[NSUserDefaults standardUserDefaults] boolForKey:kUDKeyLogMode]);
}
					   
+(AppController*) sharedAppController
{
	if (sharedInstance == nil) {
		sharedInstance = [[super allocWithZone:nil] init];
	}
	return sharedInstance;
}

-(id) init
{
	if (init_ed == NO) {
		init_ed = YES;

		ud = [NSUserDefaults standardUserDefaults];
		notifCenter = [NSNotificationCenter defaultCenter];
		
		/////////////////////////setup auto update////////////////////
		// 设定手动更新
		[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:NO];
		
		NSBundle *mainBundle = [NSBundle mainBundle];
		// 建立支持格式的Set
		for( NSDictionary *dict in [mainBundle objectForInfoDictionaryKey:@"CFBundleDocumentTypes"]) {
			
			NSString *obj = [dict objectForKey:@"CFBundleTypeName"];
			// 对不同种类的格式
			if ([obj isEqualToString:@"Audio Media"]) {
				// 如果是音频文件
				supportAudioFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
				
			} else if ([obj isEqualToString:@"Video Media"]) {
				// 如果是视频文件
				supportVideoFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
			} else if ([obj isEqualToString:@"Subtitle"]) {
				// 如果是字幕文件
				supportSubFormats = [[NSSet alloc] initWithArray:[dict objectForKey:@"CFBundleTypeExtensions"]];
			}
		}
		
		/////////////////////////setup bookmarks////////////////////
		// 得到书签的文件名
		NSString *lastStoppedTimePath = [[NSFileManager applicationSupportPathWithSuffix:kMPCStringMPlayerX] stringByAppendingPathComponent:kMPCFMTBookmarkPath];

		// 得到记录播放时间的dict
		bookmarks = [[NSMutableDictionary alloc] initWithContentsOfFile:lastStoppedTimePath];
		if (!bookmarks) {
			// 如果文件不存在或者格式非法
			bookmarks = [[NSMutableDictionary alloc] initWithCapacity:10];
		}
	}
	return self;
}

+(id) allocWithZone:(NSZone *)zone { return [[self sharedAppController] retain]; }
-(id) copyWithZone:(NSZone*)zone { return self; }
-(id) retain { return self; }
-(NSUInteger) retainCount { return NSUIntegerMax; }
-(void) release { }
-(id) autorelease { return self; }

-(void) dealloc
{
	[supportVideoFormats release];
	[supportAudioFormats release];
	[supportSubFormats release];
	
	[bookmarks release];
	
	sharedInstance = nil;
	
	[super dealloc];
}

-(void) awakeFromNib
{
	// setup url list for OpenURL Panel
	[openUrlController initURLList:bookmarks];
}

-(BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(moveToTrash:)) {
		return ([playerController lastPlayedPath] != nil);
	}
	return YES;
}
/////////////////////////////////////Actions//////////////////////////////////////
-(IBAction) openFile:(id) sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setResolvesAliases:NO];
	// 现在还不支持播放列表，因此禁用多选择
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:kMPXStringOpenMediaFiles];
	
	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		[playerController loadFiles:[openPanel URLs] fromLocal:YES];
	}
}

-(IBAction) gotoWikiPage:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kMPXWikiURL]];
}

-(IBAction) writeSnapshotToFile:(id)sender
{
	// 得到图像数据
	CIImage *snapshot = [dispView snapshot];
	
	if (snapshot != nil) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		// 得到图像的Rep
		NSBitmapImageRep *imRep = [[NSBitmapImageRep alloc] initWithCIImage:snapshot];
		// 设定这个Rep的存储方式
		NSData *imData = [NSBitmapImageRep representationOfImageRepsInArray:[NSArray arrayWithObject:imRep]
																  usingType:NSPNGFileType
																 properties:nil];
		// 得到存储文件夹
		NSString *savePath = [ud stringForKey:kUDKeySnapshotSavePath];
		
		// 如果是默认路径，那么就更换为绝对地址
		if ([savePath isEqualToString:kSnapshotSaveDefaultPath]) {
			savePath = [savePath stringByExpandingTildeInPath];
		}
		NSString *mediaPath = ([playerController.lastPlayedPath isFileURL])?([playerController.lastPlayedPath path]):([playerController.lastPlayedPath absoluteString]);
		// 创建文件名
		// 修改文件名中的：，因为：无法作为文件名存储
		savePath = [NSString stringWithFormat:@"%@/%@_%@.png",
					savePath, 
					[[mediaPath lastPathComponent] stringByDeletingPathExtension],
					[[NSDateFormatter localizedStringFromDate:[NSDate date]
													dateStyle:NSDateFormatterMediumStyle
													timeStyle:NSDateFormatterMediumStyle] 
					 stringByReplacingOccurrencesOfString:@":" withString:@"."]];							   
		// 写文件
		[imData writeToFile:savePath atomically:YES];
		[imRep release];
		[pool drain];
	}
}

-(IBAction) moveToTrash:(id) sender
{
	NSURL *path = [[playerController lastPlayedPath] retain];
		
	if (path && [path isFileURL]) {
		[playerController stop];
		[[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:path] completionHandler:nil];
	}
	[path release];
}

-(IBAction) donate:(id)sender
{
	NSArray *langs = [NSLocale preferredLanguages];
	NSString *currency = nil;
	
	if (langs && [[langs objectAtIndex:0] isEqualToString:@"ja"]) {
		MPLog(@"Japanese user");
		currency = @"JPY";
	} else {
		currency = @"USD";
	}

	[[NSWorkspace sharedWorkspace] openURL:
	 [NSURL URLWithString:[NSString stringWithFormat:
						   @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mplayerx%%2eqzy%%40gmail%%2ecom&lc=US&item_name=MPlayerX&no_note=0&currency_code=%@&bn=PP%%2dDonationsBF%%3abtn_donate_LG%2egif%%3aNonHostedGuest", currency]]];
}

-(IBAction) gotoFeedbackPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kMPXFeedbackURL]];
}

/////////////////////////////////////Application Delegate//////////////////////////////////////
-(BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	[playerController loadFiles:[NSArray arrayWithObject:filename] fromLocal:YES];
	return YES;
}

-(void) application:(NSApplication *)theApplication openFiles:(NSArray *)filenames
{
	[playerController loadFiles:filenames fromLocal:YES];
	[theApplication replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

-(NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	[playerController stop];
	
	[ud synchronize];

	NSString *lastStoppedTimePath = [[NSFileManager applicationSupportPathWithSuffix:kMPCStringMPlayerX] stringByAppendingPathComponent:kMPCFMTBookmarkPath];

	[openUrlController syncToBookmark:bookmarks];
	
	[bookmarks writeToFile:lastStoppedTimePath atomically:YES];
	
	return NSTerminateNow;	
}

-(void) applicationDidFinishLaunching:(NSNotification *)notification
{
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

@end
