//
//  Apptentive.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "Apptentive.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveBannerViewController.h"
#import "ApptentiveUnreadMessagesBadgeView.h"
#import "ApptentiveAboutViewController.h"
#import "ApptentiveStyleSheet.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveMutablePerson.h"
#import "ApptentiveMutableDevice.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"

NSString *const ApptentiveMessageCenterUnreadCountChangedNotification = @"ApptentiveMessageCenterUnreadCountChangedNotification";

NSString *const ApptentiveAppRatingFlowUserAgreedToRateAppNotification = @"ApptentiveAppRatingFlowUserAgreedToRateAppNotification";

NSString *const ApptentiveSurveyShownNotification = @"ApptentiveSurveyShownNotification";
NSString *const ApptentiveSurveySentNotification = @"ApptentiveSurveySentNotification";
NSString *const ApptentiveSurveyIDKey = @"ApptentiveSurveyIDKey";

NSString *const ApptentiveCustomPersonDataChangedNotification = @"ApptentiveCustomPersonDataChangedNotification";
NSString *const ApptentiveCustomDeviceDataChangedNotification = @"ApptentiveCustomDeviceDataChangedNotification";
NSString *const ApptentiveInteractionsDidUpdateNotification = @"ApptentiveInteractionsDidUpdateNotification";
NSString *const ApptentiveConversationCreatedNotification = @"ApptentiveConversationCreatedNotification";

NSString *const ApptentiveCustomDeviceDataPreferenceKey = @"ApptentiveCustomDeviceDataPreferenceKey";
NSString *const ApptentiveCustomPersonDataPreferenceKey = @"ApptentiveCustomPersonDataPreferenceKey";


@interface Apptentive () <ApptentiveBannerViewControllerDelegate>
@end


@implementation Apptentive

@synthesize styleSheet = _styleSheet;

+ (NSString *)supportDirectoryPath {
	NSString *appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
	NSString *apptentiveDirectoryPath = [appSupportDirectoryPath stringByAppendingPathComponent:@"com.apptentive.feedback"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;

	if (![fm createDirectoryAtPath:apptentiveDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
		ApptentiveLogError(@"Failed to create support directory: %@", apptentiveDirectoryPath);
		ApptentiveLogError(@"Error was: %@", error);
		return nil;
	}

	if (![fm setAttributes:@{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication } ofItemAtPath:apptentiveDirectoryPath error:&error]) {
		ApptentiveLogError(@"Failed to set file protection level: %@", apptentiveDirectoryPath);
		ApptentiveLogError(@"Error was: %@", error);
	}

	return apptentiveDirectoryPath;
}

+ (instancetype)sharedConnection {
	static Apptentive *sharedConnection = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedConnection = [[Apptentive alloc] init];
	});
	return sharedConnection;
}

+ (instancetype)shared {
	return [self sharedConnection];
}

- (id)init {
	self = [super init];

	if (self) {
		_styleSheet = [[ApptentiveStyleSheet alloc] init];

		ApptentiveLogInfo(@"Apptentive SDK Version %@", [ApptentiveSDK SDKVersion].versionString);
	}
	return self;
}

- (void)setAPIKey:(NSString *)APIKey {
	[self setAPIKey:APIKey baseURL:[NSURL URLWithString:@"https://api.apptentive.com/"]];
}

- (void)setAPIKey:(NSString *)APIKey distributionName:(NSString *)distributionName distributionVersion:(NSString *)distributionVersionString {
	[ApptentiveSDK setDistributionName:distributionName];
	[ApptentiveSDK setDistributionVersion:[[ApptentiveVersion alloc] initWithString:distributionVersionString]];

	self.APIKey = APIKey;
}

- (void)setAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL {
	if (![self.APIKey isEqualToString:APIKey] || ![baseURL isEqual:self.baseURL]) {
		_APIKey = APIKey;
		_baseURL = baseURL;
		_backend = [[ApptentiveBackend alloc] initWithAPIKey:APIKey baseURL:baseURL];
		_engagementBackend = [[ApptentiveEngagementBackend alloc] init];
	}
}

- (NSString *)apiKey {
	return self.APIKey;
}

- (void)setApiKey:(NSString *)apiKey {
	self.APIKey = apiKey;
}

- (id<ApptentiveStyle>)styleSheet {
	[self.backend.session didOverrideStyles];

	return _styleSheet;
}

- (void)setStyleSheet:(id<ApptentiveStyle>)styleSheet {
	_styleSheet = styleSheet;

	[self.backend.session didOverrideStyles];
}

- (NSString *)personName {
	return self.backend.session.person.name;
}

- (void)setPersonName:(NSString *)personName {
	[self.backend.session updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = personName;
	}];
}

- (NSString *)personEmailAddress {
	return self.backend.session.person.emailAddress;
}

- (void)setPersonEmailAddress:(NSString *)personEmailAddress {
	[self.backend.session updatePerson:^(ApptentiveMutablePerson *person) {
		person.emailAddress = personEmailAddress;
	}];
}

- (void)sendAttachmentText:(NSString *)text {
	[self.backend sendTextMessageWithBody:text hiddenOnClient:YES];
}

- (void)sendAttachmentImage:(UIImage *)image {
	[self.backend sendImageMessageWithImage:image hiddenOnClient:YES];
}

- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType {
	[self.backend sendFileMessageWithFileData:fileData andMimeType:mimeType hiddenOnClient:YES];
}

- (NSDictionary *)customPersonData {
	return self.backend.session.person.customData;
}

- (NSDictionary *)customDeviceData {
	return self.backend.session.device.customData;
}

- (void)addCustomDeviceDataString:(NSString *)string withKey:(NSString *)key {
	[self.backend.session updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomString:string withKey:key];
	}];
}

- (void)addCustomDeviceDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.backend.session updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomNumber:number withKey:key];
	}];
}

- (void)addCustomDeviceDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.backend.session updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomBool:boolValue withKey:key];
	}];
}

- (void)addCustomPersonDataString:(NSString *)string withKey:(NSString *)key {
	[self.backend.session updatePerson:^(ApptentiveMutablePerson *person) {
		[person addCustomString:string withKey:key];
	}];
}

- (void)addCustomPersonDataNumber:(NSNumber *)number withKey:(NSString *)key {
	[self.backend.session updatePerson:^(ApptentiveMutablePerson *person) {
		[person addCustomNumber:number withKey:key];
	}];
}

- (void)addCustomPersonDataBool:(BOOL)boolValue withKey:(NSString *)key {
	[self.backend.session updatePerson:^(ApptentiveMutablePerson *person) {
		[person addCustomBool:boolValue withKey:key];
	}];
}

+ (NSDictionary *)versionObjectWithVersion:(NSString *)version {
	return @{ @"_type": @"version",
		@"version": version ?: [NSNull null],
	};
}

+ (NSDictionary *)timestampObjectWithNumber:(NSNumber *)seconds {
	return @{ @"_type": @"datetime",
		@"sec": seconds,
	};
}

+ (NSDictionary *)timestampObjectWithDate:(NSDate *)date {
	return [self timestampObjectWithNumber:@([date timeIntervalSince1970])];
}

- (void)addCustomData:(NSObject *)object withKey:(NSString *)key toCustomDataDictionary:(NSMutableDictionary *)customData {
	BOOL simpleType = ([object isKindOfClass:[NSString class]] ||
		[object isKindOfClass:[NSNumber class]] ||
		[object isKindOfClass:[NSNull class]]);

	BOOL complexType = NO;
	if ([object isKindOfClass:[NSDictionary class]]) {
		NSString *type = ((NSDictionary *)object)[@"_type"];
		if (type) {
			complexType = (type != nil);
		}
	}

	if (simpleType || complexType) {
		[customData setObject:object forKey:key];
	} else {
		ApptentiveLogError(@"Apptentive custom data must be of type NSString, NSNumber, or NSNull, or a 'complex type' NSDictionary created by one of the constructors in Apptentive.h");
	}
}

- (void)removeCustomPersonDataWithKey:(NSString *)key {
	[self.backend.session updatePerson:^(ApptentiveMutablePerson *person) {
		[person removeCustomValueWithKey:key];
	}];
}

- (void)removeCustomDeviceDataWithKey:(NSString *)key {
	[self.backend.session updateDevice:^(ApptentiveMutableDevice *device) {
		[device removeCustomValueWithKey:key];
	}];
}

- (void)openAppStore {
	if (!self.appID) {
		ApptentiveLogError(@"Cannot open App Store because `[Apptentive sharedConnection].appID` is not set to your app's iTunes App ID.");
		return;
	}

	[self.engagementBackend engageApptentiveAppEvent:@"open_app_store_manually"];

	ApptentiveInteraction *appStoreInteraction = [[ApptentiveInteraction alloc] init];
	appStoreInteraction.type = @"AppStoreRating";
	appStoreInteraction.priority = 1;
	appStoreInteraction.version = @"1.0.0";
	appStoreInteraction.identifier = @"OpenAppStore";
	appStoreInteraction.configuration = @{ @"store_id": self.appID,
		@"method": @"app_store" };

	[self.engagementBackend presentInteraction:appStoreInteraction fromViewController:nil];
}

- (NSDictionary *)integrationConfiguration {
	return self.backend.session.device.integrationConfiguration;
}

- (void)setPushNotificationIntegration:(ApptentivePushProvider)pushProvider withDeviceToken:(NSData *)deviceToken {
	[self removeAllPushIntegrations];

	NSString *integrationKey = [self integrationKeyForPushProvider:pushProvider];

	[self addIntegration:integrationKey withDeviceToken:deviceToken];
}

- (void)removeAllPushIntegrations {
	[self removeIntegration:[self integrationKeyForPushProvider:ApptentivePushProviderApptentive]];
	[self removeIntegration:[self integrationKeyForPushProvider:ApptentivePushProviderUrbanAirship]];
	[self removeIntegration:[self integrationKeyForPushProvider:ApptentivePushProviderAmazonSNS]];
	[self removeIntegration:[self integrationKeyForPushProvider:ApptentivePushProviderParse]];
}

- (NSString *)integrationKeyForPushProvider:(ApptentivePushProvider)pushProvider {
	switch (pushProvider) {
		case ApptentivePushProviderApptentive:
			return @"apptentive_push";
		case ApptentivePushProviderUrbanAirship:
			return @"urban_airship";
		case ApptentivePushProviderAmazonSNS:
			return @"aws_sns";
		case ApptentivePushProviderParse:
			return @"parse";
		default:
			return @"UNKNOWN_PUSH_PROVIDER";
	}
}

- (void)addIntegration:(NSString *)integration withConfiguration:(NSDictionary *)configuration {
	NSMutableDictionary *integrationConfiguration = [self.backend.session.device.integrationConfiguration mutableCopy];
	[integrationConfiguration setObject:configuration forKey:integration];

	[self.backend.session updateDevice:^(ApptentiveMutableDevice *device) {
		device.integrationConfiguration = integrationConfiguration;
	}];
}

- (void)addIntegration:(NSString *)integration withDeviceToken:(NSData *)deviceToken {
	const unsigned *tokenBytes = [deviceToken bytes];
	NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
								ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
								ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
								ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

	[self addIntegration:integration withConfiguration:@{ @"token": token }];
}

- (void)removeIntegration:(NSString *)integration {
	NSMutableDictionary *integrationConfiguration = [self.backend.session.device.integrationConfiguration mutableCopy];
	[integrationConfiguration removeObjectForKey:integration];

	[self.backend.session updateDevice:^(ApptentiveMutableDevice *device) {
		device.integrationConfiguration = integrationConfiguration;
	}];
}

- (BOOL)canShowInteractionForEvent:(NSString *)event {
	return [self.engagementBackend canShowInteractionForLocalEvent:event];
}

- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData fromViewController:(UIViewController *)viewController {
	return [self engage:event withCustomData:customData withExtendedData:nil fromViewController:viewController];
}

- (BOOL)engage:(NSString *)event withCustomData:(NSDictionary *)customData withExtendedData:(NSArray *)extendedData fromViewController:(UIViewController *)viewController {
	return [self.engagementBackend engageLocalEvent:event userInfo:nil customData:customData extendedData:extendedData fromViewController:viewController];
}

+ (NSDictionary *)extendedDataDate:(NSDate *)date {
	NSDictionary *time = @{ @"time": @{@"version": @1,
		@"timestamp": @([date timeIntervalSince1970])}
	};
	return time;
}

+ (NSDictionary *)extendedDataLocationForLatitude:(double)latitude longitude:(double)longitude {
	// Coordinates sent to server in order (longitude, latitude)
	NSDictionary *location = @{ @"location": @{@"version": @1,
		@"coordinates": @[@(longitude), @(latitude)]}
	};

	return location;
}


+ (NSDictionary *)extendedDataCommerceWithTransactionID:(NSString *)transactionID
											affiliation:(NSString *)affiliation
												revenue:(NSNumber *)revenue
											   shipping:(NSNumber *)shipping
													tax:(NSNumber *)tax
											   currency:(NSString *)currency
										  commerceItems:(NSArray *)commerceItems {
	NSMutableDictionary *commerce = [NSMutableDictionary dictionary];
	commerce[@"version"] = @1;

	if (transactionID) {
		commerce[@"id"] = transactionID;
	}

	if (affiliation) {
		commerce[@"affiliation"] = affiliation;
	}

	if (revenue != nil) {
		commerce[@"revenue"] = revenue;
	}

	if (shipping != nil) {
		commerce[@"shipping"] = shipping;
	}

	if (tax != nil) {
		commerce[@"tax"] = tax;
	}

	if (currency) {
		commerce[@"currency"] = currency;
	}

	if (commerceItems) {
		commerce[@"items"] = commerceItems;
	}

	return @{ @"commerce": commerce };
}

+ (NSDictionary *)extendedDataCommerceItemWithItemID:(NSString *)itemID
												name:(NSString *)name
											category:(NSString *)category
											   price:(NSNumber *)price
											quantity:(NSNumber *)quantity
											currency:(NSString *)currency {
	NSMutableDictionary *commerceItem = [NSMutableDictionary dictionary];
	commerceItem[@"version"] = @1;

	if (itemID) {
		commerceItem[@"id"] = itemID;
	}

	if (name) {
		commerceItem[@"name"] = name;
	}

	if (category) {
		commerceItem[@"category"] = category;
	}

	if (price != nil) {
		commerceItem[@"price"] = price;
	}

	if (quantity != nil) {
		commerceItem[@"quantity"] = quantity;
	}

	if (currency) {
		commerceItem[@"currency"] = currency;
	}

	return commerceItem;
}

- (BOOL)canShowMessageCenter {
	NSString *messageCenterCodePoint = [[ApptentiveInteraction apptentiveAppInteraction] codePointForEvent:ApptentiveEngagementMessageCenterEvent];
	return [self.engagementBackend canShowInteractionForCodePoint:messageCenterCodePoint];
}

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController {
	return [self.backend presentMessageCenterFromViewController:viewController];
}

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData {
	NSMutableDictionary *allowedCustomMessageData = [NSMutableDictionary dictionary];

	for (NSString *key in [customData allKeys]) {
		[self addCustomData:[customData objectForKey:key] withKey:key toCustomDataDictionary:allowedCustomMessageData];
	}

	return [self.backend presentMessageCenterFromViewController:viewController withCustomData:allowedCustomMessageData];
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController {
	return [self didReceiveRemoteNotification:userInfo fromViewController:viewController fetchCompletionHandler:^void(UIBackgroundFetchResult result){
	}];
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	NSDictionary *apptentivePayload = [userInfo objectForKey:@"apptentive"];
	if (apptentivePayload) {
		BOOL shouldCallCompletionHandler = YES;

		switch ([UIApplication sharedApplication].applicationState) {
			case UIApplicationStateBackground: {
				NSNumber *contentAvailable = userInfo[@"aps"][@"content-available"];
				if (contentAvailable.boolValue) {
					shouldCallCompletionHandler = NO;
					[self.backend fetchMessagesInBackground:completionHandler];
				}
				break;
			}
			case UIApplicationStateInactive:
				// Present Apptentive UI later, when Application State is Active
				self.pushUserInfo = userInfo;
				self.pushViewController = viewController;
				break;
			case UIApplicationStateActive:
				self.pushUserInfo = nil;
				self.pushViewController = nil;

				NSString *action = [apptentivePayload objectForKey:@"action"];
				if ([action isEqualToString:@"pmc"]) {
					[self presentMessageCenterFromViewController:viewController];
				} else {
					[self.backend checkForMessages];
				}
				break;
		}

		if (shouldCallCompletionHandler && completionHandler) {
			completionHandler(UIBackgroundFetchResultNoData);
		}
	}

	return (apptentivePayload != nil);
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[self.backend dismissMessageCenterAnimated:animated completion:completion];
}

- (NSUInteger)unreadMessageCount {
	return [self.backend unreadMessageCount];
}

- (UIView *)unreadMessageCountAccessoryView:(BOOL)apptentiveHeart {
	if (apptentiveHeart) {
		return [ApptentiveUnreadMessagesBadgeView unreadMessageCountViewBadgeWithApptentiveHeart];
	} else {
		return [ApptentiveUnreadMessagesBadgeView unreadMessageCountViewBadge];
	}
}

+ (NSBundle *)resourceBundle {
	NSBundle *bundleForClass = [NSBundle bundleForClass:[self class]];
	NSString *resourceBundlePath = [bundleForClass pathForResource:@"ApptentiveResources" ofType:@"bundle"];

	// Resources may sit alongside this class in a framework or may be nested in resource bundle.
	return resourceBundlePath ? [NSBundle bundleWithPath:resourceBundlePath] : bundleForClass;
}

#pragma mark - Message notification banner

- (void)showNotificationBannerForMessage:(ApptentiveMessage *)message {
	if (self.backend.configuration.messageCenter.notificationPopupEnabled && [message isKindOfClass:[ApptentiveMessage class]]) {
		// TODO: Display something if body is empty
		ApptentiveMessage *textMessage = (ApptentiveMessage *)message;
		NSURL *profilePhotoURL = textMessage.sender.profilePhotoURL ? [NSURL URLWithString:textMessage.sender.profilePhotoURL] : nil;

		ApptentiveBannerViewController *banner = [ApptentiveBannerViewController bannerWithImageURL:profilePhotoURL title:textMessage.sender.name message:textMessage.body];

		banner.delegate = self;

		[banner show];
	}
}

- (void)userDidTapBanner:(ApptentiveBannerViewController *)banner {
	[self presentMessageCenterFromViewController:[self viewControllerForInteractions]];
}

- (UIViewController *)viewControllerForInteractions {
	if (self.delegate && [self.delegate respondsToSelector:@selector(viewControllerForInteractionsWithConnection:)]) {
		return [self.delegate viewControllerForInteractionsWithConnection:self];
	} else {
		return [ApptentiveUtilities topViewController];
	}
}

+ (UIStoryboard *)storyboard {
	return [UIStoryboard storyboardWithName:@"Apptentive" bundle:[Apptentive resourceBundle]];
}

#if APPTENTIVE_DEBUG
- (void)checkSDKConfiguration {
	BOOL hasPhotoLibraryUsageDescription = [[NSBundle mainBundle].infoDictionary objectForKey:@"NSPhotoLibraryUsageDescription"] != nil;

	if (!hasPhotoLibraryUsageDescription) {
		ApptentiveLogError(@"No Photo Library Usage Description Set. This will cause your app to be rejected during app review.");
	}

	BOOL hasAppIDSet = self.appID != nil;

	if (!hasAppIDSet) {
		ApptentiveLogError(@"No App ID set. This may keep the ratings prompt from directing users to your app in the App Store.");
	}

	BOOL hasResources = [Apptentive resourceBundle] != nil;

	if (!hasResources) {
		ApptentiveLogError(@"Missing resources.");
#if APPTENTIVE_COCOAPODS
		ApptentiveLogError(@"Try cleaning derived data and/or `pod deintegrate && pod install`.");
#else
		ApptentiveLogError(@"Please make sure the resources are added to the appropriate target(s).");
#endif
	}
}
#endif

@end


@implementation ApptentiveNavigationController
// Container to allow customization of Apptentive UI using UIAppearance

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		if (!([UINavigationBar appearance].barTintColor || [UINavigationBar appearanceWhenContainedIn:[ApptentiveNavigationController class], nil].barTintColor)) {
			[UINavigationBar appearanceWhenContainedIn:[ApptentiveNavigationController class], nil].barTintColor = [UIColor whiteColor];
		}
	}
	return self;
}

- (void)pushAboutApptentiveViewController {
	UIViewController *aboutViewController = [[Apptentive storyboard] instantiateViewControllerWithIdentifier:@"About"];
	[self pushViewController:aboutViewController animated:YES];
}

@end

NSString *ApptentiveLocalizedString(NSString *key, NSString *comment) {
	static NSBundle *bundle = nil;
	if (!bundle) {
		bundle = [Apptentive resourceBundle];
	}
	NSString *result = [bundle localizedStringForKey:key value:key table:nil];
	return result;
}
