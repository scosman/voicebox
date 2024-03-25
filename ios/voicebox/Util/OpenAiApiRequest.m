//
//  OpenApiRequest.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-14.
//

#import "OpenAiApiRequest.h"

#import "AppSecrets.h"
#import "Constants.h"

#import "VBStringUtils.h"

#define OPEN_API_ROLE_PARAM @"role"
#define OPEN_API_CONTENT_PARAM @"content"

@implementation ChatGptMessage
@end

@implementation ChatGptRequest
@end

@implementation ResponseOption
- (bool)hasSuboptions
{
    return NO;
}
- (nonnull NSString*)replacementText
{
    return nil;
}
- (nonnull NSArray<ResponseOption*>*)subOptions
{
    return nil;
}
- (nonnull NSString*)displayName
{
    return nil;
}
@end

@interface StringResponseOption : ResponseOption
@property (nonatomic, strong) NSString* optionText;
@end

@implementation StringResponseOption
- (instancetype)initWithString:(NSString*)str
{
    self = [super init];
    if (self) {
        self.optionText = str;
    }
    return self;
}

- (bool)hasSuboptions
{
    return false;
}
- (NSString*)displayName
{
    return self.optionText;
}
- (NSString*)replacementText
{
    return self.optionText;
}

- (NSArray<ResponseOption*>*)subOptions
{
    return nil;
}
@end

@interface TopicResponseOption : ResponseOption
@property (nonatomic, strong) NSString* topicName;
@property (nonatomic, strong) NSMutableArray<ResponseOption*>* options;
@end

@implementation TopicResponseOption

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.options = [[NSMutableArray alloc] init];
    }
    return self;
}

- (bool)hasSuboptions
{
    return true;
}

- (NSString*)displayName
{
    return self.topicName;
}
- (NSString*)replacementText
{
    return nil;
}

- (NSArray<ResponseOption*>*)subOptions
{
    return self.options;
}

@end

@interface OpenAiApiRequest ()

@property (nonatomic, strong) NSDictionary* bodyPayload;
@property (nonatomic, strong) NSString *apiUrl, *bearerToken;

@end

@implementation OpenAiApiRequest

- (instancetype)initGtp3WithPrompt:(NSString*)prompt
{
    self = [super init];
    if (self) {
        self.apiUrl = @"https://api.openai.com/v1/completions";
        self.bearerToken = OPEN_API_KEY;
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
        self.bearerToken = OPEN_API_KEY;
        NSMutableDictionary* bodyPayload = [self buildBodyForChatCompletion:request];
        // bodyPayload[@"model"] = @"gpt-4-1106-preview";
        bodyPayload[@"model"] = @"gpt-3.5-turbo-1106";

        self.bodyPayload = bodyPayload;
    }
    return self;
}

- (instancetype)initGrokWithRequest:(ChatGptRequest*)request
{
    self = [super init];
    if (self) {
        self.apiUrl = @"https://api.groq.com/openai/v1/chat/completions";
        self.bearerToken = GROK_API_KEY;
        NSMutableDictionary* bodyPayload = [self buildBodyForChatCompletion:request];
        // https://console.groq.com/docs/models
        bodyPayload[@"model"] = @"mixtral-8x7b-32768";

        self.bodyPayload = bodyPayload;
    }
    return self;
}

- (NSMutableDictionary*)buildBodyForChatCompletion:(ChatGptRequest*)request
{
    NSMutableDictionary* bodyPayload = [[NSMutableDictionary alloc] init];

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

    return bodyPayload;
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
- (NSString*)sendSynchronousRequestRaw:(NSError**)error
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
    NSString* authBearerKey = [NSString stringWithFormat:@"Bearer %@", self.bearerToken];
    [urlRequest setValue:authBearerKey forHTTPHeaderField:@"Authorization"];

    [urlRequest setTimeoutInterval:OPEN_AI_API_TIMEOUT_SECONDS];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    NSURLSession* session = [NSURLSession sharedSession];
    __block NSData* responseData;
    __block NSError* requestBlockError;
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:urlRequest
                                                completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable requestErr) {
                                                    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                                                    if (requestErr) {
                                                        requestBlockError = requestErr;
                                                    } else if (httpResponse.statusCode != 200) {
                                                        if (data && data.length) {
                                                            NSLog(@"Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                                        }
                                                        requestBlockError = [self apiError:999200];
                                                    } else {
                                                        responseData = data;
                                                    }

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
    if (!responseData) {
        *error = [self apiError:91111];
        return nil;
    }

    NSError* jsonError = nil;
    id parsedJsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
    if (jsonError) {
        *error = jsonError;
        return nil;
    }

    NSString* responseMessage = [self parseOpenApiResponseForFirstChoice:parsedJsonResponse];
    if (!responseMessage) {
        *error = [self apiError:89345];
        return nil;
    }

    return responseMessage;
}

- (NSMutableArray<ResponseOption*>*)sendSynchronousRequest:(NSError**)error
{
    NSString* openAiMessage = [self sendSynchronousRequestRaw:error];
    return [OpenAiApiRequest processMessageString:openAiMessage withError:error];
}

+ (NSMutableArray<ResponseOption*>*)processMessageString:(NSString*)msgString withError:(NSError**)error
{
    NSLog(@"%@", msgString);
    NSString* jsonString = [self extractJsonBlockFromStringMsg:msgString];
    NSLog(@"%@", jsonString);

    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* jsonError = nil;
    id options = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
    if (jsonError) {
        *error = jsonError;
        return nil;
    }

    NSMutableArray<ResponseOption*>* optionArray = [[NSMutableArray alloc] init];
    if ([options isKindOfClass:[NSArray class]]) {
        for (id option in (NSArray*)options) {
            if ([option isKindOfClass:[NSString class]]) {
                StringResponseOption* sro = [[StringResponseOption alloc] initWithString:option];
                [optionArray addObject:sro];
            }
            if ([option isKindOfClass:[NSDictionary class]]) {
                NSDictionary* dict = (NSDictionary*)option;
                if (dict[@"name"] && dict[@"options"] && dict[@"most_general"]) {
                    // this is a topic
                    TopicResponseOption* topic = [[TopicResponseOption alloc] init];
                    topic.topicName = dict[@"name"];
                    for (NSString* optionText in (NSArray*)dict[@"options"]) {
                        StringResponseOption* sro = [[StringResponseOption alloc] initWithString:optionText];
                        [topic.options addObject:sro];
                    }
                    StringResponseOption* sro = [[StringResponseOption alloc] initWithString:dict[@"most_general"]];
                    [topic.options addObject:sro];
                    [optionArray addObject:topic];
                }
            }
        }
    }

    return optionArray;
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

// Extracts a ```json .... ``` block if one exists
+ (NSString*)extractJsonBlockFromStringMsg:(NSString*)rawMsg
{
    // Support ```json and ``` for start
    NSRange startRange = [rawMsg rangeOfString:@"```json"];
    if (startRange.location == NSNotFound) {
        startRange = [rawMsg rangeOfString:@"```"];
    }
    NSRange endRange = [rawMsg rangeOfString:@"```" options:NSBackwardsSearch];
    if (startRange.location == NSNotFound || endRange.location == NSNotFound || endRange.location <= startRange.location) {
        return rawMsg;
    }

    NSUInteger startPos = startRange.location + startRange.length;
    NSRange jsonRange = NSMakeRange(startPos, endRange.location - startPos);
    return [rawMsg substringWithRange:jsonRange];
}

+ (NSArray<ResponseOption*>*)developmentResponseOptions
{
    NSMutableArray<ResponseOption*>* a = [[NSMutableArray alloc] init];

    StringResponseOption* sro1 = [[StringResponseOption alloc] init];
    sro1.optionText = @"Option 1";
    [a addObject:sro1];

    StringResponseOption* sro2 = [[StringResponseOption alloc] init];
    sro2.optionText = @"Option 2";
    [a addObject:sro2];

    for (int j = 1; j < 3; j++) {
        TopicResponseOption* tro = [[TopicResponseOption alloc] init];
        tro.topicName = [NSString stringWithFormat:@"Topic %d", j];
        for (int i = 1; i < 6; i++) {
            StringResponseOption* sro = [[StringResponseOption alloc] init];
            sro.optionText = [NSString stringWithFormat:@"Sub-option %d", i];
            [tro.options addObject:sro];
        }
        [a addObject:tro];
    }

    return a;
}

@end
