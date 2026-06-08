//
//  SecurityManager.mm
//  Mashkal
//  Advanced Security & Activation System
//

#import "OneStateOverlay.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

// ============================================================================
// MARK: - Constants
// ============================================================================

static NSString * const kKeychainService = @"com.mashkal.security";
static NSString * const kActivationDateKey = @"activation_date";
static NSString * const kExpirationDateKey = @"expiration_date";
static NSString * const kActivationCountKey = @"activation_count";
static NSString * const kDeviceIDKey = @"device_id";
static NSString * const kProtectedPassword = @"halak"; // كلمة المرور الافتراضية
static const NSInteger kActivationDays = 7;

// ============================================================================
// MARK: - SecurityManager Implementation
// ============================================================================

@implementation SecurityManager

+ (instancetype)sharedInstance {
    static SecurityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializeDeviceID];
    }
    return self;
}

// ============================================================================
// MARK: - Device Identification
// ============================================================================

- (void)initializeDeviceID {
    NSString *deviceID = [self loadFromKeychain:kDeviceIDKey];
    if (!deviceID) {
        deviceID = [[NSUUID UUID] UUIDString];
        [self saveToKeychain:deviceID forKey:kDeviceIDKey];
    }
}

- (NSString *)deviceID {
    return [self loadFromKeychain:kDeviceIDKey];
}

// ============================================================================
// MARK: - Password Validation
// ============================================================================

- (NSString *)hashPassword:(NSString *)password {
    if (!password || password.length == 0) {
        return nil;
    }

    const char *cStr = [password UTF8String];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cStr, (CC_LONG)strlen(cStr), digest);

    NSMutableString *hashString = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hashString appendFormat:@"%02x", digest[i]];
    }

    return hashString;
}

- (BOOL)validatePassword:(NSString *)password {
    if (!password || password.length == 0) {
        return NO;
    }

    NSString *inputHash = [self hashPassword:password];
    NSString *expectedHash = [self hashPassword:kProtectedPassword];

    return [inputHash isEqualToString:expectedHash];
}

// ============================================================================
// MARK: - Activation Management
// ============================================================================

- (BOOL)activateWithPassword:(NSString *)password {
    if (![self validatePassword:password]) {
        NSLog(@"[Mashkal] Invalid password attempt");
        return NO;
    }

    NSDate *now = [NSDate date];
    NSDate *expiration = [now dateByAddingTimeInterval:(kActivationDays * 24 * 60 * 60)];

    // Save activation data
    NSData *activationData = [NSKeyedArchiver archivedDataWithRootObject:now requiringSecureCoding:YES error:nil];
    NSData *expirationData = [NSKeyedArchiver archivedDataWithRootObject:expiration requiringSecureCoding:YES error:nil];

    [self saveToKeychain:activationData forKey:kActivationDateKey];
    [self saveToKeychain:expirationData forKey:kExpirationDateKey];

    // Increment activation count
    NSNumber *count = [self loadFromKeychain:kActivationCountKey] ?: @0;
    count = @([count integerValue] + 1);
    [self saveToKeychain:count forKey:kActivationCountKey];

    NSLog(@"[Mashkal] Activated for %ld days. Activation count: %@", (long)kActivationDays, count);
    return YES;
}

- (void)deactivate {
    [self deleteFromKeychain:kActivationDateKey];
    [self deleteFromKeychain:kExpirationDateKey];
    NSLog(@"[Mashkal] Deactivated");
}

- (BOOL)isActivatedAndValid {
    NSDate *expirationDate = [self expirationDate];

    if (!expirationDate) {
        return NO;
    }

    NSDate *now = [NSDate date];
    NSComparisonResult result = [now compare:expirationDate];

    if (result == NSOrderedDescending) {
        // Expired - clean up
        [self deactivate];
        return NO;
    }

    return YES;
}

- (BOOL)isActivated {
    return [self expirationDate] != nil;
}

// ============================================================================
// MARK: - Expiration Info
// ============================================================================

- (NSDate *)expirationDate {
    NSData *data = [self loadFromKeychain:kExpirationDateKey];
    if (!data) {
        return nil;
    }

    NSDate *date = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDate class] fromData:data error:nil];
    return date;
}

- (NSDate *)activationDate {
    NSData *data = [self loadFromKeychain:kActivationDateKey];
    if (!data) {
        return nil;
    }

    NSDate *date = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDate class] fromData:data error:nil];
    return date;
}

- (NSInteger)daysRemaining {
    NSDate *expiration = [self expirationDate];
    if (!expiration) {
        return 0;
    }

    NSDate *now = [NSDate date];
    NSTimeInterval interval = [expiration timeIntervalSinceDate:now];
    NSInteger days = (NSInteger)(interval / (24 * 60 * 60));

    return MAX(0, days);
}

- (NSInteger)daysLeft {
    return [self daysRemaining];
}

- (NSString *)activationStatus {
    if (![self isActivated]) {
        return @"غير مفعل ❌";
    }

    NSInteger days = [self daysRemaining];
    if (days <= 0) {
        return @"منتهي الصلاحية ⏰";
    }

    return [NSString stringWithFormat:@"مفعل - %ld يوم متبقي ✅", (long)days];
}

- (NSString *)statusMessage {
    return [self activationStatus];
}

// ============================================================================
// MARK: - Keychain Operations
// ============================================================================

- (BOOL)saveToKeychain:(id)data forKey:(NSString *)key {
    if (!data || !key) {
        return NO;
    }

    NSData *archivedData;
    if ([data isKindOfClass:[NSData class]]) {
        archivedData = data;
    } else if ([data isKindOfClass:[NSString class]]) {
        archivedData = [(NSString *)data dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([data isKindOfClass:[NSNumber class]]) {
        archivedData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:YES error:nil];
    } else {
        archivedData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:YES error:nil];
    }

    if (!archivedData) {
        return NO;
    }

    // Delete existing
    NSDictionary *deleteQuery = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: kKeychainService,
        (id)kSecAttrAccount: key
    };
    SecItemDelete((CFDictionaryRef)deleteQuery);

    // Add new
    NSDictionary *addQuery = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: kKeychainService,
        (id)kSecAttrAccount: key,
        (id)kSecValueData: archivedData,
        (id)kSecAttrAccessible: (id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    };

    OSStatus status = SecItemAdd((CFDictionaryRef)addQuery, NULL);
    return status == errSecSuccess;
}

- (id)loadFromKeychain:(NSString *)key {
    if (!key) {
        return nil;
    }

    NSDictionary *query = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: kKeychainService,
        (id)kSecAttrAccount: key,
        (id)kSecReturnData: @YES,
        (id)kSecMatchLimit: (id)kSecMatchLimitOne
    };

    CFDataRef result = NULL;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);

    if (status != errSecSuccess || !result) {
        return nil;
    }

    NSData *data = (__bridge_transfer NSData *)result;

    // Try to unarchive first
    id object = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:data error:nil];
    if (object) {
        return object;
    }

    // Try as string
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string) {
        return string;
    }

    return data;
}

- (BOOL)deleteFromKeychain:(NSString *)key {
    if (!key) {
        return NO;
    }

    NSDictionary *deleteQuery = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: kKeychainService,
        (id)kSecAttrAccount: key
    };

    OSStatus status = SecItemDelete((CFDictionaryRef)deleteQuery);
    return status == errSecSuccess || status == errSecItemNotFound;
}

@end
