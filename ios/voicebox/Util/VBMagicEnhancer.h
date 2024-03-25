//
//  VBMagicEnhancer.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import <Foundation/Foundation.h>

#import "OpenAiApiRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface VBMagicEnhancer : NSObject

- (void)enhance:(NSString*)text onComplete:(void (^)(NSArray<ResponseOption*>*, NSError*))complete;

- (void)generateSubjectForEmail:(NSString*)emailText onComplete:(void (^)(NSString* _Nullable, NSError* _Nullable))complete;

@end

NS_ASSUME_NONNULL_END
