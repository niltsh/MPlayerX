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

@interface YTDL (Internal)
-(void) getRealURLThread:(NSArray*)args;
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

-(void) getRealURL:(NSString*)urlString
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
                                                                        selector:@selector(getRealURLThread:)
                                                                          object:urlString];
                [queue addOperation:currentOperation];
            } else {
                // file does not exist
                [delegate ytdl:self gotError:@"Internal Error: Binary does not exist."];
            }
        } else {
            // there is no path for the binary
            [delegate ytdl:self gotError:@"Internal Error: No binary path."];
        }
    }
}

-(void) getRealURLThread:(NSString*)urlStr
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSData *dataRet = nil;
    BOOL isError = NO;
    char *buf = NULL;
    NSString *retStr = nil;
    
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:binPath];
    [task setArguments:[NSArray arrayWithObjects:@"-g", urlStr, nil]];
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
    } else {
        retStr = [NSString stringWithString:@""];
    }
    
    if (currentOperation && (![currentOperation isCancelled])) {
        [self performSelectorOnMainThread:@selector(sendDelegateMessage:)
                               withObject:[NSArray arrayWithObjects:retStr, [NSNumber numberWithBool:isError], nil]
                            waitUntilDone:YES
                                    modes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
    } else {
        NSLog(@"this operation is cancelled");
    }
    
    [task release];
    [pool drain];
}

-(void) sendDelegateMessage:(NSArray*)args
{
    if (delegate) {
        if ([[args objectAtIndex:1] boolValue]) {
            [delegate ytdl:self gotError:[args objectAtIndex:0]];
        } else {
            [delegate ytdl:self gotRealURL:[args objectAtIndex:0]];
        }
    }
}
@end
