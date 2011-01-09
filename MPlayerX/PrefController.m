/*
 * MPlayerX - PrefController.m
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
#import	"LocalizedStrings.h"
#import "PrefController.h"
#import "PlayerController.h"
#import "RootLayerView.h"
#import "ControlUIView.h"
#import "CocoaAppendix.h"

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
	[super release];
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

- (IBAction)multiThreadChanged:(id)sender
{
	[playerController setMultiThreadMode:[ud boolForKey:kUDKeyEnableMultiThread]];
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
	unsigned int mode = [ud integerForKey:kUDKeyLetterBoxMode];
	
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
