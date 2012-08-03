/*
 * MPlayerX - PlayListController.m
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

#import "PlayListController.h"
#import "PlayerController.h"
#import "CocoaAppendix.h"
#import "AppController.h"
#import "LocalizedStrings.h"

NSArray* findDigitParts(NSString *name)
{
	unichar ch;
	NSRange range;
	NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:5];;
	
	range.location = [name length];
	range.length = 0;
	
	// 字符串长度大于0
	while(range.location--) {
		// 得到当前的char
		ch = [name characterAtIndex:range.location];
		
		if ((ch>='0')&&(ch<='9')) {
			// 是数字
			range.length++;
		} else if (range.length > 0) {
			// 不是数字并且已经找到了数字
			[ret addObject:[NSValue valueWithRange:NSMakeRange(range.location+1, range.length)]];
			range.length = 0;
		}
	}
	if (range.length > 0) {
		[ret addObject:[NSValue valueWithRange:NSMakeRange(0, range.length)]];
	}
	return [ret autorelease];
}

BOOL isTimesOfTen(NSInteger num)
{
	if ((num == 10) || (num == 0) || (num == -10)) {
		return YES;
	} else if ((num % 10) == 0) {
		return isTimesOfTen(num / 10);
	} else {
		return NO;
	}
}

NSString* getFirstDigitPart(NSString *str)
{
	NSString *ret = nil;
	NSInteger i, len = [str length];
	unichar ch;
	
	for(i = 0;i < len; i++) {
		ch = [str characterAtIndex:i];
		
		if (!((ch>='0')&&(ch<='9'))) {
			break;
		}
	}
	if (i != 0) {
		ret = [[str substringToIndex:i] retain];
	}
	return [ret autorelease];
}

// implement the singleton pattern
static PlayListController *sharedInstance = nil;
static BOOL init_ed = NO;

@implementation PlayListController

@synthesize requestingNextOrPrev;

+(PlayListController*) sharedPlayListController
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
		
		requestingNextOrPrev = NO;
	}
	return self;
}

+(id) allocWithZone:(NSZone *)zone { return [[self sharedPlayListController] retain]; }
-(id) copyWithZone:(NSZone*)zone { return self; }
-(id) retain { return self; }
-(NSUInteger) retainCount { return NSUIntegerMax; }
-(oneway void) release { }
-(id) autorelease { return self; }

-(void) dealloc
{
	sharedInstance = nil;
	
	[super dealloc];
}

+(NSArray*) enumerateAllFilesAt:(NSString*)dirPath
{
	NSMutableArray *ret = nil;
    
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:dirPath];
	
	for (NSString *file in directoryEnumerator) {
		// enum the folder
		NSDictionary *fileAttr = [directoryEnumerator fileAttributes];
		
		if ([[fileAttr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
			// skip all sub-folders
			[directoryEnumerator skipDescendants];
			
		} else if ([[fileAttr objectForKey:NSFileType] isEqualToString: NSFileTypeRegular] &&
                   [[AppController sharedAppController] isFilePlayable:[dirPath stringByAppendingPathComponent:file]]) {
			// the normal file and the file extension is OK
			// or if exts is nil, don't care the extensions
			if (!ret) {
				// lazy load
				ret = [[NSMutableArray alloc] initWithCapacity:20];
			}
			[ret addObject:file];
		}
	}
	return [ret autorelease];
}

-(IBAction) playNext:(id)sender
{
	// MPLog(@"Play next");
	
	NSURL *lastURL = [playerController lastPlayedPath];
	
	if (lastURL) {
		if ([lastURL isFileURL]) {
			NSString *nextPath = [PlayListController SearchNextMoviePathFrom:[lastURL path]];
			if (nextPath) {
				// requestingNextOrPrev 能够工作是因为 loadFiles工作在一个线程
				// 在loadFiles退出的时候，就已经保证mplayer按照正确的顺序进行了stop→start
				// 不会出现时间差
				requestingNextOrPrev = YES;
				[playerController stop];
				[playerController loadFiles:[NSArray arrayWithObject:nextPath] fromLocal:YES];
				requestingNextOrPrev = NO;
			} else {
				[self showAlertPanelModal:kMPXStringCantFindNextEpisode];
			}
		} else {
			[self showAlertPanelModal:kMPXStringNextPrevOnlySupportLocalMedia];
		}
	}
}

-(IBAction) playPrevious:(id)sender
{
	// MPLog(@"Play prev");
	
	NSURL *lastURL = [playerController lastPlayedPath];
	
	if (lastURL) {
		if ([lastURL isFileURL]) {
			NSString *nextPath = [PlayListController SearchPreviousMoviePathFrom:[lastURL path]];
			if (nextPath) {
				// requestingNextOrPrev 能够工作是因为 loadFiles工作在一个线程
				// 在loadFiles退出的时候，就已经保证mplayer按照正确的顺序进行了stop→start
				// 不会出现时间差
				requestingNextOrPrev = YES;
				[playerController stop];
				[playerController loadFiles:[NSArray arrayWithObject:nextPath] fromLocal:YES];
				requestingNextOrPrev = NO;
			} else {
				[self showAlertPanelModal:kMPXStringCantFindPrevEpisode];			
			}		
		} else {
			[self showAlertPanelModal:kMPXStringNextPrevOnlySupportLocalMedia];
		}
	}
}

+ (NSString*) SearchPreviousMoviePathFrom:(NSString*)path
{
	NSString *nextPath = nil;

	if (path) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSArray *filesCandidates = nil;
		NSRange digitRange, lastRange;
		NSString *idxNext, *fileNamePrefix = nil, *idxNextTemp;
		BOOL isTen;
		NSInteger i = 0, idxNow, digitLast; //, nonFuzzySuffixPos = 0; //;
		// 得到文件的名字，没有后缀
		NSString *movieName = [[path lastPathComponent] stringByDeletingPathExtension];
		// directory path
		NSString *dirPath = [path stringByDeletingLastPathComponent];
		// 找到数字开头的index
		NSArray *digitRangeArray = findDigitParts(movieName);
		
		lastRange.length = 0;
		lastRange.location = NSNotFound;
		
		for (NSValue *val in digitRangeArray) {
			// 得到当前数字段
			digitRange = [val rangeValue];
			
			// 得到当前的数字值
			idxNow = [[movieName substringWithRange:digitRange] integerValue];
			
			if (idxNow > 1) {
				// 数字值必须大于1
				idxNext = [NSString stringWithFormat:@"%ld", idxNow - 1];

				NSUInteger idxNextLen = [idxNext length];
				// 减法对此不成立，10 - 1 = 9 or 09
				if (isTimesOfTen(idxNow)) {
					// 如果是10的整数次方
					++idxNextLen;
					isTen = YES;
				} else {
					isTen = NO;
				}
				
				// 如果这个index的长度比上一个短，说明有padding
				if (idxNextLen < digitRange.length) {
					// 有padding
					digitRange.location += (digitRange.length-idxNextLen);
					digitRange.length = idxNextLen;
				}

				if ((lastRange.length > 0) && ([[movieName substringWithRange:lastRange] integerValue] == 1)) {
					// 如果不是最末尾的字段
					// 而且上一个字段为1，那么说明到了一个season的第一集，需要找上一个season的最后一集
					
					// 得到所有文件的列表
					if (!filesCandidates) {
						// lazy load
						filesCandidates = [PlayListController enumerateAllFilesAt:dirPath];
					}
					
					NSInteger maxNum = 0;
					NSString *digitMax;
					
					for (i = 0; i < 2; ++i) {
						if (i == 1) {
							if (isTen) {
								// 如果是10的次方，那么还要探测099的可能性
								idxNextTemp = [NSString stringWithFormat:@"0%@", idxNext];
							} else {
								continue;
							}
						} else {
							idxNextTemp = idxNext;
						}
						
						// 之前有字段的话
						digitLast = digitRange.location + digitRange.length;
						fileNamePrefix = [NSString stringWithFormat:@"%@%@%@", 
										  [movieName substringToIndex:digitRange.location],
										  idxNextTemp,
										  [movieName substringWithRange:NSMakeRange(digitLast, lastRange.location-digitLast)]];

						MPLog(@"0: %@", fileNamePrefix);

						NSRange rng;
						for (NSString *name in filesCandidates) {
							// 现不包含数字的寻找
							rng = [name rangeOfString:fileNamePrefix options:NSCaseInsensitiveSearch|NSAnchoredSearch];
							
							if (rng.length != 0) {
								// found the name
								// 得到lastDigit的字符串
								digitMax = getFirstDigitPart([name substringFromIndex:rng.length + rng.location]);
								
								// 如果大于最大值，那么就
								if ([digitMax integerValue] > maxNum) {
									maxNum = [digitMax integerValue];
									if (nextPath) {
										[nextPath release];
										nextPath = nil;
									}
									nextPath = [[dirPath stringByAppendingPathComponent:name] retain];
								}
							}
						}
						// 遍历所有文件之后
						if (nextPath) {
							goto ExitLoopPrev;
						}
					}
				} else {
					for (i = 0; i < 2; ++i) {
						if (i == 1) {
							if (isTen) {
								// 如果是10的次方，那么还要探测099的可能性
								idxNextTemp = [NSString stringWithFormat:@"0%@", idxNext];
							} else {
								continue;
							}
						} else {
							idxNextTemp = idxNext;
						}
						// 如果不是1，那可能是没有意义的字段，或者是普通的某一集
						// 或者最末尾的字段
						fileNamePrefix = [[movieName substringToIndex:digitRange.location] stringByAppendingString:idxNextTemp];
						
						MPLog(@"1: %@", fileNamePrefix);

						// fuzzy matching
						if (!filesCandidates) {
							// lazy load
							filesCandidates = [PlayListController enumerateAllFilesAt:dirPath];
						}
							
						NSRange rng;
						for (NSString *name in filesCandidates) {
							rng = [name rangeOfString:fileNamePrefix options:NSCaseInsensitiveSearch|NSAnchoredSearch];
							if (rng.length != 0) {
								// found the name
								nextPath = [[dirPath stringByAppendingPathComponent:name] retain];
								goto ExitLoopPrev;
							}
						}
					}
				}
			}
			lastRange = digitRange;
		}
ExitLoopPrev:
		[pool drain];
	}
	return [nextPath autorelease];
}

+(NSString*) SearchNextMoviePathFrom:(NSString*)path
{
	NSString *nextPath = nil;
	
	if (path) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSArray *filesCandidates = nil;
		NSRange digitRange, lastRange;
		NSString *idxNext, *fileNamePrefix = nil;
		NSInteger i = 0, digitLast; //, nonFuzzySuffixPos = 0;
		// 得到文件的名字，没有后缀
		NSString *movieName = [[path lastPathComponent] stringByDeletingPathExtension];
		// directory path
		NSString *dirPath = [path stringByDeletingLastPathComponent];
		// 找到数字开头的index
		NSArray *digitRangeArray = findDigitParts(movieName);
		
		// 初始化上个字段
		lastRange.length = 0;
		lastRange.location = NSNotFound;
		
		for (NSValue *val in digitRangeArray) {
			// 得到字段的范围
			digitRange = [val rangeValue];

			// 得到下一个想要播放的文件的index
			idxNext = [NSString stringWithFormat:@"%ld", [[movieName substringWithRange:digitRange] integerValue] + 1];

			NSUInteger idxNextLen = [idxNext length];
			// 如果这个index的长度比上一个短，说明有padding
			if (idxNextLen < digitRange.length) {
				digitRange.location += (digitRange.length-idxNextLen);
				digitRange.length = idxNextLen;
			}
			
			for (i = 0; i < 3; ++i) {
				switch (i) {
					case 0:
						// match the with the padding 0001
						if (lastRange.length > 1) {
							digitLast = digitRange.location+digitRange.length;
							NSString *fmt = [NSString stringWithFormat:@"%%@%%@%%@%%0%ldd",lastRange.length];
							fileNamePrefix = [NSString stringWithFormat:fmt,
											  [movieName substringToIndex:digitRange.location],
											  idxNext,
											  [movieName substringWithRange:NSMakeRange(digitLast, lastRange.location-digitLast)],
											  1];
							// nonFuzzySuffixPos = lastRange.location + lastRange.length;
							MPLog(@"%@", fileNamePrefix);
						} else {
							continue;
						}
						break;
					case 1:
						// match the un padding 1
						if (lastRange.length > 0) {
							digitLast = digitRange.location+digitRange.length;
							
							fileNamePrefix = [NSString stringWithFormat:@"%@%@%@1",
											  [movieName substringToIndex:digitRange.location],
											  idxNext,
											  [movieName substringWithRange:NSMakeRange(digitLast, lastRange.location-digitLast)]];
							// nonFuzzySuffixPos = lastRange.location + lastRange.length;
							MPLog(@"%@", fileNamePrefix);
						} else {
							continue;
						}
						break;
					default:
						// match the increment +1
						
						fileNamePrefix = [[movieName substringToIndex:digitRange.location] stringByAppendingString:idxNext];
						
						MPLog(@"%@", fileNamePrefix);
						break;
				}
				// fuzzy matching
				if (!filesCandidates) {
					// lazy load
					filesCandidates = [PlayListController enumerateAllFilesAt:dirPath];
				}

				NSRange rng;
				for (NSString *name in filesCandidates) {
					rng = [name rangeOfString:fileNamePrefix options:NSCaseInsensitiveSearch|NSAnchoredSearch];
					if (rng.length != 0) {
						// found the name
						nextPath = [[dirPath stringByAppendingPathComponent:name] retain];
						goto ExitLoop;
					}
				}		
			}
			lastRange = digitRange;
		}
ExitLoop:
		[pool drain];
	}	
	return [nextPath autorelease];
}
@end