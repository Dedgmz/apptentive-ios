//
//  ATEngagementTests.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 9/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementTests.h"
#import "ATInteraction.h"
#import "ATInteractionUsageData.h"
#import "ATEngagementBackend.h"

@implementation ATEngagementTests

/*
 days_since_install - The total number of days since the app was first launched (irrespective of app version).  (integer)
 days_since_upgrade - The number of days since the current version of the app was first launched.  (integer)
 application_version - The currently running application version (string).
 code_point.code_point_name.invokes.total - The total number of times code_point_name has been invoked across all versions of the app (regardless if an Interaction was shown at that point)  (integer)
 code_point.code_point_name.invokes.version - The number of times code_point_name has been invoked in the current version of the app (regardless if an Interaction was shown at that point) (integer)
 interactions.interaction_instance_id.invokes.total - The number of times the Interaction Instance with id interaction_instance_id has been invoked (irrespective of app version) (integer)
 interactions.interaction_instance_id.invokes.version  - The number of times the Interaction Instance with id interaction_instance_id has been invoked within the current version of the app (integer)
*/

- (void)testInteractionCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData;
	
	interaction.criteria = @{@"days_since_install": @{@"$gt": @5, @"$lt": @7}};
	usageData = [ATInteractionUsageData usageDataForInteraction:interaction
											   daysSinceInstall:@6
											   daysSinceUpgrade:@6
											 applicationVersion:@"1.8.9"
											   applicationBuild:@"39"
										  codePointInvokesTotal:@{}
										codePointInvokesVersion:@{}
										codePointInvokesTimeAgo:@{}
										interactionInvokesTotal:@{}
									  interactionInvokesVersion:@{}
									  interactionInvokesTimeAgo:@{}];
	
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
}

- (void)testUnknownKeyInCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"days_since_install": @6, @"days_since_upgrade": @6};
	ATInteractionUsageData *usageData = [ATInteractionUsageData usageDataForInteraction:interaction
																	   daysSinceInstall:@6
																	   daysSinceUpgrade:@6
																	 applicationVersion:@"1.8.9"
																	   applicationBuild:@"39"
																  codePointInvokesTotal:@{}
																codePointInvokesVersion:@{}
																codePointInvokesTimeAgo:@{}
																interactionInvokesTotal:@{}
															  interactionInvokesVersion:@{}
															  interactionInvokesTimeAgo:@{}];
		
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"All keys are known, thus the criteria is met.");
	
	interaction.criteria = @{@"days_since_install": @6, @"unknown_key": @"criteria_should_not_be_met"};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
}

- (void)testEmptyCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = nil;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Dictionary with nil criteria should evaluate to False.");

	interaction.criteria = @{};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Empty criteria dictionary with no keys should evaluate to True.");
	
	interaction.criteria = @{@"": @6};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Criteria with a key that is an empty string should fail (if usage data does not match).");
}

- (void)testInteractionCriteriaDaysSnceInstall {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"days_since_install": @6};
	usageData.daysSinceInstall = @6;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @5;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @7;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	
	interaction.criteria = @{@"days_since_install": @{@"$gt": @5, @"$lt": @7}};
	usageData.daysSinceInstall = @6;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @5;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @7;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	
	interaction.criteria = @{@"days_since_install": @{@"$lte": @5, @"$gt": @3}};
	usageData.daysSinceInstall = @3;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @4;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @5;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @6;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
}

- (void)testInteractionCriteriaVersion {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"application_version": @"1.2.8"};
	usageData.applicationVersion = @"1.2.8";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"v1.2.8";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
	
	interaction.criteria = @{@"application_version": @"v3.0"};
	usageData.applicationVersion = @"v3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
}

- (void)testInteractionCriteriaBuild {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"application_build": @"39"};
	usageData.applicationBuild = @"39";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Build number");
	
	usageData.applicationBuild = @"v39";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");
	
	interaction.criteria = @{@"application_build": @"v3.0"};
	usageData.applicationBuild = @"v3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Build number");
	
	usageData.applicationBuild = @"3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");
}

- (void)testCodePointInvokesVersion {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"code_point/app.launch/invokes/version": @1};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"This version has been invoked 1 time.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @0};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @2};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");

	
	interaction.criteria = @{@"code_point/big.win/invokes/version": @7};
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @7};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @1};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @19};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");

	interaction.criteria = @{@"code_point/big.win/invokes/version": @{@"$gte": @5, @"$lte": @5}};
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @5};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @3};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @19};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
}

- (void)testUpgradeMessageCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"code_point/app.launch/invokes/version": @1,
							 @"application_version": @"1.3.0",
							 @"application_build": @"39"};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message without build number.");
	usageData.applicationBuild = @"39";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @2};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.1";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	interaction.criteria = @{@"application_version": @"1.3.0",
							 @"code_point/app.launch/invokes/version": @{@"$gte": @1}};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @2};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @0};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	
	interaction.criteria = @{@"application_version": @"1.3.0",
							 @"code_point/app.launch/invokes/version": @{@"$lte": @4}};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @4};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @5};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
}

- (void)testComplexCriteria {
	NSString *jsonString = @"{\"interactions\":{\"app.launch\":[{\"id\":\"526fe2836dd8bf546a00000c\",\"priority\":2,\"criteria\":{\"days_since_upgrade\":{\"$lt\":3},\"code_point/app.launch/invokes/total\":2,\"interactions/526fe2836dd8bf546a00000b/invokes/version\":0},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}],\"big.win\":[{\"id\":\"526fe2836dd8bf546a00000d\",\"priority\":1,\"criteria\":{},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}],\"or_clause\":[{\"id\":\"526fe2836dd8bf546a00000e\",\"priority\":1,\"criteria\":{\"$or\":[{\"days_since_upgrade\":{\"$lt\":3}},{\"code_point/app.launch/invokes/total\":2},{\"interactions/526fe2836dd8bf546a00000b/invokes/version\":0}]},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}],\"complext_criteria\":[{\"id\":\"526fe2836dd8bf546a00000f\",\"priority\":1,\"criteria\":{\"$or\":[{\"days_since_upgrade\":{\"$lt\":3}},{\"$and\":[{\"code_point/app.launch/invokes/total\":2},{\"interactions/526fe2836dd8bf546a00000b/invokes/version\":0},{\"$or\":[{\"code_point/small.win/invokes/total\":2},{\"code_point/big.win/invokes/total\":2}]}]}]},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}]}}";

	/*
	criteria = {
		"$or" = ({
			"days_since_upgrade" = {
				"$lt" = 3;
			};
		},
		{
			"$and" = ({
				"code_point/app.launch/invokes/total" = 2;
			},
			{
				"interactions/526fe2836dd8bf546a00000b/invokes/version" = 0;
			},
			{
				"$or" = ({
					"code_point/small.win/invokes/total" = 2;
				},
				{
					"code_point/big.win/invokes/total" = 2;
				});
			});
		});
	};
	*/
	

	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *interactions = [NSJSONSerialization JSONObjectWithData:jsonData
																 options:NSJSONReadingAllowFragments
																   error:nil];
	
	NSDictionary *codePoints = [interactions objectForKey:@"interactions"];
	NSDictionary *complexInteractionDictionary = [[codePoints objectForKey:@"complext_criteria"] objectAtIndex:0];
	
	ATInteraction *complexInteraction = [ATInteraction interactionWithJSONDictionary:complexInteractionDictionary];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	usageData.daysSinceUpgrade = @2;
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"2 satisfies the inital OR clause; passes regardless of the next condition.");
	usageData.daysSinceUpgrade = @0;
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"0 satisfies the inital OR clause; passes regardless of the next condition.");
	
	usageData.daysSinceUpgrade = @3;
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @8};
	XCTAssertFalse([complexInteraction criteriaAreMetForUsageData:usageData], @"3 fails the initial OR clause. 8 fails the other clause.");

	usageData.daysSinceUpgrade = @3;
	usageData.interactionInvokesVersion = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @0};
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @0,
										@"code_point/big.win/invokes/total": @2};
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"complex");
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @2,
										@"code_point/big.win/invokes/total": @19};
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"complex");
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @19,
										@"code_point/big.win/invokes/total": @19};
	XCTAssertFalse([complexInteraction criteriaAreMetForUsageData:usageData], @"Neither of the last two ORed code_point totals are right.");
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @2,
										@"code_point/big.win/invokes/total": @1};
	usageData.interactionInvokesVersion = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @8};
	XCTAssertFalse([complexInteraction criteriaAreMetForUsageData:usageData], @"The middle case is incorrect.");
}

- (void)testTimeAgoCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @100,
							 @"interactions/big.win/invokes/time_ago": @1000};
	
	usageData.codePointInvokesTimeAgo = @{@"code_point/app.launch/invokes/time_ago": @100};
	usageData.interactionInvokesTimeAgo = @{@"interactions/big.win/invokes/time_ago": @1000};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500},
							 @"interactions/big.win/invokes/time_ago": @{@"$lte": @1000}};
	usageData.codePointInvokesTimeAgo = @{@"code_point/app.launch/invokes/time_ago": @800};
	usageData.interactionInvokesTimeAgo = @{@"interactions/big.win/invokes/time_ago": @100};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testTimeAgoCodePointCriteriaViaDatesInNSUserDefaults {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$lte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": [NSDate distantPast]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo: distantPast -> now time interval > 500");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": [NSDate distantPast]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": [NSDate dateWithTimeIntervalSinceNow:-600]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-400]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-501]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testTimeAgoInteractionCriteriaViaDatesInNSUserDefaults {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$lte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": [NSDate distantPast]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo: distantPast -> now time interval > 500");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": [NSDate distantPast]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": [NSDate dateWithTimeIntervalSinceNow:-600]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-400]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-501]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

@end
