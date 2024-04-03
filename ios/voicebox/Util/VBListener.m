//
//  VBListener.m
//  voicebox
//
//  Created by Steve Cosman on 2024-04-03.
//

#import "VBListener.h"

#import "voicebox-Swift.h"

@interface VBListener ()

@property (nonatomic, strong) NSHashTable* delegates;
@property (nonatomic, strong) VBSwiftListener* wk;
@end

@implementation VBListener

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.wk = [[VBSwiftListener alloc] init];
    }
    return self;
}

static VBListener* sharedInstance = nil;

+ (VBListener*)sharedInstance
{
    @synchronized(VBListener.class) {
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }

        return sharedInstance;
    }
}

+ (void)releaseSharedInstance
{
    @synchronized(VBListener.class) {
        sharedInstance = nil;
    }
}

- (void)registerDelegate:(id<VBAudioListenerDelegate>)delegate
{
    [_delegates addObject:delegate];
}

- (void)deregisterDelegate:(id<VBAudioListenerDelegate>)delegate
{
    [_delegates removeObject:delegate];
}

- (void)startListening
{
    [self.wk startWithCompletionHandler:^(NSError* _Nullable err) {
        if (err) {
            NSLog(@"Error %@", err);
        }
    }];
}

- (void)stateUpdate:(bool)running segments:(nullable NSArray<NSString*>*)segments
{
}

- (void)stopCapturing
{
}

@end
