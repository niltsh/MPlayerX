/*
 * MPlayerX - YTDL.m
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

#import "YTDL.h"
#import "CocoaAppendix.h"

NSString * const kYTDLInfoContentKey    = @"YTDLInfoContent";
NSString * const kYTDLInfoTypeKey       = @"YTDLInfoType";
NSString * const kYTDLInfoIsErrorKey    = @"YTDLInfoIsError";

@interface YTDL (Internal)
-(void) getInfoThread:(NSArray*)args;
-(NSDictionary*) makeInfoDict:(id)content type:(NSUInteger)type isError:(BOOL)err;
-(void) sendDelegateMessage:(NSDictionary*)infoDict;
-(NSString*) processHtmlEntities:(NSString*)str;
@end

@implementation YTDL

@synthesize delegate;

-(id) init
{
    self = [super init];
    if (self) {
        binPath = nil;
        delegate = nil;
        queue = nil;
        currentOperation = nil;
    }
    return self;
}

-(id) initWithBinPath:(NSString*)path
{
    self = [super init];
    if (self) {
        binPath = [path retain];
        delegate = nil;
        queue = nil;
        currentOperation = nil;
    }
    return self;
}

-(void) dealloc
{
    delegate = nil;
    [self cancel];
    [queue release];
    [binPath release];
    [super dealloc];
}

-(void) cancel
{
    if (currentOperation) {
        [currentOperation cancel];
        [currentOperation waitUntilFinished];
        [currentOperation release];
        currentOperation = nil;
    }
}

-(NSDictionary*) makeInfoDict:(id)content type:(NSUInteger)type isError:(BOOL)err
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            content, kYTDLInfoContentKey,
            [NSNumber numberWithUnsignedInteger:type], kYTDLInfoTypeKey,
            [NSNumber numberWithBool:err], kYTDLInfoIsErrorKey,
            nil];
}

-(void) getInfoFromURL:(NSString*)urlString type:(NSUInteger)type
{
    if (delegate) {
        if (binPath) {
            BOOL isDir = YES;
            if ([[NSFileManager defaultManager] fileExistsAtPath:binPath isDirectory:&isDir] && (!isDir)) {
                // the file is OK
                if (!queue) {
                    // lazy load
                    queue = [[NSOperationQueue alloc] init];
                }
                
                [self cancel];
                
                currentOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                        selector:@selector(getInfoThread:)
                                                                          object:[NSArray arrayWithObjects:
                                                                                  urlString,
                                                                                  [NSNumber numberWithUnsignedInteger:type],
                                                                                  nil]];
                [queue addOperation:currentOperation];
            } else {
                // file does not exist
                [delegate ytdl:self gotInfo:[self makeInfoDict:@"Internal Error: Binary does not exist."
                                                          type:type
                                                       isError:YES]];
            }
        } else {
            // there is no path for the binary
            [delegate ytdl:self gotInfo:[self makeInfoDict:@"Internal Error: No binary path."
                                                      type:type
                                                   isError:YES]];
        }
    }
}

-(void) getInfoThread:(NSArray*)args
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSData *dataRet = nil;
    BOOL isError = NO;
    char *buf = NULL;
    NSString *retStr = nil;
    
    NSString *urlStr = [args objectAtIndex:0];
    NSUInteger type = [[args objectAtIndex:1] unsignedIntegerValue];
    
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:binPath];
    
    if (type == kYTDLInfoTypeURL) {
        [task setArguments:[NSArray arrayWithObjects:@"-g", urlStr, nil]];
    } else if (type == kYTDLInfoTypeTitle) {
        [task setArguments:[NSArray arrayWithObjects:@"-e", urlStr, nil]];
    } else {
        [self performSelectorOnMainThread:@selector(sendDelegateMessage:)
                               withObject:[self makeInfoDict:@"Interal Error:Unacceptable Info Type"
                                                        type:type
                                                     isError:YES]
                            waitUntilDone:YES
                                    modes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
        goto ErrOut;
    }
    
    [task setStandardError:[NSPipe pipe]];
    [task setStandardOutput:[NSPipe pipe]];
    
    [task launch];
    
    NSData* dataOut = [[[[task standardOutput] fileHandleForReading] availableData] retain];
    NSData* dataErr = [[[[task standardError] fileHandleForReading] availableData] retain];
    
    [task waitUntilExit];
    
    if (dataErr && [dataErr length]) {
        dataRet = dataErr;
        isError = YES;
        [dataOut release];
    } else {
        dataRet = dataOut;
        isError = NO;
        [dataErr release];
    }
    
    if (dataRet) {
        NSUInteger len = [dataRet length];
        buf = (char*)malloc([dataRet length] + 1);
        memcpy(buf, [dataRet bytes], [dataRet length]);
        buf[len] = 0;
        while (len) {
            if (buf[len] == 0x0a) {
                buf[len] = 0;
                break;
            }
            len--;
        }
        [dataRet release];
    }
    
    if (buf) {
        retStr = [NSString stringWithUTF8String:buf];
        free(buf);
        
        if (type == kYTDLInfoTypeTitle) {
            // process the html entities here
            retStr = [self processHtmlEntities:retStr];
        }
    } else {
        retStr = @"";
    }
    
    if (currentOperation && (![currentOperation isCancelled])) {
        [self performSelectorOnMainThread:@selector(sendDelegateMessage:)
                               withObject:[self makeInfoDict:retStr
                                                        type:type
                                                     isError:isError]
                            waitUntilDone:YES
                                    modes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
    } else {
        MPLog(@"this operation is cancelled");
    }
    
ErrOut:
    [task release];
    [pool drain];
}

-(NSString*) processHtmlEntities:(NSString*)str
{
    NSString *ret = nil;

    if (str) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSArray *arr = [str componentsSeparatedByString:@"&#"];
        
        if ([arr count] == 1) {
            ret = str;
        } else {
            BOOL firstMark = YES;
            NSRange range;
            range.location = ';';
            range.length   = 1;
            NSCharacterSet *cset = [NSCharacterSet characterSetWithRange:range];
            
            for (NSString* comp in arr) {
                NSRange rng = [comp rangeOfCharacterFromSet:cset];
                
                if (!ret) {
                    ret = @"";
                }
                if (rng.location == NSNotFound) {
                    // did not find the ;
                    if (firstMark) {
                        continue;
                        firstMark = NO;
                    } else {
                        ret = [ret stringByAppendingFormat:@"&#%@", comp];
                    }
                } else {
                    // found ;
                    firstMark = NO;
                    NSString *digits = [comp substringToIndex:rng.location];
                    NSString *tails  = [comp substringFromIndex:rng.location + rng.length];
                    unichar encoded = [digits integerValue];
                    
                    ret = [ret stringByAppendingFormat:@"%@%@", 
                           [NSString stringWithCharacters:&encoded length:1],
                           tails];
                }
            }
        }
        [ret retain];
        [pool drain];
    }
    return [ret autorelease];
}

-(void) sendDelegateMessage:(NSDictionary*)infoDict
{
    if (delegate) {
        [delegate ytdl:self gotInfo:infoDict];
    }
}
@end
