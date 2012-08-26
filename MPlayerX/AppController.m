/*
 * MPlayerX - AppController.m
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

#import "AppController.h"
#import "UserDefaults.h"
#import "CocoaAppendix.h"
#import "PlayerController.h"
#import "OpenURLController.h"
#import "LocalizedStrings.h"
#import "RootLayerView.h"
#import "SPMediaKeyTap.h"
#import "AODetector.h"
#import "def.h"

#import <Sparkle/Sparkle.h>
#import <CoreServices/CoreServices.h>

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
NSString * const kMPXFeedbackURL		= @"http://mplayerx.org/support.html";
NSString * const kMPXWikiURL			= @"http://mplayerx.org/support.html";
NSString * const kMPXEAFPlaceHolder		= @"";

static AppController *sharedInstance = nil;
static BOOL init_ed = NO;

@implementation AppController

@synthesize bookmarks;

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithBool:NO], kUDKeyLogMode,
					   kMPXSnapshotSaveDefaultPath, kUDKeySnapshotSavePath,
					   @"NO", @"AppleMomentumScrollSupported",
					   [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
					   [NSNumber numberWithBool:YES], kUDKeyEnableMediaKeyTap,
					   [NSNumber numberWithBool:NO], kUDKeyDisableLastStopBookmark,
                       [NSNumber numberWithInt:kMPSnapshotFormatPNG], kUDKeySnapshotFormat,
                       @"https://raw.github.com/niltsh/MPlayerX-Deploy/master/appcast.xml", @"SUFeedURL",
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
        
        if (self = [super init]) {
            NSDictionary *dict;
            
            ud = [NSUserDefaults standardUserDefaults];
            notifCenter = [NSNotificationCenter defaultCenter];
                        
            /////////////////////////setup bookmarks////////////////////
            // 得到书签的文件名
            NSString *lastStoppedTimePath = [[NSFileManager UserPath:NSApplicationSupportDirectory WithSuffix:kMPCStringMPlayerX] stringByAppendingPathComponent:kMPCFMTBookmarkPath];
            
            // 得到记录播放时间的dict
            bookmarks = [[NSMutableDictionary alloc] initWithContentsOfFile:lastStoppedTimePath];
            if (!bookmarks) {
                // 如果文件不存在或者格式非法
                bookmarks = [[NSMutableDictionary alloc] initWithCapacity:10];
            }
            keyTap = nil;
            trashSound = nil;
            
            dict = [[NSBundle mainBundle] infoDictionary];
            subExts = [[NSSet alloc] initWithArray:[dict objectForKey:@"SupportedSubtitleExtensions"]]; 
            playableExts = [[NSSet alloc] initWithArray:[dict objectForKey:@"SupportedAVExtensions"]];
            // MPLog(@"Sub %@ \n AV %@", subExts, playableExts);
        }
	}
	return self;
}

+(id) allocWithZone:(NSZone *)zone { return [[self sharedAppController] retain]; }
-(id) copyWithZone:(NSZone*)zone { return self; }
-(id) retain { return self; }
-(NSUInteger) retainCount { return NSUIntegerMax; }
-(oneway void) release { }
-(id) autorelease { return self; }

-(void) dealloc
{
	[bookmarks release];
	[keyTap release];
    [trashSound release];
    [subExts release];
    [playableExts release];

	sharedInstance = nil;
	
	[super dealloc];
}

-(void) awakeFromNib
{
	// setup url list for OpenURL Panel
	[openUrlController initURLList:bookmarks];
	
	if ([ud boolForKey:kUDKeyDisableLastStopBookmark]) {
		// disable bookmark completely
		[bookmarks removeAllObjects];
	}
	
	[externalAudioFilePath setStringValue:kMPXEAFPlaceHolder];
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
	[openPanel setAccessoryView:openPanelAccView];
	
	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		
		BOOL isDir = YES;
		if ([[NSFileManager defaultManager] fileExistsAtPath:[externalAudioFilePath stringValue] isDirectory:&isDir] &&
			(!isDir)) {
			[playerController setExternalAudioFilePath:[externalAudioFilePath stringValue]];
		}
		// 这里也可能是打开dvdmedia这样的文件夹，因此将打开文件动作放到application的delegate方法中打开文件。
		NSString *fileUrl = [[[openPanel URLs] objectAtIndex:0] path];
		
		if ([[[fileUrl pathExtension] lowercaseString] isEqualToString:@"dvdmedia"]) {
			[playerController setPlayDisk:kPMPlayDiskDVD];
			[playerController loadFiles:[openPanel URLs] fromLocal:YES];
			[playerController setPlayDisk:kPMPlayDiskNone];
		} else {
			[playerController loadFiles:[openPanel URLs] fromLocal:YES];
		}
		// 如果选定了audiofile，就清除
		[externalAudioFilePath setStringValue:kMPXEAFPlaceHolder];
	}
}

-(IBAction) openExternalAudioFile:(id)sender
{
	NSOpenPanel *openEAF = [NSOpenPanel openPanel];
	[openEAF setCanChooseFiles:YES];
	[openEAF setCanChooseDirectories:NO];
	[openEAF setResolvesAliases:NO];
	[openEAF setAllowsMultipleSelection:NO];
	[openEAF setCanCreateDirectories:NO];
	[openEAF setTitle:kMPXStringOpenMediaFiles];
	
	[openEAF beginSheetModalForWindow:[sender window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[externalAudioFilePath setStringValue:[[[openEAF URLs] objectAtIndex:0] path]];
		}
	}];
}

-(IBAction) openVIDEOTS:(id) sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setResolvesAliases:NO];
	// 现在还不支持播放列表，因此禁用多选择
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setTitle:kMPXStringOpenVideo_TS];
	
	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		[playerController setPlayDisk:kPMPlayDiskDVD];
		[playerController loadFiles:[openPanel URLs] fromLocal:YES];
		[playerController setPlayDisk:kPMPlayDiskNone];
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
        
        NSInteger destination = [ud integerForKey:kUDKeySnapshotFormat];
        
        if (destination == kMPSnapshotFormatPasteBoard) {
            // save to pasteboard
            NSImage *im = MPCreateNSImageFromCIImage(snapshot);
            if (im) {
                NSPasteboard *pb = [NSPasteboard generalPasteboard];
                [pb clearContents];
                [pb writeObjects:[NSArray arrayWithObject:im]];
                [im release];
            }
        } else {
            // save to file
            NSBitmapImageFileType fmt;
            NSString *ext;
            
            switch (destination) {
                case kMPSnapshotFormatBMP:
                    fmt = NSBMPFileType;
                    ext = @"bmp";
                    break;
                case kMPSnapshotFormatJPEG:
                    fmt = NSJPEGFileType;
                    ext = @"jpg";
                    break;
                case kMPSnapshotFormatTIFF:
                    fmt = NSTIFFFileType;
                    ext = @"tiff";
                    break;
                default:
                    fmt = NSPNGFileType;
                    ext = @"png";
                    break;
            }
            
            // 得到存储文件夹
            NSString *savePath = [[ud stringForKey:kUDKeySnapshotSavePath] stringByExpandingTildeInPath];
            
            NSFileManager *fm = [NSFileManager defaultManager];
            BOOL isDir = NO;
            if ([fm fileExistsAtPath:savePath isDirectory:&isDir] && (!isDir)) {
                // 如果存在但不是文件夹的话
                [fm removeItemAtPath:savePath error:NULL];
            }
            if (!isDir) {
                // 如果原来不存在这个文件夹或者存在的是文件的话，都需要重建文件夹
                if (![fm createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:NULL]) {
                    savePath = nil;
                }
            }
            
            if (savePath) {
                NSString *mediaPath = nil;
				
				if ([playerController.lastPlayedPath isFileURL]) {
					mediaPath = [playerController.lastPlayedPath path];
				} else {
					mediaPath = [[playerController mediaInfo].metaData objectForKey:@"title"];
					if (!mediaPath) {
						mediaPath = [playerController.lastPlayedPath absoluteString];
					}
					NSLog(@"mediaPath: %s", [mediaPath fileSystemRepresentation]);
				}
				mediaPath = [[mediaPath lastPathComponent] stringByDeletingPathExtension];
				
                NSString *dateTime = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                    dateStyle:NSDateFormatterMediumStyle
                                                                    timeStyle:NSDateFormatterMediumStyle];
                dateTime = [dateTime stringByReplacingOccurrencesOfString:@":" withString:@"."];
                dateTime = [dateTime stringByReplacingOccurrencesOfString:@"/" withString:@"."];
                
                // 创建文件名
                // 修改文件名中的：，因为：无法作为文件名存储
                savePath = [NSString stringWithFormat:@"%@/%@_%@.%@", 
                            savePath, 
                            mediaPath,
                            dateTime,
                            ext];
                // 得到图像的Rep
                NSBitmapImageRep *imRep = [[NSBitmapImageRep alloc] initWithCIImage:snapshot];
                // 设定这个Rep的存储方式
                NSData *imData = [NSBitmapImageRep representationOfImageRepsInArray:[NSArray arrayWithObject:imRep]
                                                                          usingType:fmt
                                                                         properties:nil];
                // 写文件
                [imData writeToFile:savePath atomically:YES];
                [imRep release];			
            }
        }
		[pool drain];
	}
}

-(IBAction) moveToTrash:(id) sender
{
	NSURL *path = [[playerController lastPlayedPath] retain];
    
	if (path && [path isFileURL]) {
		[playerController stop];
		[[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:path] completionHandler:^(NSDictionary *newURLs, NSError *error) {
            if (!trashSound) {
                trashSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForSoundResource:@"drop-trash-sound"] byReference:YES];
                [trashSound setLoops:NO];
            }
            [trashSound play];
        }];
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
						   @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mplayerx%%2eqzy%%40gmail%%2ecom&lc=US&item_name=MPlayerX&no_note=0&currency_code=%@&bn=PP%%2dDonationsBF%%3abtn_donate_LG%%2egif%%3aNonHostedGuest", currency]]];
}

-(IBAction) gotoFeedbackPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kMPXFeedbackURL]];
}

-(IBAction) checkForUpdate:(id)sender
{
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}

-(BOOL) isFilePlayable:(NSString*)path
{
    if (path) {
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSString *type = [ws typeOfFile:path error:NULL];
        if ((type && [ws type:type conformsToType:(NSString*)kUTTypeAudiovisualContent]) ||
            [playableExts containsObject:[[path pathExtension] lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL) isFileSubtitle:(NSString*)path
{
    if (path) {
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSString *type = [ws typeOfFile:path error:NULL];

        if ((type && [ws type:type conformsToType:(NSString*)kUTTypePlainText]) ||
            [subExts containsObject:[[path pathExtension] lowercaseString]]) {
            // 如果文件是文本文件，或者扩展名OK
            return YES;
        }
    }
    return NO;
}

//////////////////////////////////////Media Key Delegate//////////////////////////////////////
-(void) mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event
{
	NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
	// here be dragons...
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	int keyRepeat = (keyFlags & 0x1);
	
	if (!keyRepeat) {
		switch (keyCode) {
			case NX_KEYTYPE_PLAY:
				if (keyIsPressed == NO) {
					MPLog(@"Media Key: play/pause");
					[[NSNotificationCenter defaultCenter] postNotificationName:kMPXMediaKeyPlayPauseNotification object:NSApp];
				}
				break;
			case NX_KEYTYPE_FAST:
				if (keyIsPressed == YES) {
					MPLog(@"Media Key: forward");
					[[NSNotificationCenter defaultCenter] postNotificationName:kMPXMediaKeyForwardNotification object:NSApp];
				}
				break;
			case NX_KEYTYPE_REWIND:
				if (keyIsPressed == YES) {
					MPLog(@"Media Key: backward");
					[[NSNotificationCenter defaultCenter] postNotificationName:kMPXMediaKeyBackwardNotification object:NSApp];
				}
				break;
			default:
				MPLog(@"Media Key %d pressed", keyCode);
				break;
		}
	}
}
/////////////////////////////////////Application Delegate//////////////////////////////////////
-(BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	BOOL isDir = NO, ret = NO;
	
	// 这里判断文件是否存在，是为了给command line arguments做准备
	if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir]) {
		if (isDir) {
			[playerController setPlayDisk:kPMPlayDiskDVD];
			[playerController loadFiles:[NSArray arrayWithObject:filename] fromLocal:YES];
			[playerController setPlayDisk:kPMPlayDiskNone];
		} else {
			[playerController loadFiles:[NSArray arrayWithObject:filename] fromLocal:YES];
		}
		ret = YES;
	}
	return ret;
}

-(void) application:(NSApplication *)theApplication openFiles:(NSArray *)filenames
{
	BOOL isDir = NO;
	NSApplicationDelegateReply reply = NSApplicationDelegateReplyFailure;
	
	// 这里判断文件是否存在，是为了给command line arguments做准备
	if ([[NSFileManager defaultManager] fileExistsAtPath:[filenames objectAtIndex:0] isDirectory:&isDir]) {
		if (isDir) {
			[playerController setPlayDisk:kPMPlayDiskDVD];
			[playerController loadFiles:filenames fromLocal:YES];
			[playerController setPlayDisk:kPMPlayDiskNone];
		} else {
			[playerController loadFiles:filenames fromLocal:YES];
		}
		reply = NSApplicationDelegateReplySuccess;
	}
	[theApplication replyToOpenOrPrint:reply];
}

-(NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	if (keyTap) {
		[keyTap stopWatchingMediaKeys];
	}
	
	[playerController stop];
	
	[ud synchronize];

	[openUrlController syncToBookmark:bookmarks];
	
	[bookmarks writeToFile:[[NSFileManager UserPath:NSApplicationSupportDirectory WithSuffix:kMPCStringMPlayerX] stringByAppendingPathComponent:kMPCFMTBookmarkPath]
				atomically:YES];
	
	// 先不起用监听功能
	// [[AODetector defaultDetector] stopListening];
	
	return NSTerminateNow;	
}

-(void) applicationDidFinishLaunching:(NSNotification *)notification
{
	if ([ud boolForKey:kUDKeyEnableMediaKeyTap]) {
		keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
		if ([SPMediaKeyTap usesGlobalMediaKeyTap]) {
			[keyTap startWatchingMediaKeys];
		} else {
			MPLog(@"MediaKey monitoring Disabled.");
		}
	}
	
	// 开始监听AudioDevice
	// 如果是双击文件打开程序的话，application:(NSApplication *)theApplication openFile:(NSString *)filename 会在 这个method之前被调用
	// 也就是说，在startListening之前，就要开始play了
	// 但是没有关系，即使不listen，playerController在播放的时候因为是调用[AODetector defaultDetector]，会强制判断一次是否是digital，所以不会有问题
	// 将这个method放到这里是因为不想耽误启动的时间
	// 先不起用监听功能
	// [[AODetector defaultDetector] startListening];
	
	NSString *cmdStr;
	
	cmdStr = [ud stringForKey:@"url"];
	
	if (cmdStr) {
		MPLog(@"url:%@", cmdStr);
		
		[playerController loadFiles:[NSArray arrayWithObject:cmdStr] fromLocal:NO];
		
	} else {
		cmdStr = [ud stringForKey:@"file"];
		
		if (cmdStr) {
			MPLog(@"file:%@", cmdStr);
			[self application:NSApp openFile:cmdStr];
		}
	}

    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

@end
