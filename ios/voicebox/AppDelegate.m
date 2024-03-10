//
//  AppDelegate.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "AppDelegate.h"

@import CriticalMoments;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    NSString* apiKey = @"CM1-YjpuZXQuc2Nvc21hbi52b2ljZWJveA==-MEUCIEZKKaw7ERRXxoiElENVirF/p0eP4YA58h42eePVYmmmAiEA+HRo2cGPLgEPrBBV3OEPZV9Z+Au95z9C/AUe/aLiEVw=";
    [CriticalMoments.sharedInstance setApiKey:apiKey error:nil];
    NSURL* localConfigUrl = [[NSBundle mainBundle] URLForResource:@"cmConfig" withExtension:@"json"];
    [CriticalMoments.sharedInstance setDevelopmentConfigUrl:localConfigUrl.absoluteString];
    [CriticalMoments.sharedInstance setReleaseConfigUrl:@"https://storage.googleapis.com/critical-moments-test-cases/voiceBox_criticalmoments.cmconfig"];

    [CriticalMoments.sharedInstance start];

    // Override point for customization after application launch.
    return YES;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration*)application:(UIApplication*)application configurationForConnectingSceneSession:(UISceneSession*)connectingSceneSession options:(UISceneConnectionOptions*)options
{
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication*)application didDiscardSceneSessions:(NSSet<UISceneSession*>*)sceneSessions
{
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

@end
