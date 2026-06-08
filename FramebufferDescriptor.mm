//
//  FramebufferDescriptor.mm
//  Mashkal
//

#import "OneStateOverlay.h"

@implementation FramebufferDescriptor

- (instancetype)initWithView:(MTKView *)view {
    self = [super init];
    if (self) {
        _sampleCount = view.sampleCount;
        _colorPixelFormat = view.colorPixelFormat;
        _depthPixelFormat = view.depthStencilPixelFormat;
        _stencilPixelFormat = MTLPixelFormatInvalid;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    FramebufferDescriptor *copy = [[FramebufferDescriptor alloc] init];
    copy.sampleCount = _sampleCount;
    copy.colorPixelFormat = _colorPixelFormat;
    copy.depthPixelFormat = _depthPixelFormat;
    copy.stencilPixelFormat = _stencilPixelFormat;
    return copy;
}

- (BOOL)isEqualToDescriptor:(FramebufferDescriptor *)other {
    if (!other) return NO;
    return (_sampleCount == other.sampleCount &&
            _colorPixelFormat == other.colorPixelFormat &&
            _depthPixelFormat == other.depthPixelFormat &&
            _stencilPixelFormat == other.stencilPixelFormat);
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[FramebufferDescriptor class]]) return NO;
    return [self isEqualToDescriptor:object];
}

- (NSUInteger)hash {
    return _sampleCount ^ _colorPixelFormat ^ _depthPixelFormat ^ _stencilPixelFormat;
}

@end
