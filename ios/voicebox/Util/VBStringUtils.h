//
//  VBStringUtils.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-10.
//

#import <Foundation/Foundation.h>

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface VBStringUtils : NSObject

+ (BOOL)endsInCompleteSentence:(NSString*)text;
+ (NSString*)truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:(NSString*)firstString withSecondString:(NSString*)secondString;
+ (NSString*)lastPartialSentenceFromString:(NSString*)text;
+ (NSString*)originalTextToKeepWhenStrippingLastPartialSentence:(NSString*)text;
+ (UIFont*)logoFontOfWeight:(UIFontWeight)weight withSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
