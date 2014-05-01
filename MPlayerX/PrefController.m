/*
 * MPlayerX - PrefController.m
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
#import	"LocalizedStrings.h"
#import "PrefController.h"
#import "PlayerController.h"
#import "RootLayerView.h"
#import "ControlUIView.h"
#import "CocoaAppendix.h"
#import "def.h"
#import <ApplicationServices/ApplicationServices.h>

NSString * const PrefToolBarItemIdGeneral	= @"TBIGeneral";
NSString * const PrefToolBarItemIdVideo		= @"TBIVideo";
NSString * const PrefToolBarItemIdAudio		= @"TBIAudio";
NSString * const PrefToolBarItemIdSubtitle	= @"TBISubtitle";
NSString * const PrefToolbarItemIdNetwork	= @"TBINetwork";
NSString * const PrefToolbarItemIdAdvanced	= @"TBIAdvanced";

#define PrefTBILabelGeneral			(kMPXStringTBILabelGeneral)
#define PrefTBILabelVideo			(kMPXStringTBILabelVideo)
#define PrefTBILabelAudio			(kMPXStringTBILabelAudio)
#define PrefTBILabelSubtitle		(kMPXStringTBILabelSubtitle)
#define PrefTBILabelNetwork			(kMPXStringTBILabelNetwork)
#define PrefTBILabelAdvanced		(kMPXStringTBILabelAdvanced)

@implementation PrefController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt:0], kUDKeySelectedPrefView,
	  nil]];
}

-(id) init
{
	self = [super init];
	
	if (self) {
		ud = [NSUserDefaults standardUserDefaults];

		nibLoaded = NO;
		prefViews = nil;
	}
	return self;
}

-(IBAction) showUI:(id)sender
{
	if (!nibLoaded) {
		[NSBundle loadNibNamed:@"Pref" owner:self];
		
		[[charsetListPopup menu] removeAllItems];
		
		NSMenuItem *mItem;
		mItem = [[NSMenuItem alloc] init];
		[mItem setTitle:kMPXStringTextSubEncAskMe];
		[mItem setTag:kCFStringEncodingInvalidId];
		[mItem setEnabled:YES];
		[[charsetListPopup menu] addItem:mItem];

		[[charsetListPopup menu] addItem:[NSMenuItem separatorItem]];

		[[charsetListPopup menu] appendCharsetList];

		if ([ud boolForKey:kUDKeyTextSubtitleCharsetManual]) {
			[charsetListPopup selectItem:mItem];
		} else {
			[charsetListPopup selectItem:[[charsetListPopup menu] itemWithTag:[ud integerForKey:kUDKeyTextSubtitleCharsetFallback]]];
		}

		[mItem release];
		
		///////////////////////init font list/////////////////////////////////
		NSAutoreleasePool *fontPool = [[NSAutoreleasePool alloc] init];
		
		NSMenu *fontMenu = [fontListPopup menu];
		
		[fontMenu removeAllItems];
		
		NSMenuItem *defaultFontMItem = [fontMenu getFontItemFromURL:(CFURLRef)[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kMPCDefaultSubFontPath] isDirectory:NO]];
		if (defaultFontMItem) {
			[defaultFontMItem setRepresentedObject:kMPCDefaultSubFontPath];
			[fontMenu addItem:defaultFontMItem];
			
			[fontMenu addItem:[NSMenuItem separatorItem]];			
		}
		
		CFArrayRef fontFamilies = CTFontManagerCopyAvailableFontFamilyNames();
		
		if (fontFamilies) {
			CFIndex cnt = CFArrayGetCount(fontFamilies);
			CFIndex idx;
			
			for (idx = 0; idx < cnt; ++idx) {
				CFStringRef name = CFArrayGetValueAtIndex(fontFamilies, idx);
				mItem = [fontMenu getFontItemFromFamilyName:name];
				if (mItem) {
					[fontMenu addItem:mItem];
				}
			}
			CFRelease(fontFamilies);
		}
		
		NSString *subFontPath = [ud stringForKey:kUDKeySubFontPath];
		
		if ([subFontPath isEqualToString:kMPCDefaultSubFontPath]) {
			[fontListPopup selectItem:defaultFontMItem];
		} else {
			CFArrayRef fonts = CTFontManagerCreateFontDescriptorsFromURL((CFURLRef)[NSURL fileURLWithPath:subFontPath isDirectory:NO]);
			if (fonts) {
				CTFontDescriptorRef fontDesc = CFArrayGetValueAtIndex(fonts, 0);
				CFStringRef fontFamilyName = CTFontDescriptorCopyLocalizedAttribute(fontDesc, kCTFontFamilyNameAttribute, NULL);
				
				NSMenuItem *prefMItem = [fontListPopup itemWithTitle:(NSString*)fontFamilyName];
				
				if (prefMItem) {
					[fontListPopup selectItem:prefMItem];
				} else {
					[fontListPopup selectItem:defaultFontMItem];
					[ud setObject:kMPCDefaultSubFontPath forKey:kUDKeySubFontPath];
				}
				CFRelease(fontFamilyName);
				CFRelease(fonts);
			} else {
				[fontListPopup selectItem:defaultFontMItem];
				[ud setObject:kMPCDefaultSubFontPath forKey:kUDKeySubFontPath];
			}
		}

		[fontPool drain];

		/////////////////////////////////////////////////////////////////////
		CGFloat winH = [prefWin frame].size.height;
		
		prefViews = [[NSArray alloc] initWithObjects:viewGeneral, viewVideo, viewAudio, viewSub, viewNetwork, viewAdvanced, nil];
		
		NSToolbarItem *tbi = [[prefToolbar items] objectAtIndex:[ud integerForKey:kUDKeySelectedPrefView]];
		
		if (tbi) {
			[prefToolbar setSelectedItemIdentifier:[tbi itemIdentifier]];
			
			[self switchViews:tbi];
		}
		
		[prefWin setLevel:NSMainMenuWindowLevel];
		
		// 可以选择 透明度
		[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
		
		NSPoint org = [prefWin frame].origin;
		org.y -= (winH - [prefWin frame].size.height);
		[prefWin setFrameOrigin:org];
		
		nibLoaded = YES;
	}
	[prefWin makeKeyAndOrderFront:nil];
}

-(void) dealloc
{
	[prefViews release];
	[super dealloc];
}

-(IBAction) switchViews:(id)sender
{
	NSView *viewToShow = [prefViews objectAtIndex:[sender tag]];
	
	if (viewToShow && ([prefWin contentView] != viewToShow)) {
		
		[prefToolbar setSelectedItemIdentifier:[sender itemIdentifier]];
		
		NSRect rc = [prefWin frameRectForContentRect:[viewToShow bounds]];
		NSRect winFrm = [prefWin frame];
		
		rc.origin = winFrm.origin;
		rc.origin.y -= (rc.size.height - winFrm.size.height);
		
		[prefWin setContentView: viewToShow];
		[prefWin setFrame:rc display:YES animate:YES];

		[prefWin setTitle:[sender label]];
		
		[ud setInteger:[sender tag] forKey:kUDKeySelectedPrefView];
	}
}

-(BOOL) oldFullScreenMethod
{
    return (MPXGetSysVersion() < kMPXSysVersionMavericks);
}

- (IBAction)multiThreadChanged:(id)sender
{
	[playerController setMultiThreadMode];
}

- (IBAction)onTopModeChanged:(id)sender
{
	[dispView setPlayerWindowLevel];
}

-(IBAction) controlUIAppearanceChanged:(id)sender
{
	[controlUI refreshAutoHideTimer];
	[controlUI refreshBackgroundAlpha];
	[controlUI showUp];
}

-(IBAction) osdSetChanged:(id)sender
{
	[controlUI refreshOSDSetting];
}

-(IBAction) checkCacheFormat:(id)sender
{
	float cache = [ud floatForKey:kUDKeyCacheSize];
	
	if (cache < 0) { cache = 0; }

	[ud setInteger:((unsigned int)cache) forKey:kUDKeyCacheSize];
}

-(IBAction) letterBoxModeChanged:(id)sender
{
	NSInteger mode = [ud integerForKey:kUDKeyLetterBoxMode];
	
	if (mode != kPMLetterBoxModeNotDisplay) {
		// 如果是现实letterbox，那么更新alt
		[ud setInteger:mode forKey:kUDKeyLetterBoxModeAlt];
	}
	// 更新menu
	[controlUI toggleLetterBox:nil];
}

-(IBAction) subEncodingSchemeChanged:(id)sender
{
	NSInteger tag = [[charsetListPopup selectedItem] tag];
	
	if (tag == kCFStringEncodingInvalidId) {
		[ud setBool:YES forKey:kUDKeyTextSubtitleCharsetManual];
	} else {
		[ud setBool:NO forKey:kUDKeyTextSubtitleCharsetManual];
		[ud setInteger:tag forKey:kUDKeyTextSubtitleCharsetFallback];
	}
}

-(IBAction) fontSelected:(id)sender
{
	NSString *subFontPath = [[fontListPopup selectedItem] representedObject];
	
	[ud setObject:subFontPath forKey:kUDKeySubFontPath];
}

-(IBAction) recentMenuSettingChanged:(id)sender
{
    if (![ud boolForKey:kUDKeyEnableOpenRecentMenu]) {
        [[NSDocumentController sharedDocumentController] clearRecentDocuments:nil];
    }
}

-(IBAction) snapshotFormatChanged:(id)sender
{
    NSInteger selection = [[sender selectedItem] tag];
    
    if (selection == kMPSnapshotFormatPasteBoard) {
        // if save to pasteboard, clear the save path
        [ud setObject:@"" forKey:kUDKeySnapshotSavePath];
    } else {
        // if save to file, pop up the open panel
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        
        [panel setDelegate:self];
        
        [panel setCanChooseFiles:NO];
        [panel setCanChooseDirectories:YES];
        [panel setResolvesAliases:NO];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanCreateDirectories:YES];
        [panel setTreatsFilePackagesAsDirectories:NO];
		
		NSString *expStr = [[ud objectForKey:kUDKeySnapshotSavePath] stringByExpandingTildeInPath];
		
		if ([expStr isEqualToString:@""] ||
			(![[NSFileManager defaultManager] fileExistsAtPath:expStr])) {
			// 如果是从 pasteboard刚过来准备选的话
			// 或者现有文件夹不存在的话
			expStr = [kMPXSnapshotSaveDefaultPath stringByExpandingTildeInPath];
		}
		[panel setDirectoryURL:[NSURL fileURLWithPath:expStr isDirectory:YES]];
        
        [panel beginSheetModalForWindow:prefWin completionHandler:^(NSInteger result) {
            
            [panel setDelegate:nil];
            
            if (result == NSFileHandlingPanelOKButton) {
                NSString *path = [[[panel URLs] objectAtIndex:0] path];
                path = [path stringByAbbreviatingWithTildeInPath];
                
                [ud setObject:path forKey:kUDKeySnapshotSavePath];
            } else {
                if ([[ud objectForKey:kUDKeySnapshotSavePath] isEqualToString:@""]) {
                    // if change from pasteboard -> files, and press the cancel button
                    // the path is setted @"", so restore it to the default one
                    [ud setObject:kMPXSnapshotSaveDefaultPath forKey:kUDKeySnapshotSavePath];
                }
            }
        }];
    }
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
    if ([[NSFileManager defaultManager] isWritableFileAtPath:[url path]]) {
        return YES;
    }
    return NO;
}

-(IBAction) revealSnapshotPath:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[[ud objectForKey:kUDKeySnapshotSavePath] stringByExpandingTildeInPath]];
}

/////////////////////////////Toolbar Delegate/////////////////////
/*
 * 如何添加新的Pref View
 * 1. 在Pref.xib添加一个新的View，并将这个View设置为与ContentView的尺寸绑定
 * 2. 在PrefController中添加新的Outlet来代表这个View
 * 3. 根据新的View添加ToolbarItem的Indentifier和Name
 * 4. prefViews的初始化中，添加新View的outlet到其中
 * 5. toolbarAllowedItemIdentifiers中加入新Identifier
 * 6. 在toobar: itemForItemIdentifier :willBeInsertedIntoToolbar中创建相应的Item
 * (注意需要相应的图片资源等)
 */
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:PrefToolBarItemIdGeneral, PrefToolBarItemIdVideo, PrefToolBarItemIdAudio,
									PrefToolBarItemIdSubtitle, PrefToolbarItemIdNetwork, PrefToolbarItemIdAdvanced, nil];
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = nil;
	
	if ([itemIdentifier isEqualToString:PrefToolBarItemIdGeneral]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setLabel:PrefTBILabelGeneral];
		[item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
		[item setTag:0];
		
	} else if ([itemIdentifier isEqualToString:PrefToolBarItemIdVideo]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setLabel:PrefTBILabelVideo];
		[item setImage:[NSImage imageNamed:@"toolbar_video"]];
		[item setTag:1];
		
	} else if ([itemIdentifier isEqualToString:PrefToolBarItemIdAudio]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setLabel:PrefTBILabelAudio];
		[item setImage:[NSImage imageNamed:@"toolbar_audio"]];
		[item setTag:2];
		
	} else if ([itemIdentifier isEqualToString:PrefToolBarItemIdSubtitle]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setLabel:PrefTBILabelSubtitle];
		[item setImage:[NSImage imageNamed:NSImageNameFontPanel]];
		[item setTag:3];
		
	} else if ([itemIdentifier isEqualToString:PrefToolbarItemIdNetwork]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setLabel:PrefTBILabelNetwork];
		[item setImage:[NSImage imageNamed:NSImageNameNetwork]];
		[item setTag:4];
		
	} else if([itemIdentifier isEqualToString:PrefToolbarItemIdAdvanced]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setLabel:PrefTBILabelAdvanced];
		[item setImage:[NSImage imageNamed:NSImageNameAdvanced]];
		[item setTag:5];
		
	} else {
		return nil;
	}

	[item setTarget:self];
	[item setAction:@selector(switchViews:)];
	[item setAutovalidates:NO];

	return [item autorelease];
}

@end
