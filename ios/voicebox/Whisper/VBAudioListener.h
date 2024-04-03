//
//  VBAudioListener.h
//  voicebox
//
//  Created by Steve Cosman on 2023-03-01.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VBAudioListenerDelegate <NSObject>
@required
-(void) stateUpdate:(bool)running segments:(nullable NSArray<NSString*>*)segments;
@end

@protocol VBListenerProto <NSObject>

@required
// Shared instance, which can be cleared out of memory under memory pressure, or app backgrounding
+(id<VBListenerProto>) sharedInstance;
+(void) releaseSharedInstance;

-(void) registerDelegate:(id <VBAudioListenerDelegate>)delegate;
-(void) deregisterDelegate:(id <VBAudioListenerDelegate>)delegate;
-(void) startListening;
-(void)stopCapturing;

@end

@interface VBAudioListener : NSObject <VBListenerProto>


@end

NS_ASSUME_NONNULL_END
