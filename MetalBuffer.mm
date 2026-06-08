//
//  MetalBuffer.mm
//  Mashkal
//

#import "OneStateOverlay.h"

@implementation MetalBuffer

- (instancetype)initWithBuffer:(id<MTLBuffer>)buffer {
    self = [super init];
    if (self) {
        _buffer = buffer;
        _lastReuseTime = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

+ (instancetype)bufferWithMTLBuffer:(id<MTLBuffer>)buffer {
    return [[self alloc] initWithBuffer:buffer];
}

@end
