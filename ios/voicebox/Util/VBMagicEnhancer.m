//
//  VBMagicEnhancer.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBMagicEnhancer.h"

#import "OpenAiApiRequest.h"
#import "VBStringUtils.h"

typedef NS_ENUM(NSUInteger, MagicEnhancerMode) {
    kModeTextExpansion,
    kModeNextSentence
};

#define PROMPT_QUOTE_PLACEHOLDER @"INSERT_QUOTE_PLACEHOLDER"
#define PROMPT_PRIOR_CONTENT_PLACEHOLDER @"PRIOR_CONTENT_PLACEHOLDER"

@implementation VBMagicEnhancerOption
@end

@implementation VBMagicEnhancer

- (void)enhance:(NSString*)text onComplete:(void (^)(NSArray<VBMagicEnhancerOption*>*, NSError*))complete
{
    // default to text expansion.
    MagicEnhancerMode mode = kModeTextExpansion;
    // if last charater is a period, do the next sentence completion
    if ([VBStringUtils endsInCompleteSentence:text]) {
        mode = kModeNextSentence;
    }

    OpenAiApiRequest* request = [self requestForText:text withMode:mode];
    if (!request) {
        complete(nil, [NSError errorWithDomain:@"net.scosman.voicebox.custom" code:89939 userInfo:@{ NSLocalizedDescriptionKey : @"Issue generating prompt/request." }]);
        return;
        ;
    }

    [self requestAndBuildOptions:request withOriginalText:text withMode:mode onComplete:complete];
}

- (void)requestAndBuildOptions:(OpenAiApiRequest*)request withOriginalText:(NSString*)originalText withMode:(MagicEnhancerMode)mode onComplete:(void (^)(NSArray<VBMagicEnhancerOption*>*, NSError*))complete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError* err;
        NSMutableArray<VBMagicEnhancerOption*>* options = [self requestAndBuildOptionsSyncronous:request withOriginalText:(NSString*)originalText withMode:mode withError:&err];

        if (err) {
            complete(nil, err);
        } else {
            complete(options, nil);
        }
    });
}

- (NSMutableArray<VBMagicEnhancerOption*>*)requestAndBuildOptionsSyncronous:(OpenAiApiRequest*)apiRequest withOriginalText:(NSString*)originalText withMode:(MagicEnhancerMode)mode withError:(NSError**)error
{
    NSArray<NSString*>* stringOptions = [apiRequest sendSynchronousRequest:error];
    if (*error) {
        return nil;
    }

    NSMutableArray<VBMagicEnhancerOption*>* options = [[NSMutableArray alloc] initWithCapacity:stringOptions.count];
    for (NSString* stringOption in stringOptions) {
        VBMagicEnhancerOption* option = [self optionForText:originalText withSelectedOption:stringOption withMode:mode];
        [options addObject:option];
    }
    return options;
}

- (NSString*)escapeDoubleQuotes:(NSString*)text
{
    // TODO -- better escaping, or use edit API that separates input and instructions
    return [text stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
    ;
}

- (NSString*)originalTextToKeepWhenStrippingLastPartialSentence:(NSString*)text
{
    NSString* lastSentenceToReplace = [VBStringUtils lastPartialSentenceFromString:text];
    NSUInteger originalTextToKeepLength = text.length - lastSentenceToReplace.length;
    if (originalTextToKeepLength > text.length) {
        // shouldn't hit
        NSAssert(NO, @"Unexpected: last sentence to replace longer than original text.");
        return @"";
    }
    return [text substringToIndex:originalTextToKeepLength];
    ;
}

- (OpenAiApiRequest*)requestForText:(NSString*)originalText withMode:(MagicEnhancerMode)mode
{
    switch (mode) {
    case kModeTextExpansion: {
        return [self gpt3TextExpansionRequestForText:originalText];
        // return [self chatGptTextExpansionRequestForText:originalText];
    }
    case kModeNextSentence: {
        return [self gpt3NextSentenceRequestForText:originalText];
    }
    }
}

- (OpenAiApiRequest*)chatGptTextExpansionRequestForText:(NSString*)originalText
{
    // TODO P0 -- we're only passing last sentence to ML. It loses all context from prior sentences.
    NSString* lastSentence = [VBStringUtils lastPartialSentenceFromString:originalText];
    if (!lastSentence) {
        return nil;
    }

    // TODO P0 -- no prior text integration with ChatGPT yet

    ChatGptRequest* request = [[ChatGptRequest alloc] init];
    request.systemDirective = [self chatGptTextExpansionSystemDirective];

    ChatGptMessage* userMessage = [[ChatGptMessage alloc] init];
    userMessage.roll = kChatGptRollUser;
    userMessage.content = [NSString stringWithFormat:@"The quote to make suggestions for is as follows:\n\n%@", lastSentence];
    request.messages = @[ userMessage ];

    return [[OpenAiApiRequest alloc] initChatGtpWithRequest:request];
}

// Unused, but keeping
- (OpenAiApiRequest*)gpt3TextExpansionRequestForText:(NSString*)originalText
{
    NSString* promptTemplate = [self gpt3TextExpansionPromptTemplate];
    NSString* lastSentence = [VBStringUtils lastPartialSentenceFromString:originalText];
    if (!lastSentence) {
        return nil;
    }

    NSString* originalTextToKeep = [self originalTextToKeepWhenStrippingLastPartialSentence:originalText];
    NSString* trimmedOriginalTextToKeep = [originalTextToKeep stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* promptTemplateWithPriorContextFilled;
    if (trimmedOriginalTextToKeep.length > 0) {
        // TODO trim this
        NSString* escapedPriorContent = [self escapeDoubleQuotes:trimmedOriginalTextToKeep];
        NSString* priorContentSection = [NSString stringWithFormat:@"The speaker had just said: \"%@\"", escapedPriorContent];
        promptTemplateWithPriorContextFilled = [promptTemplate stringByReplacingOccurrencesOfString:PROMPT_PRIOR_CONTENT_PLACEHOLDER withString:priorContentSection];
    } else {
        promptTemplateWithPriorContextFilled = [promptTemplate stringByReplacingOccurrencesOfString:PROMPT_PRIOR_CONTENT_PLACEHOLDER withString:@""];
    }

    NSString* prompt = [promptTemplateWithPriorContextFilled stringByReplacingOccurrencesOfString:PROMPT_QUOTE_PLACEHOLDER withString:[self escapeDoubleQuotes:lastSentence]];

    return [[OpenAiApiRequest alloc] initGtp3WithPrompt:prompt];
}

- (OpenAiApiRequest*)gpt3NextSentenceRequestForText:(NSString*)originalText
{
    if (originalText.length <= 0) {
        return nil;
    }
    NSString* promptTemplate = [self gpt3NextSentancePromptTemplate];
    NSString* prompt = [promptTemplate stringByReplacingOccurrencesOfString:PROMPT_QUOTE_PLACEHOLDER withString:[self escapeDoubleQuotes:originalText]];

    return [[OpenAiApiRequest alloc] initGtp3WithPrompt:prompt];
}

- (VBMagicEnhancerOption*)optionForText:(NSString*)originalText withSelectedOption:(NSString*)optionString withMode:(MagicEnhancerMode)mode
{
    VBMagicEnhancerOption* option = [[VBMagicEnhancerOption alloc] init];
    option.buttonLabel = optionString;

    switch (mode) {
    case kModeTextExpansion: {
        NSString* originalTextToKeep = [self originalTextToKeepWhenStrippingLastPartialSentence:originalText];
        option.replacementText = [VBStringUtils truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:originalTextToKeep withSecondString:optionString];
        break;
    }
    case kModeNextSentence: {
        option.replacementText = [VBStringUtils truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:originalText withSecondString:optionString];
        break;
    }
    }

    return option;
}

- (NSString*)chatGptTextExpansionSystemDirective
{
    static NSString* chatGptTextExpansionSystemDirective;
    if (!chatGptTextExpansionSystemDirective) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"chat-gpt-text-expansion-system-directive" ofType:@"txt"];
        chatGptTextExpansionSystemDirective = [NSString stringWithContentsOfFile:path
                                                                        encoding:NSUTF8StringEncoding
                                                                           error:NULL];
    }
    return chatGptTextExpansionSystemDirective;
}

- (NSString*)gpt3TextExpansionPromptTemplate
{
    static NSString* textExpansionPrompt;
    if (!textExpansionPrompt) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"text-expansion" ofType:@"txt"];
        textExpansionPrompt = [NSString stringWithContentsOfFile:path
                                                        encoding:NSUTF8StringEncoding
                                                           error:NULL];
    }
    return textExpansionPrompt;
}

- (NSString*)gpt3NextSentancePromptTemplate
{
    static NSString* nextSentencePrompt;
    if (!nextSentencePrompt) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"next-sentence" ofType:@"txt"];
        nextSentencePrompt = [NSString stringWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];
    }
    return nextSentencePrompt;
}

@end
