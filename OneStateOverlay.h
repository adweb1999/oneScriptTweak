//
//  OneStateOverlay.h
//  Mashkal
//  Modern ImGui + Metal Overlay for iOS
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <objc/runtime.h>

// Forward declarations
@class MetalRenderer;
@class SecurityManager;
@class ImGuiMenu;

// ============================================================================
// MARK: - OneStateOverlay Interface
// ============================================================================

@interface OneStateOverlay : UIWindow <MTKViewDelegate>

+ (instancetype)sharedInstance;

// Overlay Control
- (void)showOverlay;
- (void)hideOverlay;
- (void)toggleOverlay;

// Properties
@property (nonatomic, readonly, getter=isVisible) BOOL visible;
@property (nonatomic, strong, readonly) MTKView *mtkView;
@property (nonatomic, strong, readonly) MetalRenderer *renderer;
@property (nonatomic, strong, readonly) ImGuiMenu *menu;

// UI Components
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *dragHandle;

// Security
@property (nonatomic, strong, readonly) SecurityManager *securityManager;

@end

// ============================================================================
// MARK: - SecurityManager
// ============================================================================

@interface SecurityManager : NSObject

+ (instancetype)sharedInstance;

// Activation
- (BOOL)isActivatedAndValid;
- (BOOL)activateWithPassword:(NSString *)password;
- (void)deactivate;

// Password validation
- (BOOL)validatePassword:(NSString *)password;
- (NSString *)hashPassword:(NSString *)password;

// Expiration
- (NSDate *)expirationDate;
- (NSInteger)daysRemaining;
- (NSString *)activationStatus;

// Keychain
- (BOOL)saveToKeychain:(id)data forKey:(NSString *)key;
- (id)loadFromKeychain:(NSString *)key;
- (BOOL)deleteFromKeychain:(NSString *)key;

@property (nonatomic, readonly, getter=isActivated) BOOL activated;
@property (nonatomic, readonly) NSInteger daysLeft;
@property (nonatomic, copy, readonly) NSString *statusMessage;

@end

// ============================================================================
// MARK: - MetalRenderer
// ============================================================================

@interface MetalRenderer : NSObject <MTKViewDelegate>

- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)renderToView:(MTKView *)view;
- (void)resize:(CGSize)size;

// ImGui Integration
- (void)setupImGui;
- (void)renderImGui;
- (void)processTouchEvent:(UITouch *)touch;

// Performance
@property (nonatomic, readonly) double fps;
@property (nonatomic, readonly) double frameTime;

@end

// ============================================================================
// MARK: - ImGuiMenu
// ============================================================================

@interface ImGuiMenu : NSObject

- (instancetype)initWithRenderer:(MetalRenderer *)renderer;
- (void)renderMenu;
- (void)toggleVisibility;

// Menu Sections
- (void)renderMainMenu;
- (void)renderSettingsMenu;
- (void)renderInfoPanel;
- (void)renderSecurityPanel;

@property (nonatomic, getter=isVisible) BOOL visible;
@property (nonatomic, strong) MetalRenderer *renderer;

@end

// ============================================================================
// MARK: - MetalContext (Resource Manager)
// ============================================================================

@interface MetalContext : NSObject

+ (instancetype)sharedContextWithDevice:(id<MTLDevice>)device;

// Pipeline States
- (id<MTLRenderPipelineState>)pipelineStateForDescriptor:(MTLRenderPipelineDescriptor *)descriptor;
- (id<MTLDepthStencilState>)depthStencilState;

// Buffer Management
- (id<MTLBuffer>)bufferWithLength:(NSUInteger)length;
- (void)returnBuffer:(id<MTLBuffer>)buffer;
- (void)purgeOldBuffers;

// Texture Management
- (id<MTLTexture>)textureWithDescriptor:(MTLTextureDescriptor *)descriptor;

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) NSMutableDictionary *pipelineCache;
@property (nonatomic, strong) NSMutableArray *bufferCache;

@end

// ============================================================================
// MARK: - FramebufferDescriptor
// ============================================================================

@interface FramebufferDescriptor : NSObject <NSCopying>

@property (nonatomic, assign) NSUInteger sampleCount;
@property (nonatomic, assign) MTLPixelFormat colorPixelFormat;
@property (nonatomic, assign) MTLPixelFormat depthPixelFormat;
@property (nonatomic, assign) MTLPixelFormat stencilPixelFormat;

- (instancetype)initWithView:(MTKView *)view;
- (BOOL)isEqualToDescriptor:(FramebufferDescriptor *)other;

@end

// ============================================================================
// MARK: - MetalBuffer
// ============================================================================

@interface MetalBuffer : NSObject

@property (nonatomic, strong) id<MTLBuffer> buffer;
@property (nonatomic, assign) NSTimeInterval lastReuseTime;

- (instancetype)initWithBuffer:(id<MTLBuffer>)buffer;
+ (instancetype)bufferWithMTLBuffer:(id<MTLBuffer>)buffer;

@end

// ============================================================================
// MARK: - MetalTexture
// ============================================================================

@interface MetalTexture : NSObject

@property (nonatomic, strong) id<MTLTexture> metalTexture;

- (instancetype)initWithTexture:(id<MTLTexture>)texture;
+ (instancetype)textureWithMTLTexture:(id<MTLTexture>)texture;

@end
