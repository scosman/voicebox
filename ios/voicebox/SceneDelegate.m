//
//  SceneDelegate.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "SceneDelegate.h"
#import "MainViewController.h"
#import "VBAudioListener.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate

- (void)scene:(UIScene*)scene willConnectToSession:(UISceneSession*)session options:(UISceneConnectionOptions*)connectionOptions
{

    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIWindowScene* windowScene = (UIWindowScene*)scene;
    UIWindow* window = [[UIWindow alloc] initWithWindowScene:windowScene];
    window.rootViewController = [[MainViewController alloc] init];
    self.window = window;
    [window makeKeyAndVisible];

    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
}

- (void)sceneDidDisconnect:(UIScene*)scene
{
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}

- (void)sceneDidBecomeActive:(UIScene*)scene
{
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}

- (void)sceneWillResignActive:(UIScene*)scene
{
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}

- (void)sceneWillEnterForeground:(UIScene*)scene
{
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.

    // only for primary window scene
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        // Preload whisper model in background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [VBAudioListener sharedInstance];
        });
    };
}

- (void)sceneDidEnterBackground:(UIScene*)scene
{
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.

    // only for primary window scene
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        // Release whisper (500MB+ of memory)
        [VBAudioListener releaseSharedInstance];
    };
}

@end
