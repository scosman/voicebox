//
//  VBStringUtils.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-10.
//

#import "VBStringUtils.h"

@import UIKit;

#define SENTENCE_TERMINATORS_STRING @".?!;"

@implementation VBStringUtils

+ (BOOL)endsInCompleteSentence:(NSString*)text
{
    NSString* trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* lastNonWhitespaceChar = [VBStringUtils lastCharaterInString:trimmedText];
    return [SENTENCE_TERMINATORS_STRING containsString:lastNonWhitespaceChar];
}

+ (NSString*)lastCharaterInString:(NSString*)string
{
    if (string.length == 0) {
        return @"";
    }

    return [string substringFromIndex:(string.length - 1)];
    ;
}

+ (NSString*)firstCharaterInString:(NSString*)string
{
    if (string.length == 0) {
        return @"";
    }

    return [string substringToIndex:1];
    ;
}

+ (NSString*)truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:(NSString*)firstString withSecondString:(NSString*)secondString
{
    NSString* secondStringWithTrailingSpace;
    NSString* endOfSecondString = [VBStringUtils lastCharaterInString:secondString];
    if (endOfSecondString.length > 0 && [VBStringUtils stringIsAllWhitespace:endOfSecondString]) {
        secondStringWithTrailingSpace = secondString;
    } else {
        secondStringWithTrailingSpace = [secondString stringByAppendingString:@" "];
    }

    NSString* endOfFirstString = [VBStringUtils lastCharaterInString:firstString];
    NSString* startOfSecondString = [VBStringUtils firstCharaterInString:secondString];

    if ([VBStringUtils stringIsAllWhitespace:endOfFirstString] ||
        [VBStringUtils stringIsAllWhitespace:startOfSecondString]) {
        return [firstString stringByAppendingString:secondStringWithTrailingSpace];
    }

    return [NSString stringWithFormat:@"%@ %@", firstString, secondStringWithTrailingSpace];
}

+ (BOOL)stringIsAllWhitespace:(NSString*)text
{
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
}

+ (NSString*)trimLeadingWhitespaceAndNewlines:(NSString*)text
{
    // Why use this in lastPartialSentenceFromString?
    // Leading white space could have been intentional (eg paragraph breaks).
    // Leave the whitespace after in string. The ML is replacing this fragment, including trailing whitespace.
    NSRange firstNonWhitespaceRange = [text rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]];
    if (firstNonWhitespaceRange.location == NSNotFound || firstNonWhitespaceRange.location >= text.length) {
        return @"";
    }
    return [text substringFromIndex:firstNonWhitespaceRange.location];
}

+ (NSString*)lastPartialSentenceFromString:(NSString*)text
{
    if (text.length == 0) {
        return nil;
    }

    NSRange lastSentenceEndRange = [text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:SENTENCE_TERMINATORS_STRING] options:NSBackwardsSearch];

    if (lastSentenceEndRange.location == NSNotFound) {
        return [VBStringUtils trimLeadingWhitespaceAndNewlines:text];
    }
    if (lastSentenceEndRange.location >= text.length) {
        // period is last charater
        return nil;
    }

    NSString* stingAfterLastSentence = [text substringFromIndex:lastSentenceEndRange.location + 1];
    NSString* trimmedStingAfterLastSentence = [stingAfterLastSentence stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (trimmedStingAfterLastSentence.length == 0) {
        return nil;
    }

    return [VBStringUtils trimLeadingWhitespaceAndNewlines:stingAfterLastSentence];
}

+ (NSString*)originalTextToKeepWhenStrippingLastPartialSentence:(NSString*)text
{
    NSString* lastSentenceToReplace = [VBStringUtils lastPartialSentenceFromString:text];
    NSUInteger originalTextToKeepLength = text.length - lastSentenceToReplace.length;
    if (originalTextToKeepLength > text.length) {
        // shouldn't hit
        NSAssert(NO, @"Unexpected: last sentence to replace longer than original text.");
        return @"";
    }
    return [text substringToIndex:originalTextToKeepLength];
}

+ (UIFont*)logoFontOfWeight:(UIFontWeight)weight withSize:(CGFloat)size
{
    // weird trick needed to get SF Pro Rounded
    UIFont* systemFont = [UIFont systemFontOfSize:size weight:weight];
    UIFontDescriptor* sfRoundedFontDescriptor = [systemFont.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    UIFont* roundedSystemFont = [UIFont fontWithDescriptor:sfRoundedFontDescriptor size:size];
    return roundedSystemFont ? roundedSystemFont : systemFont;
}

@end
