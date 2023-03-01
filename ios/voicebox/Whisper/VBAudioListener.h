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

@interface VBAudioListener : NSObject

+(VBAudioListener*) sharedInstance;

-(void) registerDelegate:(id <VBAudioListenerDelegate>)delegate;
-(void) deregisterDelegate:(id <VBAudioListenerDelegate>)delegate;
-(void) startListening;
-(void)stopCapturing;

@end

NS_ASSUME_NONNULL_END
