//
//  VBStringUtils.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-10.
//

#import "VBStringUtils.h"

#define SENTENCE_TERMINATORS_STRING @".?!;"

@implementation VBStringUtils

+ (BOOL) endsInCompleteSentence:(NSString*)text {
    NSString* trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* lastNonWhitespaceChar = [VBStringUtils lastCharaterInString:trimmedText];
    return [SENTENCE_TERMINATORS_STRING containsString:lastNonWhitespaceChar];
}

+(NSString*) lastCharaterInString:(NSString*)string {
    if (string.length == 0) {
        return @"";
    }
    
    return [string substringFromIndex:(string.length-1)];;
}

+(NSString*) firstCharaterInString:(NSString*)string {
    if (string.length == 0) {
        return @"";
    }
    
    return [string substringToIndex:1];;
}

+(NSString*) truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:(NSString*)firstString withSecondString:(NSString*)secondString
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

+(BOOL) stringIsAllWhitespace:(NSString*)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
}

+(NSString*) lastPartialSentenceFromString:(NSString*)text {
    NSRange lastSentenceEndRange = [text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:SENTENCE_TERMINATORS_STRING] options:NSBackwardsSearch];
    
    if (lastSentenceEndRange.location == NSNotFound) {
        return nil;
    }
    
    NSString* stingAfterLastSentence = [text substringFromIndex:lastSentenceEndRange.location+1];
    NSString* trimmedStingAfterLastSentence = [stingAfterLastSentence stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (trimmedStingAfterLastSentence.length == 0) {
        return nil;
    }
    
    // trim the whitespace before this sentence fragment starts, and keep it when we re-assemble.
    // leading white space could have been intentional (paragraph breaks).
    // leave the whitespace after. The ML is replacing this fragment, including trailing whitespace.
    NSRange firstNonWhitespaceRange = [text rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:SENTENCE_TERMINATORS_STRING] invertedSet]];
    return [stingAfterLastSentence substringFromIndex:firstNonWhitespaceRange.location];
}

@end
