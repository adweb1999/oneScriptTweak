//
//  Tweak.xm
//  Mashkal
//  iOS Tweak with ImGui + Metal Overlay
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "OneStateOverlay.h"

// ============================================================================
// MARK: - SpringBoard Hook (Entry Point)
// ============================================================================

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    // Initialize overlay after SpringBoard launches
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[OneStateOverlay sharedInstance] showOverlay];
    });
}

%end

// ============================================================================
// MARK: - UIApplication Hook (For all apps mode)
// ============================================================================

%hook UIApplication

- (void)_runWithMainScene:(id)scene transitionContext:(id)context completion:(id)completion {
    %orig;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (![OneStateOverlay sharedInstance].isVisible) {
                [[OneStateOverlay sharedInstance] showOverlay];
            }
        });
    });
}

%end

// ============================================================================
// MARK: - Constructor
// ============================================================================

%ctor {
    NSLog(@"[Mashkal] Tweak loaded successfully");

    // Initialize security manager
    [SecurityManager sharedInstance];

    // Register for app launch notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        NSLog(@"[Mashkal] App launched: %@", [[UIApplication sharedApplication] bundleIdentifier]);
    }];
}
