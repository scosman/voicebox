//
//  VBMagicEnhancer.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBMagicEnhancer.h"

#import "AppSecrets.h"
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

-(void) enhance:(NSString*)text onComplete:(void (^)(NSArray<VBMagicEnhancerOption*>*, NSError*))complete {
    // default to text expansion.
    MagicEnhancerMode mode = kModeTextExpansion;
    // if last charater is a period, do the next sentence completion
    if ([VBStringUtils endsInCompleteSentence:text]) {
        mode = kModeNextSentence;
    }
    
    NSString* prompt = [self promptForText:text withMode:mode];
    if (!prompt) {
        complete(nil, [NSError errorWithDomain:@"net.scosman.voicebox.custom" code:89939 userInfo:@{NSLocalizedDescriptionKey:@"Issue generating prompt."}]);
        return;;
    }
    
    [self openAiGptRequest:prompt withOriginalText:text withMode:mode onComplete:complete];
}

/*
 TODO - Lots to fix here. Getting it up for quick prototyping, but no where near ship worthy.
  - completion block format is fragile AF. Any early returns hang app. Replace with syncronous, and dispatch calls background. Return array/error directly.
  - Try the Open API edit endpoint
  - use "n" param of open API endpoint, and structured response instead of parsing json from plaintext
  - add timeout to request
 */
-(void) openAiGptRequest:(NSString*)prompt withOriginalText:(NSString*)originalText withMode:(MagicEnhancerMode)mode onComplete:(void (^)(NSArray<VBMagicEnhancerOption*>*, NSError*))complete {
    // TODO: none of these are tuned, just defaults
    NSDictionary* bodyPayloadData = @{
        @"model": @"text-davinci-003",
        @"prompt": prompt,
        @"temperature": @0,
        @"max_tokens": @245,
        @"top_p": @1,
        @"frequency_penalty": @0,
        @"presence_penalty": @0
    };
    
    NSError* error;
    NSData* bodyPayloadJsonData = [NSJSONSerialization dataWithJSONObject:bodyPayloadData options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        complete(nil, error);
    }
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.openai.com/v1/completions"]];

    // POST body
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:bodyPayloadJsonData];
    
    // Headers
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString* authBearerKey = [NSString stringWithFormat:@"Bearer %@", OPEN_API_KEY];
    [urlRequest setValue:authBearerKey forHTTPHeaderField:@"Authorization"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSArray* stringOptions;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode != 200)
        {
            NSLog(@"Status Code Error: %ld", (long)httpResponse.statusCode);
        } else {
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            NSString* responseJSONString = responseDictionary[@"choices"][0][@"text"];
            if (!parseError && responseJSONString) {
                NSLog(@"The payload response is - %@", responseJSONString);
                NSData* jsonData = [responseJSONString dataUsingEncoding:NSUTF8StringEncoding];
                stringOptions = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&parseError];
                NSLog(@"The options are - %@", stringOptions);
            }
            NSLog(@"The response is - %@",responseDictionary);
        }
        
        if (!stringOptions) {
            complete(nil,  [NSError errorWithDomain:@"net.scosman.voicebox.openai.errors" code:91111 userInfo:@{NSLocalizedDescriptionKey:@"Issue with OpenAI API."}]);
        }
        else {
            NSMutableArray<VBMagicEnhancerOption*>* options = [[NSMutableArray alloc] initWithCapacity:stringOptions.count];
            for (NSString* stringOption in stringOptions) {
                VBMagicEnhancerOption* option = [self optionForText:originalText withSelectedOption:stringOption withMode:mode];
                [options addObject:option];
            }
            complete(options, nil);
        }
    }];
    [dataTask resume];
}

-(NSString*) escapeDoubleQuotes:(NSString*)text {
    // TODO -- better escaping, or use edit API that separates input and instructions
    return [text stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];;
}

-(NSString*) originalTextToKeepWhenStrippingLastPartialSentence:(NSString*)text {
    NSString* lastSentenceToReplace = [VBStringUtils lastPartialSentenceFromString:text];
    NSUInteger originalTextToKeepLength = text.length - lastSentenceToReplace.length;
    if (originalTextToKeepLength > text.length) {
        // shouldn't hit
        NSAssert(NO, @"Unexpected: last sentence to replace longer than original text.");
        return @"";
    }
    return [text substringToIndex:originalTextToKeepLength];;
}

-(NSString*) promptForText:(NSString*)originalText withMode:(MagicEnhancerMode)mode {
    switch (mode) {
        case kModeTextExpansion:
        {
            // TODO P0 -- we're only passing last sentence to ML. It loses all context from prior sentences.
            NSString* promptTemplate = [self textExpansionPromptTemplate];
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
            return prompt;
        }
        case kModeNextSentence:
        {
            if (originalText.length <= 0) {
                return nil;
            }
            NSString* promptTemplate = [self nextSentancePromptTemplate];
            return [promptTemplate stringByReplacingOccurrencesOfString:PROMPT_QUOTE_PLACEHOLDER withString:[self escapeDoubleQuotes:originalText]];
        }
    }
}

-(VBMagicEnhancerOption*) optionForText:(NSString*)originalText withSelectedOption:(NSString*)optionString withMode:(MagicEnhancerMode)mode {
    VBMagicEnhancerOption* option = [[VBMagicEnhancerOption alloc] init];
    option.buttonLabel = optionString;
    
    switch (mode) {
        case kModeTextExpansion:
        {
            NSString* originalTextToKeep = [self originalTextToKeepWhenStrippingLastPartialSentence:originalText];
            option.replacementText = [VBStringUtils truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:originalTextToKeep withSecondString:optionString];
            break;
        }
        case kModeNextSentence:
        {
            option.replacementText = [VBStringUtils truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:originalText withSecondString:optionString];
            break;
        }
    }
    
    return option;
}

-(NSString*) textExpansionPromptTemplate {
    static NSString* textExpansionPrompt;
    if (!textExpansionPrompt) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"text-expansion" ofType:@"txt"];
        textExpansionPrompt = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
    }
    return textExpansionPrompt;
}

-(NSString*) nextSentancePromptTemplate {
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
