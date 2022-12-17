//
//  OpenApiRequest.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenApiRequest : NSObject

- (instancetype)initWithPrompt:(NSString*)prompt;
- (NSArray<NSString*>*)sendSynchronousRequest:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
