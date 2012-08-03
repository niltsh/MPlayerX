/*
 * MPlayerX - SubConverter.m
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

#import "SubConverter.h"
#import <UniversalDetector/UniversalDetector.h>

NSString * const kWorkDirSubDir = @"Subs";

@implementation SubConverter

@synthesize delegate;
 
-(id) init
{
	self = [super init];
	
	if (self) {
		delegate = nil;
		textSubFileExts = [[NSSet alloc] initWithObjects:@"utf", @"utf8", @"srt", @"ass", @"smi", @"txt", @"ssa", @"smil", @"jss", @"rt", nil];
		workDirectory = nil;
		detector = [[UniversalDetector alloc] init];
		[detector reset];
	}
	return self;
}

-(void) dealloc
{
	[textSubFileExts release];
	[workDirectory release];

	@synchronized (detector) { [detector release]; }

	[super dealloc];
}

-(void) clearWorkDirectory
{
	if (workDirectory) {
		[[NSFileManager defaultManager] removeItemAtPath:[workDirectory stringByAppendingPathComponent:kWorkDirSubDir] error:NULL];
	}
}

-(void) setWorkDirectory:(NSString *)wd
{
	[self clearWorkDirectory];

	[wd retain];
	[workDirectory release];
	workDirectory = wd;
}

-(NSString*) getCPOfTextSubtitle:(NSString*)path
{
	BOOL isDir = YES;
	NSString *cpStr = nil;	
	
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && (!isDir) &&
		[textSubFileExts containsObject:[[path pathExtension] lowercaseString]]) {

		@synchronized(detector) {
			[detector analyzeContentsOfFile:path];
			cpStr = [detector MIMECharset];
			
			if (delegate) {
				NSString *cpPrefer = [delegate subConverter:self detectedFile:path ofCharsetName:cpStr confidence:[detector confidence]];
				if (cpPrefer && (cpPrefer != cpStr)) {
					cpStr = cpPrefer;
				}
			}
			[cpStr retain];
			[detector reset];
		}
	}
	return [cpStr autorelease];
}

-(NSArray*) convertTextSubsAndEncodings:(NSDictionary*)subEncDict
{
	if (!workDirectory) {
		return nil;
	}
	
	NSString *subDir = [workDirectory stringByAppendingPathComponent:kWorkDirSubDir];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	
	if ([fm fileExistsAtPath:subDir isDirectory:&isDir] && (!isDir)) {
		// 如果存在但不是文件夹的话，删除文件先
		[fm removeItemAtPath:subDir error:NULL];
	}
	
	if (!isDir) {
		// 如果原来不存在这个文件夹或者存在的是文件的话，都需要重建文件夹
		if (![fm createDirectoryAtPath:subDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
			return nil;
		}
	}

	NSMutableArray *newSubs = [[NSMutableArray alloc] initWithCapacity:4];
	NSString *subPathOld, *enc, *subFileOld, *subPathNew, *ext, *prefix;
	NSUInteger idx;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for (subPathOld in subEncDict) {
		// 得到文件的编码
		enc = [subEncDict objectForKey:subPathOld];
		
		if (enc) {
			// 如果能够得到编码字符串，先转换为CF格式
			CFStringEncoding ce = CFStringConvertIANACharSetNameToEncoding((CFStringRef)enc);
			
			if (ce != kCFStringEncodingInvalidId) {
				// 先根据本来的文件名得到workDir的文件路径
				subPathNew = [subDir stringByAppendingPathComponent:
							  [[subPathOld lastPathComponent] stringByReplacingOccurrencesOfString:@"," withString:@"_"]];
				
				// 因为有可能会有重名的情况，所以这里要找到合适的文件名
				isDir = YES;
				idx = 0;
				ext = nil;
				prefix = nil;
				
				// 因为有重名的可能性，所以要找到一个不重复的文件名
				while([fm fileExistsAtPath:subPathNew isDirectory:&isDir] && (!isDir)) {
					if (ext == nil) {
						ext = [subPathNew pathExtension];
					}
					if (prefix == nil) {
						prefix = [subPathNew stringByDeletingPathExtension];
					}
					// 如果该文件存在那么就寻找下一个不存在的文件名
					subPathNew = [prefix stringByAppendingFormat:@".%ld.%@", idx++, ext];
				}
				
				// CP949据说总会fallback到EUC_KR，这里把它回到CP949(kCFStringEncodingDOSKorean)
				if ((ce == kCFStringEncodingMacKorean) || (ce == kCFStringEncodingEUC_KR)) {
					ce = kCFStringEncodingDOSKorean;
				}
				
				// 如果合法就转码
				NSStringEncoding ne = CFStringConvertEncodingToNSStringEncoding(ce);
				
				subFileOld = [NSString stringWithContentsOfFile:subPathOld encoding:ne error:NULL];
				
				if (!subFileOld) {
					// 如果没有成功打开，有可能是编码指定有一些问题
					if (ce == kCFStringEncodingBig5) {
						// 如果是Big5的话，就再试试HKSCS看看
						ne = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5_HKSCS_1999);
						subFileOld = [NSString stringWithContentsOfFile:subPathOld encoding:ne error:NULL];
					} else {
					}
				}
				
				if (subFileOld) {
					// 成功读出文件
					// 因为UCD也有猜错的时候，这个时候就直接拷贝文件了
					if ([subFileOld writeToFile:subPathNew atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
						// 如果成功写入
						// 如果没有些成功，那就试着直接拷贝
						[newSubs addObject:subPathNew];
						continue;
					}
				}
			}
		}
	}
	[pool drain];
	
	return [newSubs autorelease];
}

-(NSDictionary*) getCPFromMoviePath:(NSString*)moviePath nameRule:(SUBFILE_NAMERULE)nameRule alsoFindVobSub:(NSString**)vobPath
{
	NSString *cpStr = nil;
	NSString *subPath = nil;
	NSMutableDictionary *subEncDict = [[NSMutableDictionary alloc] initWithCapacity:2];

	if (vobPath) {
		*vobPath = nil;
	}

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// 文件夹路径
	NSString *directoryPath = [moviePath stringByDeletingLastPathComponent];
	// 播放文件名称
	NSString *movieName = [[[moviePath lastPathComponent] stringByDeletingPathExtension] lowercaseString];
	
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
	
	// 遍历播放文件所在的目录
	for (NSString *path in directoryEnumerator)
	{
		// the lower case of the sub path
		NSString *caseName = [[path stringByDeletingPathExtension] lowercaseString];

		NSDictionary *fileAttr = [directoryEnumerator fileAttributes];
		
		if ([[fileAttr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
			//不遍历子目录
			[directoryEnumerator skipDescendants];
			
		} else if ([[fileAttr objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			// 如果是普通文件
			switch (nameRule) {
				case kSubFileNameRuleExactMatch:
					if (![movieName isEqualToString:caseName]) continue; // exact match
					break;
				case kSubFileNameRuleAny:
					break; // any sub file is OK
				case kSubFileNameRuleContain:
					if ([caseName rangeOfString: movieName].location == NSNotFound) continue; // contain the movieName
					break;
				default:
					continue;
					break;
			}
			
			subPath = [directoryPath stringByAppendingPathComponent:path];

			NSString *ext = [[path pathExtension] lowercaseString];
			
			if ([textSubFileExts containsObject: ext]) {
				// 如果是文本字幕文件
				@synchronized (detector) {
					[detector analyzeContentsOfFile: subPath];
					
					cpStr = [detector MIMECharset];

					if (delegate) {
						NSString *cpPrefer = [delegate subConverter:self detectedFile:subPath ofCharsetName:cpStr confidence:[detector confidence]];
						if (cpPrefer && (cpPrefer != cpStr)) {
							cpStr = cpPrefer;
						}
					}
					if (cpStr) {
						[subEncDict setObject:cpStr forKey:subPath];
					}
					[detector reset];					
				}
			} else if (vobPath && [ext isEqualToString:@"sub"]) {
				// 如果是vobsub并且设定要寻找vobsub
				[*vobPath release];
				*vobPath = [subPath retain];
			}
		}
	}
	[pool drain];

	if (vobPath && (*vobPath)) {
		[*vobPath autorelease];
	}

	return [subEncDict autorelease];	
}

-(NSString*) mergeSubtitle:(NSString*)fullPath to:(NSString*)subName
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *ret = nil;
    NSString *subDir = [workDirectory stringByAppendingPathComponent:kWorkDirSubDir];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = YES;
    NSString *originalPath = [subDir stringByAppendingPathComponent:subName];
    
	if ([fm fileExistsAtPath:originalPath isDirectory:&isDir] && (!isDir)) {
        // file exists and not folder
        NSString *encoding = [self getCPOfTextSubtitle:fullPath];
        
        if (encoding) {
            // convert the current sub
            NSArray *newPath = [self convertTextSubsAndEncodings:[NSDictionary dictionaryWithObjectsAndKeys:encoding, fullPath, nil]];
            if (newPath && [newPath count]) {
                // convert succeeded, then merge the two subs
                NSString *originalContent = [NSString stringWithContentsOfFile:originalPath
                                                                      encoding:NSUTF8StringEncoding
                                                                         error:NULL];
                NSString *newContent = [NSString stringWithContentsOfFile:[newPath objectAtIndex:0]
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:NULL];
                if (originalContent && newContent) {
                    // if all the contents are read out
                    NSString *mergedContent = [NSString stringWithFormat:@"%@\r\n\r\n%@", newContent, originalContent];
                    
                    if (mergedContent) {
                        NSString *tempDir = NSTemporaryDirectory();
                        
                        if (!tempDir) {
                            tempDir = subDir;
                        }
                        NSString *newFullPath = [tempDir stringByAppendingPathComponent:
                                                 [NSString stringWithFormat:
                                                  @"%@_%@.merged.%@",
                                                  [[fullPath lastPathComponent] stringByDeletingPathExtension],
                                                  [[subName lastPathComponent] stringByDeletingPathExtension],
                                                  [fullPath pathExtension]]];
                        
                        if ([mergedContent writeToFile:newFullPath atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
                            ret = [newFullPath retain];
                        }
                    }
                }
            }
        }
	}
    [pool drain];
    
    return [ret autorelease];
}
@end
