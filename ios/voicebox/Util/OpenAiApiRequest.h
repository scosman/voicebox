//
//  OpenApiRequest.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-14.
//

#import <Foundation/Foundation.h>

#import "VBResponseOption.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ChatGptRoll) {
    kChatGptRollUser,
    kChatGptRollAssistant
};

@interface ChatGptMessage : NSObject

@property (assign) ChatGptRoll roll;
@property (nonatomic, strong) NSString* content;

@end

@interface ChatGptRequest : NSObject

@property (nonatomic, strong) NSString *systemDirective, *model;
@property (nonatomic, strong) NSArray<ChatGptMessage*>* messages;

@end

@interface OpenAiApiRequest : NSObject <VBMLProvider>

- (instancetype)initGtp3WithPrompt:(NSString*)prompt;
- (instancetype)initChatGtpWithRequest:(ChatGptRequest*)request;
- (instancetype)initGrokWithRequest:(ChatGptRequest*)request;

+ (NSArray<ResponseOption*>*)developmentResponseOptions;
+ (NSMutableArray<ResponseOption*>*)processMessageString:(NSString*)msgString withError:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
