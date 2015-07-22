/*
 * MPlayerX - AODetector.m
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

#import "AODetector.h"
#import "CocoaAppendix.h"

extern NSTextView *logView;

static void print_format(const char* str, const AudioStreamBasicDescription *f)
{
    uint32_t flags=(uint32_t) f->mFormatFlags;
	MPLog(@"%s %7.1fHz %"PRIu32"bit [%c%c%c%c][%"PRIu32"][%"PRIu32"][%"PRIu32"][%"PRIu32"][%"PRIu32"] %s %s %s%s%s%s\n",
			str, f->mSampleRate, f->mBitsPerChannel,
			(int)(f->mFormatID & 0xff000000) >> 24,
			(int)(f->mFormatID & 0x00ff0000) >> 16,
			(int)(f->mFormatID & 0x0000ff00) >>  8,
			(int)(f->mFormatID & 0x000000ff) >>  0,
			f->mFormatFlags, f->mBytesPerPacket,
			f->mFramesPerPacket, f->mBytesPerFrame,
			f->mChannelsPerFrame,
			(flags&kAudioFormatFlagIsFloat) ? "float" : "int",
			(flags&kAudioFormatFlagIsBigEndian) ? "BE" : "LE",
			(flags&kAudioFormatFlagIsSignedInteger) ? "S" : "U",
			(flags&kAudioFormatFlagIsPacked) ? " packed" : "",
			(flags&kAudioFormatFlagIsAlignedHigh) ? " aligned" : "",
			(flags&kAudioFormatFlagIsNonInterleaved) ? " ni" : "");
}

static OSStatus GetAudioProperty(AudioObjectID aid, AudioObjectPropertySelector selector, UInt32 outSize, void *outData)
{
    AudioObjectPropertyAddress property_address;
	
    property_address.mSelector = selector;
    property_address.mScope    = kAudioObjectPropertyScopeGlobal;
    property_address.mElement  = kAudioObjectPropertyElementMaster;
	
    return AudioObjectGetPropertyData(aid, &property_address, 0, NULL, &outSize, outData);
}

static UInt32 GetAudioPropertyArray(AudioObjectID aid, AudioObjectPropertySelector selector, AudioObjectPropertyScope scope, void **outData)
{
    OSStatus err;
    AudioObjectPropertyAddress property_address;
    UInt32 i_param_size;
	
    property_address.mSelector = selector;
    property_address.mScope    = scope;
    property_address.mElement  = kAudioObjectPropertyElementMaster;
	
    err = AudioObjectGetPropertyDataSize(aid, &property_address, 0, NULL, &i_param_size);
	
    if (err != noErr) {
        return 0;
	}
	
    *outData = malloc(i_param_size);
	
    err = AudioObjectGetPropertyData(aid, &property_address, 0, NULL, &i_param_size, *outData);
	
    if (err != noErr) {
        free(*outData);
        return 0;
    }
	
    return i_param_size;
}

static OSStatus GetAudioPropertyString(AudioObjectID aid, AudioObjectPropertySelector selector, char **outData)
{
    OSStatus err;
    AudioObjectPropertyAddress property_address;
    UInt32 i_param_size;
    CFStringRef string;
    CFIndex string_length;
	
    property_address.mSelector = selector;
    property_address.mScope    = kAudioObjectPropertyScopeGlobal;
    property_address.mElement  = kAudioObjectPropertyElementMaster;
	
    i_param_size = sizeof(CFStringRef);
    err = AudioObjectGetPropertyData(aid, &property_address, 0, NULL, &i_param_size, &string);
    if (err != noErr) {
        return err;
	}
	
    string_length = CFStringGetMaximumSizeForEncoding(CFStringGetLength(string), kCFStringEncodingUTF8);
    *outData = malloc(string_length + 1);
    CFStringGetCString(string, *outData, string_length + 1, kCFStringEncodingUTF8);
	
    CFRelease(string);
	
    return err;
}

static int AudioStreamSupportsDigital( AudioStreamID i_stream_id )
{
    UInt32 i_param_size;
    AudioStreamRangedDescription *p_format_list = NULL;
    int i, i_formats, b_return = NO;
	
    /* Retrieve all the stream formats supported by each output stream. */
    i_param_size = GetAudioPropertyArray(i_stream_id, kAudioStreamPropertyAvailablePhysicalFormats, kAudioObjectPropertyScopeGlobal, (void **)&p_format_list);
	
    if (!i_param_size) {
		MPLog(@"Could not get number of stream formats.\n");
        return NO;
    }
	
    i_formats = i_param_size / sizeof(AudioStreamRangedDescription);
	
    for (i = 0; i < i_formats; ++i) {
        print_format("Supported format:", &(p_format_list[i].mFormat));
		
        if ((p_format_list[i].mFormat.mFormatID == 'IAC3') ||
			(p_format_list[i].mFormat.mFormatID == 'iac3') ||
			(p_format_list[i].mFormat.mFormatID == kAudioFormat60958AC3) ||
			(p_format_list[i].mFormat.mFormatID == kAudioFormatAC3)) {
            b_return = YES;
			break;
		}
    }
	
    free(p_format_list);
    return b_return;
}

static int AudioDeviceSupportsDigital( AudioDeviceID i_dev_id )
{
	UInt32                      i_param_size = 0;
	AudioStreamID               *p_streams = NULL;
	int                         i = 0, i_streams = 0;
	int                         b_return = NO;
	
	/* Retrieve all the output streams. */
	i_param_size = GetAudioPropertyArray(i_dev_id, kAudioDevicePropertyStreams, kAudioDevicePropertyScopeOutput, (void **)&p_streams);
	
	if (!i_param_size) {
		MPLog(@"could not get number of streams.\n");
		return NO;
	}
	
    i_streams = i_param_size / sizeof(AudioStreamID);
	
	for (i = 0; i < i_streams; ++i) {
		if (AudioStreamSupportsDigital(p_streams[i])) {
			b_return = YES;
			break;
		}
	}
	
	free(p_streams);
	return b_return;
}

static OSStatus DeviceListener( AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void *inClientData )
{
    for (int i=0; i < inNumberAddresses; ++i) {
        if (inAddresses[i].mSelector == kAudioDevicePropertyDeviceHasChanged) {
			MPLog(@"Device Changed.\n");

			AODetector *d = (AODetector*)inClientData;
			char *name = NULL;
			
			[d setDigital: AudioDeviceSupportsDigital([d defaultDevID])];
			
			GetAudioPropertyString([d defaultDevID], kAudioObjectPropertyName, &name);

            if (name) {
                [d setDeviceName:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
                free(name);
            } else {
                [d setDeviceName:@"Unknown"];
            }

			[[NSNotificationCenter defaultCenter] postNotificationName:kMPXDefaultAudioDeviceChanged object:d];
			break;
        }
    }
    return noErr;
}

NSString * const kMPXDefaultAudioDeviceChanged		= @"MPXDefaultAudioDeviceChanged";

static AODetector *sharedInstance = nil;
static BOOL init_ed = NO;

@implementation AODetector

@synthesize deviceName;
@synthesize defaultDevID;
@synthesize listening;

+(AODetector*) defaultDetector
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
		
		deviceName = nil;
		digital = NO;
		listening = NO;
		defaultDevID = kAudioDeviceUnknown;
		
		OSStatus err;
		char *name;
		err = GetAudioProperty(kAudioObjectSystemObject, kAudioHardwarePropertyDefaultOutputDevice, sizeof(UInt32), &defaultDevID);
		if (err == noErr) {
			err = GetAudioPropertyString(defaultDevID, kAudioObjectPropertyName, &name);
            
			if (err == noErr) {
				[self setDeviceName:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
				free(name);
				
				digital = AudioDeviceSupportsDigital(defaultDevID);
			} else {
                defaultDevID = kAudioDeviceUnknown;
                MPLog(@"DevName Error: [%4.4s]\n", (char *)&err);
			}
		} else {
			MPLog(@"Default Audio Device Error: [%4.4s]\n", (char *)&err);
		}
	}
	return self;
}

+(id) allocWithZone:(NSZone *)zone { return [[self defaultDetector] retain]; }
-(id) copyWithZone:(NSZone*)zone { return self; }
-(id) retain { return self; }
-(NSUInteger) retainCount { return NSUIntegerMax; }
-(oneway void) release { }
-(id) autorelease { return self; }

-(void) dealloc
{
	[self stopListening];
	[deviceName release];
	sharedInstance = nil;

	[super dealloc];
}

-(void) setDigital:(BOOL)dig
{
	digital = dig;
}

-(BOOL) isDigital
{
	if (!listening) {
		if (defaultDevID != kAudioDeviceUnknown) {
			digital = AudioDeviceSupportsDigital(defaultDevID);
		} else {
			digital = NO;
		}
	}
	return digital;
}

-(void) startListening
{
	if (!listening) {
		OSStatus err;
		AudioObjectPropertyAddress  property_address;
		property_address.mSelector = kAudioDevicePropertyDeviceHasChanged;
		property_address.mScope    = kAudioObjectPropertyScopeGlobal;
		property_address.mElement  = kAudioObjectPropertyElementMaster;
		
		err = AudioObjectAddPropertyListener(defaultDevID, &property_address, DeviceListener, self);
		if (err == noErr) {
			listening = YES;
		} else {
			MPLog(@"Listen Error: [%4.4s]\n", (char *)&err);
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:kMPXDefaultAudioDeviceChanged object:self];
	}
}

-(void) stopListening
{
	if (listening) {
		listening = NO;
		AudioObjectPropertyAddress  property_address;
	    property_address.mSelector = kAudioDevicePropertyDeviceHasChanged;
		property_address.mScope    = kAudioObjectPropertyScopeGlobal;
		property_address.mElement  = kAudioObjectPropertyElementMaster;
		
		AudioObjectRemovePropertyListener(defaultDevID, &property_address, DeviceListener, self);
	}
}
@end
