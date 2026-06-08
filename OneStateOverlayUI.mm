//
//  OneStateOverlayUI.mm
//  Mashkal
//  Enhanced UI Components
//

#import "OneStateOverlay.h"

// ============================================================================
// MARK: - UI Extensions for OneStateOverlay
// ============================================================================

@implementation OneStateOverlay (UIEnhancements)

- (void)setupEnhancedUI {
    // Background blur effect
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.bounds;
    blurView.alpha = 0.95;
    [self insertSubview:blurView atIndex:0];

    // Gradient overlay
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.bounds;
    gradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:0.9].CGColor,
        (__bridge id)[UIColor colorWithRed:0.1 green:0.15 blue:0.25 alpha:0.9].CGColor
    ];
    gradient.locations = @[@0.0, @1.0];
    [self.layer insertSublayer:gradient atIndex:1];

    // Animated border
    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.frame = self.bounds;
    borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:16.0].CGPath;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.strokeColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.8].CGColor;
    borderLayer.lineWidth = 2.0;
    [self.layer insertSublayer:borderLayer atIndex:2];

    // Animation for border
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @0.0;
    animation.toValue = @1.0;
    animation.duration = 1.0;
    animation.repeatCount = HUGE_VALF;
    animation.autoreverses = YES;
    [borderLayer addAnimation:animation forKey:@"borderAnimation"];
}

- (void)animateShow {
    self.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.alpha = 0;

    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1.0;
    } completion:nil];
}

- (void)animateHide {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.transform = CGAffineTransformMakeScale(0.5, 0.5);
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.transform = CGAffineTransformIdentity;
    }];
}

- (void)pulseToggleButton {
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @1.0;
    pulse.toValue = @1.2;
    pulse.duration = 0.5;
    pulse.repeatCount = 2;
    pulse.autoreverses = YES;
    [_toggleButton.layer addAnimation:pulse forKey:@"pulse"];
}

@end
