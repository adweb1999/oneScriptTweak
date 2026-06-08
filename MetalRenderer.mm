//
//  MetalRenderer.mm
//  Mashkal
//  Metal + ImGui Renderer
//

#import "OneStateOverlay.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

// ============================================================================
// MARK: - MetalRenderer Implementation
// ============================================================================

@implementation MetalRenderer {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    MetalContext *_context;

    // ImGui Resources
    id<MTLRenderPipelineState> _imguiPipelineState;
    id<MTLDepthStencilState> _imguiDepthStencilState;
    id<MTLBuffer> _vertexBuffer;
    id<MTLBuffer> _indexBuffer;
    id<MTLTexture> _fontTexture;

    // Performance
    CFTimeInterval _lastFrameTime;
    CFTimeInterval _currentFPS;
    CFTimeInterval _frameTime;

    // Touch
    CGPoint _lastTouchLocation;
    BOOL _isTouching;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    self = [super init];
    if (self) {
        _device = device;
        _commandQueue = [_device newCommandQueue];
        _context = [MetalContext sharedContextWithDevice:device];
        _lastFrameTime = CACurrentMediaTime();
    }
    return self;
}

// ============================================================================
// MARK: - ImGui Setup
// ============================================================================

- (void)setupImGui {
    // Initialize ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO();

    // Enable features
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;

    // Setup style
    [self setupImGuiStyle];

    // Setup fonts
    [self setupFonts];

    // Setup Metal backend
    [self setupMetalBackend];

    NSLog(@"[Mashkal] ImGui initialized successfully");
}

- (void)setupImGuiStyle {
    ImGuiStyle &style = ImGui::GetStyle();
    ImVec4 *colors = style.Colors;

    // Modern dark theme with blue accents
    colors[ImGuiCol_WindowBg] = ImVec4(0.08f, 0.08f, 0.12f, 0.95f);
    colors[ImGuiCol_Border] = ImVec4(0.15f, 0.20f, 0.35f, 0.50f);
    colors[ImGuiCol_FrameBg] = ImVec4(0.12f, 0.15f, 0.22f, 1.00f);
    colors[ImGuiCol_FrameBgHovered] = ImVec4(0.18f, 0.22f, 0.35f, 1.00f);
    colors[ImGuiCol_FrameBgActive] = ImVec4(0.25f, 0.30f, 0.50f, 1.00f);
    colors[ImGuiCol_TitleBg] = ImVec4(0.10f, 0.15f, 0.30f, 1.00f);
    colors[ImGuiCol_TitleBgActive] = ImVec4(0.15f, 0.25f, 0.50f, 1.00f);
    colors[ImGuiCol_Button] = ImVec4(0.20f, 0.40f, 0.80f, 1.00f);
    colors[ImGuiCol_ButtonHovered] = ImVec4(0.25f, 0.50f, 1.00f, 1.00f);
    colors[ImGuiCol_ButtonActive] = ImVec4(0.30f, 0.60f, 1.00f, 1.00f);
    colors[ImGuiCol_Header] = ImVec4(0.20f, 0.40f, 0.80f, 0.50f);
    colors[ImGuiCol_HeaderHovered] = ImVec4(0.25f, 0.50f, 1.00f, 0.60f);
    colors[ImGuiCol_HeaderActive] = ImVec4(0.30f, 0.60f, 1.00f, 0.70f);
    colors[ImGuiCol_SliderGrab] = ImVec4(0.20f, 0.40f, 0.80f, 1.00f);
    colors[ImGuiCol_SliderGrabActive] = ImVec4(0.30f, 0.60f, 1.00f, 1.00f);
    colors[ImGuiCol_CheckMark] = ImVec4(0.20f, 0.80f, 0.40f, 1.00f);
    colors[ImGuiCol_Text] = ImVec4(0.90f, 0.90f, 0.95f, 1.00f);
    colors[ImGuiCol_TextDisabled] = ImVec4(0.50f, 0.50f, 0.55f, 1.00f);

    // Rounding
    style.WindowRounding = 12.0f;
    style.FrameRounding = 8.0f;
    style.GrabRounding = 8.0f;
    style.PopupRounding = 8.0f;
    style.ScrollbarRounding = 8.0f;
    style.TabRounding = 8.0f;

    // Spacing
    style.WindowPadding = ImVec2(12.0f, 12.0f);
    style.FramePadding = ImVec2(8.0f, 6.0f);
    style.ItemSpacing = ImVec2(8.0f, 6.0f);
    style.ItemInnerSpacing = ImVec2(6.0f, 4.0f);
}

- (void)setupFonts {
    ImGuiIO &io = ImGui::GetIO();

    // Load default font
    io.Fonts->AddFontDefault();

    // You can add custom fonts here
    // io.Fonts->AddFontFromFileTTF("/path/to/font.ttf", 16.0f);

    // Build font atlas
    unsigned char *pixels;
    int width, height;
    io.Fonts->GetTexDataAsRGBA32(&pixels, &width, &height);

    // Create Metal texture
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                          width:width
                                                                                         height:height
                                                                                      mipmapped:NO];
    _fontTexture = [_device newTextureWithDescriptor:descriptor];

    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [_fontTexture replaceRegion:region mipmapLevel:0 withBytes:pixels bytesPerRow:width * 4];

    io.Fonts->SetTexID((__bridge void *)_fontTexture);
}

- (void)setupMetalBackend {
    // Create render pipeline for ImGui
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = [self loadShaderFunction:@"imgui_vertex"];
    pipelineDescriptor.fragmentFunction = [self loadShaderFunction:@"imgui_fragment"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    NSError *error = nil;
    _imguiPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (error) {
        NSLog(@"[Mashkal] Pipeline error: %@", error);
    }

    // Depth stencil
    MTLDepthStencilDescriptor *depthDescriptor = [[MTLDepthStencilDescriptor alloc] init];
    depthDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
    depthDescriptor.depthWriteEnabled = NO;
    _imguiDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthDescriptor];
}

- (id<MTLFunction>)loadShaderFunction:(NSString *)name {
    // In a real implementation, you'd load from a .metallib file
    // For now, we'll use inline shaders or precompiled library

    NSString *shaderSource = @"
        #include <metal_stdlib>

        using namespace metal;

        

        struct VertexIn {

            float2 position [[attribute(0)]];

            float2 texCoord [[attribute(1)]];

            float4 color [[attribute(2)]];

        };

        

        struct VertexOut {

            float4 position [[position]];

            float2 texCoord;

            float4 color;

        };

        

        vertex VertexOut imgui_vertex(VertexIn in [[stage_in]],

                                      constant float4x4 &projection [[buffer(1)]]) {

            VertexOut out;

            out.position = projection * float4(in.position, 0.0, 1.0);

            out.texCoord = in.texCoord;

            out.color = in.color;

            return out;

        }

        

        fragment float4 imgui_fragment(VertexOut in [[stage_in]],

                                       texture2d<float> fontTexture [[texture(0)]],

                                       sampler fontSampler [[sampler(0)]]) {

            float4 color = in.color;

            if (fontTexture) {

                color.a *= fontTexture.sample(fontSampler, in.texCoord).r;

            }

            return color;

        }

    ";

    NSError *error = nil;
    id<MTLLibrary> library = [_device newLibraryWithSource:shaderSource options:nil error:&error];
    if (error) {
        NSLog(@"[Mashkal] Shader compilation error: %@", error);
        return nil;
    }

    return [library newFunctionWithName:name];
}

// ============================================================================
// MARK: - Rendering
// ============================================================================

- (void)renderToView:(MTKView *)view {
    CFTimeInterval currentTime = CACurrentMediaTime();
    _frameTime = currentTime - _lastFrameTime;
    _currentFPS = 1.0 / _frameTime;
    _lastFrameTime = currentTime;

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    MTLRenderPassDescriptor *passDescriptor = view.currentRenderPassDescriptor;

    if (!passDescriptor) {
        return;
    }

    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

    // Setup viewport
    CGSize drawableSize = view.drawableSize;
    MTLViewport viewport = {0.0, 0.0, drawableSize.width, drawableSize.height, 0.0, 1.0};
    [encoder setViewport:viewport];

    // Render ImGui
    [self renderImGuiWithEncoder:encoder view:view];

    [encoder endEncoding];

    // Present
    id<MTLDrawable> drawable = view.currentDrawable;
    if (drawable) {
        [commandBuffer presentDrawable:drawable];
    }

    [commandBuffer commit];
}

- (void)renderImGuiWithEncoder:(id<MTLRenderCommandEncoder>)encoder view:(MTKView *)view {
    ImGui::Render();
    ImDrawData *drawData = ImGui::GetDrawData();

    if (!drawData || drawData->CmdListsCount == 0) {
        return;
    }

    [encoder setRenderPipelineState:_imguiPipelineState];
    [encoder setDepthStencilState:_imguiDepthStencilState];

    // Setup projection matrix
    CGSize size = view.drawableSize;
    float orthoProjection[4][4] = {
        { 2.0f/size.width, 0.0f, 0.0f, 0.0f },
        { 0.0f, 2.0f/-size.height, 0.0f, 0.0f },
        { 0.0f, 0.0f, -1.0f, 0.0f },
        { -1.0f, 1.0f, 0.0f, 1.0f }
    };

    [encoder setVertexBytes:orthoProjection length:sizeof(orthoProjection) atIndex:1];

    // Render command lists
    for (int n = 0; n < drawData->CmdListsCount; n++) {
        const ImDrawList *cmdList = drawData->CmdLists[n];

        // Update vertex/index buffers
        [self updateBuffersWithCommandList:cmdList encoder:encoder];

        // Draw commands
        for (int cmd_i = 0; cmd_i < cmdList->CmdBuffer.Size; cmd_i++) {
            const ImDrawCmd *cmd = &cmdList->CmdBuffer[cmd_i];

            if (cmd->UserCallback) {
                cmd->UserCallback(cmdList, cmd);
            } else {
                MTLScissorRect scissor = {
                    (NSUInteger)cmd->ClipRect.x,
                    (NSUInteger)(size.height - cmd->ClipRect.w),
                    (NSUInteger)(cmd->ClipRect.z - cmd->ClipRect.x),
                    (NSUInteger)(cmd->ClipRect.w - cmd->ClipRect.y)
                };
                [encoder setScissorRect:scissor];

                if (cmd->TextureId) {
                    [encoder setFragmentTexture:(__bridge id<MTLTexture>)cmd->TextureId atIndex:0];
                }

                [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                    indexCount:cmd->ElemCount
                                     indexType:MTLIndexTypeUInt16
                                   indexBuffer:_indexBuffer
                             indexBufferOffset:cmd->IdxOffset * sizeof(ImDrawIdx)
                                vertexBuffer:_vertexBuffer
                          vertexBufferOffset:cmd->VtxOffset * sizeof(ImDrawVert)];
            }
        }
    }
}

- (void)updateBuffersWithCommandList:(const ImDrawList *)cmdList encoder:(id<MTLRenderCommandEncoder>)encoder {
    // Update vertex buffer
    NSUInteger vertexSize = cmdList->VtxBuffer.Size * sizeof(ImDrawVert);
    if (!_vertexBuffer || _vertexBuffer.length < vertexSize) {
        _vertexBuffer = [_device newBufferWithLength:vertexSize options:MTLResourceStorageModeShared];
    }
    memcpy(_vertexBuffer.contents, cmdList->VtxBuffer.Data, vertexSize);

    // Update index buffer
    NSUInteger indexSize = cmdList->IdxBuffer.Size * sizeof(ImDrawIdx);
    if (!_indexBuffer || _indexBuffer.length < indexSize) {
        _indexBuffer = [_device newBufferWithLength:indexSize options:MTLResourceStorageModeShared];
    }
    memcpy(_indexBuffer.contents, cmdList->IdxBuffer.Data, indexSize);

    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
}

- (void)resize:(CGSize)size {
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize = ImVec2(size.width, size.height);
    io.DisplayFramebufferScale = ImVec2(1.0f, 1.0f);
}

// ============================================================================
// MARK: - Touch Input
// ============================================================================

- (void)processTouchEvent:(UITouch *)touch {
    ImGuiIO &io = ImGui::GetIO();
    CGPoint location = [touch locationInView:touch.view];

    switch (touch.phase) {
        case UITouchPhaseBegan:
            io.MousePos = ImVec2(location.x, location.y);
            io.MouseDown[0] = true;
            _isTouching = YES;
            break;

        case UITouchPhaseMoved:
            io.MousePos = ImVec2(location.x, location.y);
            _lastTouchLocation = location;
            break;

        case UITouchPhaseEnded:
        case UITouchPhaseCancelled:
            io.MouseDown[0] = false;
            _isTouching = NO;
            break;

        default:
            break;
    }
}

// ============================================================================
// MARK: - Performance Getters
// ============================================================================

- (double)fps {
    return _currentFPS;
}

- (double)frameTime {
    return _frameTime * 1000.0; // Convert to milliseconds
}

@end
