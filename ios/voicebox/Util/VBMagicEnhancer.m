//
//  VBMagicEnhancer.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBMagicEnhancer.h"

#import "OpenAiApiRequest.h"
#import "VBStringUtils.h"

#define PROMPT_QUOTE_PLACEHOLDER @"INSERT_QUOTE_PLACEHOLDER"
#define PROMPT_PRIOR_CONTENT_PLACEHOLDER @"PRIOR_CONTENT_PLACEHOLDER"

typedef NS_ENUM(NSUInteger, MagicEnhancerMode) {
    kModeTextExpansion,
    kModeNextSentence
};

/*
@implementation VBMagicEnhancerOption
@end
*/

@implementation VBMagicEnhancer

- (void)enhance:(NSString*)text onComplete:(void (^)(NSArray<ResponseOption*>*, NSError*))complete
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

- (void)requestAndBuildOptions:(OpenAiApiRequest*)request withOriginalText:(NSString*)originalText withMode:(MagicEnhancerMode)mode onComplete:(void (^)(NSArray<ResponseOption*>*, NSError*))complete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError* err;
        NSMutableArray<ResponseOption*>* options = [self requestAndBuildOptionsSyncronous:request withOriginalText:(NSString*)originalText withMode:mode withError:&err];

        if (err) {
            complete(nil, err);
        } else {
            complete(options, nil);
        }
    });
}

- (NSMutableArray<ResponseOption*>*)requestAndBuildOptionsSyncronous:(OpenAiApiRequest*)apiRequest withOriginalText:(NSString*)originalText withMode:(MagicEnhancerMode)mode withError:(NSError**)error
{
    NSMutableArray<ResponseOption*>* sourceOptions = [apiRequest sendSynchronousRequest:error];
    if (*error) {
        return nil;
    }

    [self buildFullResponseStrings:sourceOptions withOriginalText:originalText withMode:mode];

    return sourceOptions;

    /*NSMutableArray<VBMagicEnhancerOption*>* options = [[NSMutableArray alloc] initWithCapacity:stringOptions.count];
    for (NSString* stringOption in stringOptions) {I'm cold.
        VBMagicEnhancerOption* option = [self optionForText:originalText withSelectedOption:stringOption withMode:mode];
        [options addObject:option];
    }
    return options;*/
}

- (void)buildFullResponseStrings:(NSArray<ResponseOption*>*)sourceOptions withOriginalText:(NSString*)originalText withMode:(MagicEnhancerMode)mode
{
    for (ResponseOption* option in sourceOptions) {
        if (option.hasSuboptions) {
            [self buildFullResponseStrings:option.subOptions withOriginalText:originalText withMode:mode];
        } else if (option.replacementText) {
            switch (mode) {
            case kModeTextExpansion: {
                NSString* originalTextToKeep = [VBStringUtils originalTextToKeepWhenStrippingLastPartialSentence:originalText];
                option.fullBodyReplacement = [VBStringUtils truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:originalTextToKeep withSecondString:option.replacementText];
                break;
            }
            case kModeNextSentence: {
                option.fullBodyReplacement = [VBStringUtils truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:originalText withSecondString:option.replacementText];
                break;
            }
            }
        }
    }
}

- (NSString*)escapeDoubleQuotes:(NSString*)text
{
    // TODO -- better escaping, or use edit API that separates input and instructions
    return [text stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
    ;
}

- (OpenAiApiRequest*)requestForText:(NSString*)originalText withMode:(MagicEnhancerMode)mode
{
    return [self gpt35MidRequestForText:originalText ofMode:mode];
    // return [self gpt4RequestForText:originalText ofMode:mode];
    /*switch (mode) {
    case kModeTextExpansion: {
        return [self gpt3TextExpansionRequestForText:originalText];
        //return [self chatGptTextExpansionRequestForText:originalText];
    }
    case kModeNextSentence: {
        return [self gpt3NextSentenceRequestForText:originalText];
    }
    }*/
}

- (OpenAiApiRequest*)gpt35MidRequestForText:(NSString*)originalText ofMode:(MagicEnhancerMode)mode;
{
    return [self gptSharedTaskRequestForText:originalText ofMode:mode withSystemPrompt:[self gpt35MidSystemDirective]];
}

- (OpenAiApiRequest*)gpt4RequestForText:(NSString*)originalText ofMode:(MagicEnhancerMode)mode;
{
    return [self gptSharedTaskRequestForText:originalText ofMode:mode withSystemPrompt:[self gpt4SystemDirective]];
}

- (OpenAiApiRequest*)gptSharedTaskRequestForText:(NSString*)originalText ofMode:(MagicEnhancerMode)mode withSystemPrompt:(NSString*)systemPrompt
{

    NSString* userMessage;
    switch (mode) {
    case kModeTextExpansion:
        userMessage = @"This message is for task 1.";
        break;
    case kModeNextSentence:
        userMessage = @"This message is for task 2.";
    }

    NSString* originalTextToKeep = [VBStringUtils originalTextToKeepWhenStrippingLastPartialSentence:originalText];
    NSString* trimmedOriginalTextToKeep = [originalTextToKeep stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedOriginalTextToKeep.length > 0) {
        // TODO trim this
        NSString* escapedPriorContent = [self escapeDoubleQuotes:trimmedOriginalTextToKeep];
        NSString* priorContentSection = [NSString stringWithFormat:@"The user had already typed (preceeing text/prior sentances): \"%@\"", escapedPriorContent];
        userMessage = [NSString stringWithFormat:@"%@\n\n%@", userMessage, priorContentSection];
    }

    if (mode == kModeTextExpansion) {
        NSString* lastSentence = [VBStringUtils lastPartialSentenceFromString:originalText];
        if (!lastSentence) {
            return nil;
        }
        NSString* escapedLastSentence = [self escapeDoubleQuotes:lastSentence];
        userMessage = [NSString stringWithFormat:@"%@\n\nThe quote (partial sentence in progress) is: \"%@\"", userMessage, escapedLastSentence];
    }

    ChatGptRequest* request = [[ChatGptRequest alloc] init];
    request.systemDirective = systemPrompt;

    ChatGptMessage* apiMessage = [[ChatGptMessage alloc] init];
    apiMessage.roll = kChatGptRollUser;
    apiMessage.content = userMessage;
    request.messages = @[ apiMessage ];

    return [[OpenAiApiRequest alloc] initChatGtpWithRequest:request];
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

    NSString* originalTextToKeep = [VBStringUtils originalTextToKeepWhenStrippingLastPartialSentence:originalText];
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

- (NSString*)gpt4SystemDirective
{
    static NSString* gpt4SystemDirective;
    if (!gpt4SystemDirective) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"gpt4-v4" ofType:@"txt"];
        gpt4SystemDirective = [NSString stringWithContentsOfFile:path
                                                        encoding:NSUTF8StringEncoding
                                                           error:NULL];
    }
    return gpt4SystemDirective;
}

- (NSString*)gpt35MidSystemDirective
{
    static NSString* gpt35MidSystemDirective;
    if (!gpt35MidSystemDirective) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"gpt3.5 - mid 3" ofType:@"txt"];
        gpt35MidSystemDirective = [NSString stringWithContentsOfFile:path
                                                            encoding:NSUTF8StringEncoding
                                                               error:NULL];
    }
    return gpt35MidSystemDirective;
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
