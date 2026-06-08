//
//  MetalTexture.mm
//  Mashkal
//

#import "OneStateOverlay.h"

@implementation MetalTexture

- (instancetype)initWithTexture:(id<MTLTexture>)texture {
    self = [super init];
    if (self) {
        _metalTexture = texture;
    }
    return self;
}

+ (instancetype)textureWithMTLTexture:(id<MTLTexture>)texture {
    return [[self alloc] initWithTexture:texture];
}

@end
