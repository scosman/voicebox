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
    NSString* prompt = [NSString stringWithFormat:[self promptTemplate], escapedText];
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

-(NSString*) promptTemplate {
    return @"The following quote is from someone with a disability who can not type quickly. Because they can not type quickly, they may use fewer words to express themselves. Their quote may also have gramatical or spelling errors.\n\n\
    Please offer 6 new quotes, expressing what they may be trying to communicate in standard English. The generated quotes should be in the first person. They should be friendly and casual in tone, they are not for a formal or professional setting. Please correct and spelling or gammar errors.\n\n\
    It may not clear what the person who wrote the quote is trying to communicate. For example \"hungry\" could mean \"I am hungry.\" or \"are you hungry?\" or \"are they hungry?\". The 6 returned quotes should express the range of possible meanings the original person was trying to communicate. It's important the most likely meaning they are trying to convey in this social conversation is covered in the potential replies, ideally in the first position.\n\n\
    Please ensure the 6 new quotes cover several unique meanings, and aren't just different phrasings of the same meaning. They should be the most likley meanings that would come up in a casual social conversation.\n\n\
    The quote may be the start to a quesiton, even if it doesn't include a question mark.\n\n\
    At minimum, the 6 quotes should cover at least 2 separate meanings and not all be different ways of phrasing one interpretation of the quote's meaning.\n\n\
    The quote may also be the start of a sentance which is not yet complete. If it looks like that is the case, you can offer the complete sentance the person may be starting to type.\n\n\
    Please format the response as a JSON array of strings.\n\n\
    The quote is: \"%@\"";
}

@end
