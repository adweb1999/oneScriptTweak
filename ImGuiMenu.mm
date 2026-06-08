//
//  ImGuiMenu.mm
//  Mashkal
//  Interactive ImGui Menu System
//

#import "OneStateOverlay.h"

// ============================================================================
// MARK: - ImGuiMenu Implementation
// ============================================================================

@implementation ImGuiMenu {
    MetalRenderer *_renderer;
    BOOL _visible;

    // Menu State
    int _selectedTab;
    BOOL _showDemoWindow;
    BOOL _showStyleEditor;

    // Settings
    float _menuOpacity;
    float _animationSpeed;
    BOOL _enableAnimations;
    BOOL _enableShadows;

    // Feature Toggles
    BOOL _feature1;
    BOOL _feature2;
    BOOL _feature3;
    float _sliderValue;
    int _comboIndex;

    // Info
    char _username[64];
    char _email[128];
}

- (instancetype)initWithRenderer:(MetalRenderer *)renderer {
    self = [super init];
    if (self) {
        _renderer = renderer;
        _visible = YES;
        _selectedTab = 0;
        _menuOpacity = 0.95f;
        _animationSpeed = 1.0f;
        _enableAnimations = YES;
        _enableShadows = YES;
        _feature1 = NO;
        _feature2 = NO;
        _feature3 = NO;
        _sliderValue = 50.0f;
        _comboIndex = 0;

        strcpy(_username, "User");
        strcpy(_email, "user@example.com");
    }
    return self;
}

- (void)renderMenu {
    if (!_visible) {
        return;
    }

    ImGuiIO &io = ImGui::GetIO();

    // Setup main window
    ImGui::SetNextWindowPos(ImVec2(0, 0), ImGuiCond_Always);
    ImGui::SetNextWindowSize(io.DisplaySize, ImGuiCond_Always);

    ImGuiWindowFlags windowFlags = ImGuiWindowFlags_NoTitleBar |
                                    ImGuiWindowFlags_NoResize |
                                    ImGuiWindowFlags_NoMove |
                                    ImGuiWindowFlags_NoScrollbar |
                                    ImGuiWindowFlags_NoScrollWithMouse |
                                    ImGuiWindowFlags_NoCollapse |
                                    ImGuiWindowFlags_NoBringToFrontOnFocus;

    ImGui::Begin("MashkalMain", NULL, windowFlags);

    // Render header
    [self renderHeader];

    // Render tabs
    [self renderTabs];

    // Render content based on selected tab
    switch (_selectedTab) {
        case 0:
            [self renderMainPanel];
            break;
        case 1:
            [self renderFeaturesPanel];
            break;
        case 2:
            [self renderSettingsPanel];
            break;
        case 3:
            [self renderSecurityPanel];
            break;
        case 4:
            [self renderInfoPanel];
            break;
    }

    // Render footer
    [self renderFooter];

    ImGui::End();

    // Demo window (optional)
    if (_showDemoWindow) {
        ImGui::ShowDemoWindow(&_showDemoWindow);
    }

    // Style editor (optional)
    if (_showStyleEditor) {
        ImGui::ShowStyleEditor();
    }
}

- (void)renderHeader {
    ImDrawList *drawList = ImGui::GetWindowDrawList();
    ImVec2 windowPos = ImGui::GetWindowPos();
    ImVec2 windowSize = ImGui::GetWindowSize();

    // Header background
    ImVec2 headerMin = windowPos;
    ImVec2 headerMax = ImVec2(windowPos.x + windowSize.x, windowPos.y + 50);
    drawList->AddRectFilled(headerMin, headerMax, IM_COL32(15, 25, 50, 255), 12.0f, ImDrawCornerFlags_Top);

    // Title
    ImGui::SetCursorPos(ImVec2(15, 12));
    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "⚡ Mashkal Overlay");

    // Version
    ImGui::SameLine(windowSize.x - 80);
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.6f, 1.0f), "v2.0");

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();
}

- (void)renderTabs {
    const char *tabs[] = {"الرئيسية", "الخصائص", "الإعدادات", "الحماية", "معلومات"};
    int tabCount = 5;

    ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 8.0f);

    for (int i = 0; i < tabCount; i++) {
        if (i > 0) {
            ImGui::SameLine();
        }

        bool isSelected = (_selectedTab == i);

        if (isSelected) {
            ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.2f, 0.4f, 0.8f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.25f, 0.5f, 1.0f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.3f, 0.6f, 1.0f, 1.0f));
        } else {
            ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.1f, 0.12f, 0.18f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.15f, 0.2f, 0.3f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.2f, 0.3f, 0.5f, 1.0f));
        }

        if (ImGui::Button(tabs[i], ImVec2(65, 32))) {
            _selectedTab = i;
        }

        ImGui::PopStyleColor(3);
    }

    ImGui::PopStyleVar();
    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();
}

- (void)renderMainPanel {
    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "📊 لوحة التحكم الرئيسية");
    ImGui::Spacing();

    // Stats cards
    ImGui::Columns(3, "stats", false);

    [self renderStatCard:@"FPS" value:[NSString stringWithFormat:@"%.0f", _renderer.fps] color:IM_COL32(50, 200, 100, 255)];
    ImGui::NextColumn();
    [self renderStatCard:@"Frame Time" value:[NSString stringWithFormat:@"%.2f ms", _renderer.frameTime] color:IM_COL32(200, 150, 50, 255)];
    ImGui::NextColumn();
    [self renderStatCard:@"Status" value:@"Active" color:IM_COL32(50, 150, 250, 255)];

    ImGui::Columns(1);
    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    // Quick actions
    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "⚡ إجراءات سريعة");
    ImGui::Spacing();

    if (ImGui::Button("إعادة تحميل", ImVec2(120, 35))) {
        NSLog(@"[Mashkal] Reload requested");
    }

    ImGui::SameLine();

    if (ImGui::Button("تصدير الإعدادات", ImVec2(120, 35))) {
        NSLog(@"[Mashkal] Export settings");
    }

    ImGui::SameLine();

    if (ImGui::Button("مسح الذاكرة", ImVec2(120, 35))) {
        NSLog(@"[Mashkal] Clear cache");
    }

    ImGui::Spacing();

    // Progress bars
    ImGui::Text("استخدام الذاكرة");
    ImGui::ProgressBar(0.65f, ImVec2(-1, 20), "65%%");

    ImGui::Text("استخدام المعالج");
    ImGui::ProgressBar(0.32f, ImVec2(-1, 20), "32%%");
}

- (void)renderStatCard:(NSString *)title value:(NSString *)value color:(ImU32)color {
    ImDrawList *drawList = ImGui::GetWindowDrawList();
    ImVec2 pos = ImGui::GetCursorScreenPos();
    ImVec2 size = ImVec2(ImGui::GetColumnWidth() - 10, 60);

    // Card background
    drawList->AddRectFilled(pos, ImVec2(pos.x + size.x, pos.y + size.y), IM_COL32(20, 25, 40, 255), 8.0f);

    // Accent line
    drawList->AddRectFilled(pos, ImVec2(pos.x + 4, pos.y + size.y), color, 8.0f, ImDrawCornerFlags_Left);

    // Text
    ImGui::SetCursorScreenPos(ImVec2(pos.x + 15, pos.y + 10));
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.6f, 1.0f), "%s", [title UTF8String]);

    ImGui::SetCursorScreenPos(ImVec2(pos.x + 15, pos.y + 30));
    ImGui::TextColored(ImVec4(1.0f, 1.0f, 1.0f, 1.0f), "%s", [value UTF8String]);

    ImGui::Dummy(size);
}

- (void)renderFeaturesPanel {
    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "🔧 الخصائص والميزات");
    ImGui::Spacing();

    // Feature toggles
    ImGui::Checkbox("تفعيل الميزة الأولى", &_feature1);
    ImGui::Checkbox("تفعيل الميزة الثانية", &_feature2);
    ImGui::Checkbox("تفعيل الميزة الثالثة", &_feature3);

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    // Slider
    ImGui::Text("شدة التأثير");
    ImGui::SliderFloat("##intensity", &_sliderValue, 0.0f, 100.0f, "%.1f%%");

    ImGui::Spacing();

    // Combo
    const char *items[] = {"وضع 1", "وضع 2", "وضع 3"};
    ImGui::Text("اختيار الوضع");
    ImGui::Combo("##mode", &_comboIndex, items, IM_ARRAYSIZE(items));

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    // Color picker
    static float color[4] = {0.2f, 0.6f, 1.0f, 1.0f};
    ImGui::Text("لون مخصص");
    ImGui::ColorEdit4("##color", color);
}

- (void)renderSettingsPanel {
    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "⚙️ الإعدادات");
    ImGui::Spacing();

    // Appearance
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.7f, 1.0f), "المظهر");
    ImGui::Spacing();

    ImGui::SliderFloat("شفافية القائمة", &_menuOpacity, 0.5f, 1.0f, "%.2f");
    ImGui::SliderFloat("سرعة الحركة", &_animationSpeed, 0.1f, 3.0f, "%.1fx");
    ImGui::Checkbox("تفعيل الحركات", &_enableAnimations);
    ImGui::Checkbox("تفعيل الظلال", &_enableShadows);

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    // Advanced
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.7f, 1.0f), "متقدم");
    ImGui::Spacing();

    if (ImGui::Button("فتح محرر الأنماط", ImVec2(150, 30))) {
        _showStyleEditor = !_showStyleEditor;
    }

    ImGui::SameLine();

    if (ImGui::Button("نافذة تجريبية", ImVec2(150, 30))) {
        _showDemoWindow = !_showDemoWindow;
    }

    ImGui::Spacing();

    if (ImGui::Button("إعادة ضبط الإعدادات", ImVec2(200, 35))) {
        _menuOpacity = 0.95f;
        _animationSpeed = 1.0f;
        _enableAnimations = YES;
        _enableShadows = YES;
    }
}

- (void)renderSecurityPanel {
    SecurityManager *security = [SecurityManager sharedInstance];

    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "🔐 إدارة الحماية");
    ImGui::Spacing();

    // Status card
    ImDrawList *drawList = ImGui::GetWindowDrawList();
    ImVec2 pos = ImGui::GetCursorScreenPos();
    ImVec2 size = ImVec2(ImGui::GetWindowWidth() - 30, 80);

    BOOL isActive = [security isActivatedAndValid];
    ImU32 statusColor = isActive ? IM_COL32(50, 200, 100, 255) : IM_COL32(200, 50, 50, 255);

    drawList->AddRectFilled(pos, ImVec2(pos.x + size.x, pos.y + size.y), IM_COL32(20, 25, 40, 255), 12.0f);
    drawList->AddRectFilled(pos, ImVec2(pos.x + 5, pos.y + size.y), statusColor, 12.0f, ImDrawCornerFlags_Left);

    ImGui::SetCursorScreenPos(ImVec2(pos.x + 20, pos.y + 15));
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.6f, 1.0f), "حالة التفعيل");

    ImGui::SetCursorScreenPos(ImVec2(pos.x + 20, pos.y + 40));
    ImGui::TextColored(ImVec4(1.0f, 1.0f, 1.0f, 1.0f), "%s", [[security activationStatus] UTF8String]);

    ImGui::Dummy(size);
    ImGui::Spacing();

    // Days remaining
    if (isActive) {
        ImGui::Text("الأيام المتبقية: %ld", (long)[security daysRemaining]);
        ImGui::ProgressBar((float)[security daysRemaining] / 7.0f, ImVec2(-1, 20));
    }

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    // Activation actions
    if (!isActive) {
        ImGui::TextColored(ImVec4(1.0f, 0.5f, 0.5f, 1.0f), "⚠️ التفعيل مطلوب");
        ImGui::Spacing();

        static char password[64] = "";
        ImGui::InputText("كلمة المرور", password, 64, ImGuiInputTextFlags_Password);

        if (ImGui::Button("تفعيل", ImVec2(120, 35))) {
            NSString *pass = [NSString stringWithUTF8String:password];
            if ([security activateWithPassword:pass]) {
                NSLog(@"[Mashkal] Activated via menu");
            }
        }
    } else {
        if (ImGui::Button("تجديد التفعيل", ImVec2(150, 35))) {
            [security deactivate];
        }

        ImGui::SameLine();

        if (ImGui::Button("تسجيل الخروج", ImVec2(150, 35))) {
            [security deactivate];
        }
    }
}

- (void)renderInfoPanel {
    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "ℹ️ معلومات");
    ImGui::Spacing();

    // About
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.7f, 1.0f), "عن التطبيق");
    ImGui::Spacing();
    ImGui::Text("Mashkal Overlay v2.0");
    ImGui::Text("iOS Tweak with ImGui + Metal");
    ImGui::Text("© 2026 Mashkal Team");

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    // Device info
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.7f, 1.0f), "معلومات الجهاز");
    ImGui::Spacing();

    UIDevice *device = [UIDevice currentDevice];
    ImGui::Text("الجهاز: %s", [[device model] UTF8String]);
    ImGui::Text("النظام: %s", [[device systemVersion] UTF8String]);
    ImGui::Text("الاسم: %s", [[device name] UTF8String]);

    ImGui::Spacing();
    ImGui::Separator();
    ImGui::Spacing();

    // Credits
    ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.7f, 1.0f), "الشكر والتقدير");
    ImGui::Spacing();
    ImGui::Text("• ImGui by Omar Cornut");
    ImGui::Text("• Metal by Apple");
    ImGui::Text("• Theos by iOS Developers");

    ImGui::Spacing();

    if (ImGui::Button("فتح GitHub", ImVec2(150, 30))) {
        NSLog(@"[Mashkal] Open GitHub");
    }

    ImGui::SameLine();

    if (ImGui::Button("إرسال feedback", ImVec2(150, 30))) {
        NSLog(@"[Mashkal] Send feedback");
    }
}

- (void)renderFooter {
    ImVec2 windowSize = ImGui::GetWindowSize();
    ImVec2 windowPos = ImGui::GetWindowPos();

    // Footer background
    ImDrawList *drawList = ImGui::GetWindowDrawList();
    ImVec2 footerMin = ImVec2(windowPos.x, windowPos.y + windowSize.y - 30);
    ImVec2 footerMax = ImVec2(windowPos.x + windowSize.x, windowPos.y + windowSize.y);
    drawList->AddRectFilled(footerMin, footerMax, IM_COL32(15, 20, 35, 255), 12.0f, ImDrawCornerFlags_Bottom);

    // Footer text
    ImGui::SetCursorPos(ImVec2(15, windowSize.y - 25));
    ImGui::TextColored(ImVec4(0.4f, 0.4f, 0.5f, 1.0f), "Mashkal v2.0 | Ready");

    // FPS counter
    ImGui::SetCursorPos(ImVec2(windowSize.x - 80, windowSize.y - 25));
    ImGui::TextColored(ImVec4(0.3f, 0.7f, 1.0f, 1.0f), "%.0f FPS", _renderer.fps);
}

- (void)toggleVisibility {
    _visible = !_visible;
}

- (BOOL)isVisible {
    return _visible;
}

@end
