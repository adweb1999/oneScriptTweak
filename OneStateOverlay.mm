//
//  OneStateOverlay.mm
//  Mashkal
//  Modern Overlay Implementation with ImGui + Metal
//

#import "OneStateOverlay.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

// ============================================================================
// MARK: - Constants
// ============================================================================

static NSString * const kOverlayWindowKey = @"com.mashkal.overlay.window";
static NSString * const kSecurityKeychainService = @"com.mashkal.security";
static NSString * const kActivationDateKey = @"activation_date";
static NSString * const kExpirationDateKey = @"expiration_date";
static NSString * const kProtectedPasswordHash = @"5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"; // "password" SHA256

static const CGFloat kOverlayWidth = 350.0f;
static const CGFloat kOverlayHeight = 500.0f;
static const CGFloat kToggleButtonSize = 50.0f;

// ============================================================================
// MARK: - OneStateOverlay Implementation
// ============================================================================

@implementation OneStateOverlay {
    MetalRenderer *_renderer;
    SecurityManager *_securityManager;
    ImGuiMenu *_menu;
    BOOL _isVisible;
    CGPoint _dragStartPoint;
    CGPoint _windowStartPoint;
}

+ (instancetype)sharedInstance {
    static OneStateOverlay *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    CGRect frame = CGRectMake(20, 100, kOverlayWidth, kOverlayHeight);
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWindow];
        [self setupSecurity];
        [self setupMetal];
        [self setupUI];
        [self setupGestures];
    }
    return self;
}

- (void)setupWindow {
    self.windowLevel = UIWindowLevelAlert + 100;
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 16.0f;

    // Shadow
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.3f;
    self.layer.shadowRadius = 10.0f;
    self.layer.shadowOffset = CGSizeMake(0, 5);
}

- (void)setupSecurity {
    _securityManager = [SecurityManager sharedInstance];

    if (![_securityManager isActivatedAndValid]) {
        [self presentActivationDialog];
    }
}

- (void)setupMetal {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        NSLog(@"[Mashkal] Metal not supported on this device");
        return;
    }

    _mtkView = [[MTKView alloc] initWithFrame:self.bounds device:device];
    _mtkView.backgroundColor = [UIColor clearColor];
    _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    _mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    _mtkView.sampleCount = 1;
    _mtkView.paused = NO;
    _mtkView.enableSetNeedsDisplay = NO;
    _mtkView.preferredFramesPerSecond = 60;
    _mtkView.delegate = self;

    [self addSubview:_mtkView];

    _renderer = [[MetalRenderer alloc] initWithDevice:device];
    _menu = [[ImGuiMenu alloc] initWithRenderer:_renderer];

    // Setup ImGui
    [_renderer setupImGui];
}

- (void)setupUI {
    // Toggle Button (Floating)
    _toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _toggleButton.frame = CGRectMake(0, 0, kToggleButtonSize, kToggleButtonSize);
    _toggleButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
    _toggleButton.layer.cornerRadius = kToggleButtonSize / 2;
    _toggleButton.layer.masksToBounds = YES;
    [_toggleButton setTitle:@"⚡" forState:UIControlStateNormal];
    [_toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _toggleButton.titleLabel.font = [UIFont systemFontOfSize:24];
    [_toggleButton addTarget:self action:@selector(toggleOverlay) forControlEvents:UIControlEventTouchUpInside];

    // Add shadow to toggle button
    _toggleButton.layer.shadowColor = [UIColor blackColor].CGColor;
    _toggleButton.layer.shadowOpacity = 0.4f;
    _toggleButton.layer.shadowRadius = 6.0f;
    _toggleButton.layer.shadowOffset = CGSizeMake(0, 3);

    // Drag Handle
    _dragHandle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kOverlayWidth, 40)];
    _dragHandle.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:0.95];
    _dragHandle.layer.cornerRadius = 16.0f;
    _dragHandle.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;

    // Title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 20)];
    titleLabel.text = @"⚡ Mashkal Overlay";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [_dragHandle addSubview:titleLabel];

    // Close button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(kOverlayWidth - 40, 5, 30, 30);
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithWhite:0.7 alpha:1.0] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(hideOverlay) forControlEvents:UIControlEventTouchUpInside];
    [_dragHandle addSubview:closeButton];

    [self addSubview:_dragHandle];
    [_mtkView setFrame:CGRectMake(0, 40, kOverlayWidth, kOverlayHeight - 40)];
}

- (void)setupGestures {
    // Pan gesture for dragging
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_dragHandle addGestureRecognizer:panGesture];

    // Pinch gesture for resizing
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self addGestureRecognizer:pinchGesture];

    // Tap gesture for toggle button
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOverlay)];
    [_toggleButton addGestureRecognizer:tapGesture];
}

// ============================================================================
// MARK: - Overlay Control
// ============================================================================

- (void)showOverlay {
    if (![_securityManager isActivatedAndValid]) {
        [self presentActivationDialog];
        return;
    }

    self.hidden = NO;
    _isVisible = YES;

    // Add toggle button to key window
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (![_toggleButton isDescendantOfView:keyWindow]) {
        [keyWindow addSubview:_toggleButton];
        _toggleButton.center = CGPointMake(keyWindow.bounds.size.width - 40, keyWindow.bounds.size.height / 2);
    }

    // Animation
    self.transform = CGAffineTransformMakeScale(0.8, 0.8);
    self.alpha = 0;

    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1.0;
    } completion:nil];
}

- (void)hideOverlay {
    [UIView animateWithDuration:0.2 animations:^{
        self.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        _isVisible = NO;
        self.transform = CGAffineTransformIdentity;
    }];
}

- (void)toggleOverlay {
    if (_isVisible) {
        [self hideOverlay];
    } else {
        [self showOverlay];
    }
}

- (BOOL)isVisible {
    return _isVisible;
}

// ============================================================================
// MARK: - Gesture Handlers
// ============================================================================

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];

    if (gesture.state == UIGestureRecognizerStateBegan) {
        _windowStartPoint = self.frame.origin;
    }

    CGPoint newOrigin = CGPointMake(_windowStartPoint.x + translation.x, _windowStartPoint.y + translation.y);

    // Keep within screen bounds
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    CGFloat maxX = keyWindow.bounds.size.width - self.frame.size.width;
    CGFloat maxY = keyWindow.bounds.size.height - self.frame.size.height;

    newOrigin.x = MAX(0, MIN(newOrigin.x, maxX));
    newOrigin.y = MAX(0, MIN(newOrigin.y, maxY));

    self.frame = CGRectMake(newOrigin.x, newOrigin.y, self.frame.size.width, self.frame.size.height);
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat scale = gesture.scale;
        CGFloat newWidth = kOverlayWidth * scale;
        CGFloat newHeight = kOverlayHeight * scale;

        // Limit size
        newWidth = MAX(250, MIN(newWidth, 500));
        newHeight = MAX(350, MIN(newHeight, 700));

        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, newHeight);
        _mtkView.frame = CGRectMake(0, 40, newWidth, newHeight - 40);
        _dragHandle.frame = CGRectMake(0, 0, newWidth, 40);
    }
}

// ============================================================================
// MARK: - Activation Dialog
// ============================================================================

- (void)presentActivationDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔐 تفعيل Mashkal"
                                                                     message:@"أدخل كلمة المرور لتفعيل الخصائص لمدة 7 أيام"
                                                              preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"كلمة المرور";
        textField.secureTextEntry = YES;
        textField.textAlignment = NSTextAlignmentCenter;
    }];

    UIAlertAction *activateAction = [UIAlertAction actionWithTitle:@"تفعيل ✅"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
        UITextField *passwordField = alert.textFields[0];
        if ([_securityManager activateWithPassword:passwordField.text]) {
            [self showSuccessAlert:@"تم التفعيل بنجاح لمدة 7 أيام! 🎉"];
            [self showOverlay];
        } else {
            [self showErrorAlert:@"كلمة المرور غير صحيحة ❌"];
            [self presentActivationDialog];
        }
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"إلغاء"
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self disableFeatures];
    }];

    [alert addAction:activateAction];
    [alert addAction:cancelAction];

    [self presentAlert:alert];
}

- (void)showErrorAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"❌ خطأ"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
    [self presentAlert:alert];
}

- (void)showSuccessAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅ نجاح"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
    [self presentAlert:alert];
}

- (void)presentAlert:(UIAlertController *)alert {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *rootVC = keyWindow.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)disableFeatures {
    self.hidden = YES;
    [_toggleButton removeFromSuperview];
    NSLog(@"[Mashkal] Features disabled");
}

// ============================================================================
// MARK: - MTKViewDelegate
// ============================================================================

- (void)drawInMTKView:(MTKView *)view {
    if (![_securityManager isActivatedAndValid]) {
        return;
    }

    [_renderer renderToView:view];
    [_menu renderMenu];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    [_renderer resize:size];
}

// ============================================================================
// MARK: - Touch Handling for ImGui
// ============================================================================

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    for (UITouch *touch in touches) {
        [_renderer processTouchEvent:touch];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    for (UITouch *touch in touches) {
        [_renderer processTouchEvent:touch];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    for (UITouch *touch in touches) {
        [_renderer processTouchEvent:touch];
    }
}

@end
