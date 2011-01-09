/*
 * MPlayerX - LogAnalyzer.m
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

#import "LogAnalyzer.h"
#import "LogAnalyzeOperation.h"

@implementation LogAnalyzer

@synthesize delegate;

-(id) initWithDelegate:(id<LogAnalyzerDelegate>) obj
{
	self = [super init];
	
	if (self) {
		delegate = obj;
		// 解析log的queue
		queue = [[NSOperationQueue alloc] init];
	}
	return self;
}

-(void) dealloc
{
	[self stop];

	[queue release];	
	[super dealloc];
}

-(void) stop
{
	[queue cancelAllOperations];
	[queue waitUntilAllOperationsAreFinished];
}

-(void) analyzeData:(NSData*) data
{
	if (data && ([data length] != 0) && delegate) {
		// 如果没有delegate，那么什么都不做
		// 因此这个类必须要有delegate才能正常工作
		LogAnalyzeOperation *op = [[LogAnalyzeOperation alloc] initWithData:data 
														 whenFinishedTarget:delegate 
																   selector:@selector(logAnalyzeFinished:)];		
		[queue addOperation:op];
		[op release];
	}
}
@end
