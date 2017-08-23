//
//  ApptentiveUtilities.h
//  Apptentive
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kApptentiveHostName @"apptentive.com"


@interface ApptentiveUtilities : NSObject

+ (BOOL)fileExistsAtPath:(NSString *)path;
+ (BOOL)deleteFileAtPath:(NSString *)path;
+ (BOOL)deleteFileAtPath:(NSString *)path error:(NSError **)error;
+ (BOOL)deleteDirectoryAtPath:(NSString *)path error:(NSError **)error;

+ (NSString *)applicationSupportPath;
+ (NSBundle *)resourceBundle;
+ (UIStoryboard *)storyboard;
+ (UIImage *)imageNamed:(NSString *)name;
+ (NSURL *)apptentiveHomepageURL;
+ (NSString *)appName;

+ (UIViewController *)rootViewControllerForCurrentWindow;
+ (UIViewController *)topViewController;
+ (UIImage *)appIcon;

+ (NSString *)stringByEscapingForPredicate:(NSString *)string;
+ (NSString *)randomStringOfLength:(NSUInteger)length;

+ (NSString *)stringRepresentationOfDate:(NSDate *)date;

+ (NSComparisonResult)compareVersionString:(NSString *)a toVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isGreaterThanVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isLessThanVersionString:(NSString *)b;
+ (BOOL)versionString:(NSString *)a isEqualToVersionString:(NSString *)b;

+ (NSDictionary *)diffDictionary:(NSDictionary *) new againstDictionary:(NSDictionary *)old;

+ (BOOL)emailAddressIsValid:(NSString *)emailAddress;

+ (NSData *)secureRandomDataOfLength:(NSUInteger)length;

+ (NSString *)stringByPaddingBase64:(NSString *)base64String;
+ (NSString *)formatAsTableRows:(NSArray<NSArray *> *)rows;

@end