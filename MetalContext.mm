//
//  MetalContext.mm
//  Mashkal
//  Metal Resource Manager
//

#import "OneStateOverlay.h"

@implementation MetalContext

+ (instancetype)sharedContextWithDevice:(id<MTLDevice>)device {
    static MetalContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[self alloc] init];
        context.device = device;
        context.pipelineCache = [NSMutableDictionary dictionary];
        context.bufferCache = [NSMutableArray array];
    });
    return context;
}

- (id<MTLRenderPipelineState>)pipelineStateForDescriptor:(MTLRenderPipelineDescriptor *)descriptor {
    NSString *key = [NSString stringWithFormat:@"%p", descriptor];
    id<MTLRenderPipelineState> state = self.pipelineCache[key];

    if (!state) {
        NSError *error = nil;
        state = [self.device newRenderPipelineStateWithDescriptor:descriptor error:&error];
        if (error) {
            NSLog(@"[Mashkal] Pipeline error: %@", error);
        } else {
            self.pipelineCache[key] = state;
        }
    }

    return state;
}

- (id<MTLDepthStencilState>)depthStencilState {
    MTLDepthStencilDescriptor *descriptor = [[MTLDepthStencilDescriptor alloc] init];
    descriptor.depthCompareFunction = MTLCompareFunctionLess;
    descriptor.depthWriteEnabled = YES;
    return [self.device newDepthStencilStateWithDescriptor:descriptor];
}

- (id<MTLBuffer>)bufferWithLength:(NSUInteger)length {
    // Check cache for reusable buffer
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    for (MetalBuffer *metalBuffer in self.bufferCache) {
        if (metalBuffer.buffer.length >= length && (now - metalBuffer.lastReuseTime) > 1.0) {
            metalBuffer.lastReuseTime = now;
            return metalBuffer.buffer;
        }
    }

    // Create new buffer
    id<MTLBuffer> buffer = [self.device newBufferWithLength:length options:MTLResourceStorageModeShared];
    MetalBuffer *metalBuffer = [[MetalBuffer alloc] initWithBuffer:buffer];
    metalBuffer.lastReuseTime = now;
    [self.bufferCache addObject:metalBuffer];

    // Purge old buffers if too many
    if (self.bufferCache.count > 50) {
        [self purgeOldBuffers];
    }

    return buffer;
}

- (void)returnBuffer:(id<MTLBuffer>)buffer {
    // Buffer returned to cache automatically
}

- (void)purgeOldBuffers {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSMutableArray *toRemove = [NSMutableArray array];

    for (MetalBuffer *metalBuffer in self.bufferCache) {
        if ((now - metalBuffer.lastReuseTime) > 10.0) {
            [toRemove addObject:metalBuffer];
        }
    }

    [self.bufferCache removeObjectsInArray:toRemove];
}

- (id<MTLTexture>)textureWithDescriptor:(MTLTextureDescriptor *)descriptor {
    return [self.device newTextureWithDescriptor:descriptor];
}

@end
