//
//  VBMagicEnhancer.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBMagicEnhancer.h"

#import "AppSecrets.h"

@implementation VBMagicEnhancer


-(void) enhance:(NSString*)text onComplete:(void (^)(NSArray*, NSError*))complete {
    // TODO -- better escaping, or use edit API that separates input and instructions
    NSString* escapedText = [text stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
    NSString* prompt = [[self textExpansionPromptTemplate] stringByReplacingOccurrencesOfString:@"INSERT_QUOTE_PLACEHOLDER" withString:escapedText];
    [self openAiGptRequest:prompt onComplete:complete];
}

/*
 TODO - Lots to fix here. Getting it up for quick prototyping, but no where near ship worthy.
  - completion block format is fragile AF. Any early returns hang app. Replace with syncronous, and dispatch calls background. Return array/error directly.
  - Try the Open API edit endpoint
  - use "n" param of open API endpoint, and structured response instead of parsing json from plaintext
  - add timeout to request
 */
-(void) openAiGptRequest:(NSString*)prompt onComplete:(void (^)(NSArray*, NSError*))complete {
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
        NSArray* options;
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
                options = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&parseError];
                NSLog(@"The options are - %@", options);
            }
            NSLog(@"The response is - %@",responseDictionary);
        }
        
        if (!options) {
            complete(nil,  [NSError errorWithDomain:@"net.scosman.voicebox.openai.errors" code:91111 userInfo:@{NSLocalizedDescriptionKey:@"Issue with OpenAPI API."}]);
        }
        else {
            complete(options, nil);
        }
    }];
    [dataTask resume];
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

@end
