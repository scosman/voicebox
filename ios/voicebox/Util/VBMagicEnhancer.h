//
//  VBMagicEnhancer.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VBMagicEnhancerOption : NSObject

@property (nonatomic, strong) NSString* buttonLabel;
@property (nonatomic, strong) NSString* replacementText;

@end

@interface VBMagicEnhancer : NSObject

-(void) enhance:(NSString*)text onComplete:(void (^)(NSArray<VBMagicEnhancerOption*>*, NSError*))complete;

@end

NS_ASSUME_NONNULL_END
