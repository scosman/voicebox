//
//  OpenApiRequest.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-14.
//

#import "OpenAiApiRequest.h"

#import "AppSecrets.h"
#import "Constants.h"

#define OPEN_API_ROLE_PARAM @"role"
#define OPEN_API_CONTENT_PARAM @"content"

@implementation ChatGptMessage
@end

@implementation ChatGptRequest
@end

@interface OpenAiApiRequest ()

@property (nonatomic, strong) NSDictionary* bodyPayload;
@property (nonatomic, strong) NSString* apiUrl;

@end

@implementation OpenAiApiRequest

- (instancetype)initGtp3WithPrompt:(NSString*)prompt
{
    self = [super init];
    if (self) {
        self.apiUrl = @"https://api.openai.com/v1/completions";
        // TODO: none of these are tuned, just defaults
        self.bodyPayload = @{
            @"model" : @"text-davinci-003",
            @"prompt" : prompt,
            @"temperature" : @0,
            @"max_tokens" : @245,
            @"top_p" : @1,
            @"frequency_penalty" : @0,
            @"presence_penalty" : @0
        };
    }
    return self;
}

- (instancetype)initChatGtpWithRequest:(ChatGptRequest*)request
{
    self = [super init];
    if (self) {
        self.apiUrl = @"https://api.openai.com/v1/chat/completions";
        NSMutableDictionary* bodyPayload = [[NSMutableDictionary alloc] init];
        bodyPayload[@"model"] = @"gpt-3.5-turbo";

        // build system directive message
        NSMutableArray<NSDictionary*>* apiMessageSet = [[NSMutableArray alloc] init];
        [apiMessageSet addObject:@{ OPEN_API_ROLE_PARAM : @"system", OPEN_API_CONTENT_PARAM : request.systemDirective }];

        // Build set of messages
        for (ChatGptMessage* message in request.messages) {
            NSString* role;
            switch (message.roll) {
            case kChatGptRollUser:
                role = @"user";
                break;
            case kChatGptRollAssistant:
                role = @"assistant";
                break;
            default:
                NSLog(@"invalid role");
                return nil;
            }
            [apiMessageSet addObject:@{ OPEN_API_ROLE_PARAM : role, OPEN_API_CONTENT_PARAM : message.content }];
        }
        bodyPayload[@"messages"] = apiMessageSet;
        self.bodyPayload = bodyPayload;
    }
    return self;
}

// Why make this sync? Too many error condition checks here for safe usage of callbacks.
// Early returns, several levels of parsing errors. Want to make sure this code is robust to future
// changes. Any return should return back up to UI callback, so wrapped this all in a sync.
/*
 TODO
  - Try the Open API edit endpoint
  - P0 before ship: the assumption the prompt returns valid json is not nearly robust enough to ship.
    strangely it's been rock solid, so using for prototyping. Try the "n" param of open API endpoint,
    and structured response instead of parsing json from plaintext
 */
- (NSArray<NSString*>*)sendSynchronousRequest:(NSError**)error
{
    NSData* bodyPayloadJsonData = [NSJSONSerialization dataWithJSONObject:self.bodyPayload options:NSJSONWritingPrettyPrinted error:error];
    if (*error) {
        return nil;
    }

    NSMutableURLRequest* urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.apiUrl]];

    // POST body
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:bodyPayloadJsonData];

    // Headers
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString* authBearerKey = [NSString stringWithFormat:@"Bearer %@", OPEN_API_KEY];
    [urlRequest setValue:authBearerKey forHTTPHeaderField:@"Authorization"];

    [urlRequest setTimeoutInterval:OPEN_AI_API_TIMEOUT_SECONDS];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    NSURLSession* session = [NSURLSession sharedSession];
    __block NSArray<NSString*>* options;
    __block NSError* requestBlockError;
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:urlRequest
                                                completionHandler:^(NSData* data, NSURLResponse* response, NSError* requestError) {
                                                    options = [self processResponse:response withData:data withRequestError:requestError withError:&requestBlockError];
                                                    dispatch_semaphore_signal(semaphore);
                                                }];
    [dataTask resume];

    // Timeout: 1s over the network timeout
    float timeoutBuffer = 1.0;
#if DEBUG
    // When debugging, want lots of time before UI timeout
    timeoutBuffer = 1000.0;
#endif
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * (OPEN_AI_API_TIMEOUT_SECONDS + timeoutBuffer))));

    if (requestBlockError) {
        *error = requestBlockError;
        return nil;
    }
    if (!options) {
        *error = [self apiError:91111];
        return nil;
    }

    return options;
}

- (NSArray<NSString*>*)processResponse:(NSURLResponse*)response withData:(NSData*)data withRequestError:(NSError*)requestError withError:(NSError**)error
{
    if (requestError) {
        *error = requestError;
        return nil;
    }

    NSArray<NSString*>* stringOptions;
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if (httpResponse.statusCode != 200) {
        *error = [self apiError:999200];
        return nil;
    }

    NSError* jsonError = nil;
    id parsedJsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
        *error = jsonError;
        return nil;
    }

    NSString* responseJSONString = [self parseOpenApiResponseForFirstChoice:parsedJsonResponse];
    if (!responseJSONString) {
        *error = [self apiError:89345];
        return nil;
    }

    NSData* jsonData = [responseJSONString dataUsingEncoding:NSUTF8StringEncoding];
    stringOptions = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
    if (jsonError) {
        *error = jsonError;
        return nil;
    }

    return stringOptions;
}

- (NSString*)parseOpenApiResponseForFirstChoice:(id)parsedJsonResponse
{
    if (!parsedJsonResponse || ![parsedJsonResponse isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary* responseDictionary = parsedJsonResponse;

    id choices = responseDictionary[@"choices"];
    if (!choices || ![choices isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSArray* choicesArray = choices;

    id firstChoice = choicesArray.firstObject;
    if (!firstChoice || ![firstChoice isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary* firstChoiceDict = firstChoice;

    // text for GPT3, message for chatGPT
    id optionsText = firstChoiceDict[@"text"];
    if (!optionsText) {
        id chatGptMessage = firstChoiceDict[@"message"];
        if (!chatGptMessage || ![chatGptMessage isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        NSDictionary* chatGptMessageDict = chatGptMessage;
        if (![@"assistant" isEqualToString:chatGptMessageDict[@"role"]]) {
            NSLog(@"expected assistant response");
            return nil;
        }
        optionsText = chatGptMessageDict[@"content"];
    }
    if (!optionsText || ![optionsText isKindOfClass:[NSString class]]) {
        return nil;
    }
    return optionsText;
}

- (NSError*)apiError:(NSInteger)code
{
    return [NSError errorWithDomain:@"net.scosman.voicebox.openai.errors" code:code userInfo:@{ NSLocalizedDescriptionKey : @"Issue with OpenAI API." }];
}

@end
