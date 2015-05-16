#import <Foundation/Foundation.h>

@interface UniversalDetector:NSObject
{
	void *detectorPtr;
	NSString *charsetName;
	float confidence;
}

-(void)analyzeContentsOfFile:(NSString *)path;
-(void)analyzeData:(NSData *)data;
-(void)analyzeBytes:(const char *)data length:(int)len;
-(void)reset;

-(BOOL)done;
-(NSString *)MIMECharset;
-(NSStringEncoding)encoding;
-(float)confidence;

@end
