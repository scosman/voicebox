//
//  OpenApiRequest.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-14.
//

#import <Foundation/Foundation.h>

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

@interface OpenAiApiRequest : NSObject

- (instancetype)initGtp3WithPrompt:(NSString*)prompt;
- (instancetype)initChatGtpWithRequest:(ChatGptRequest*)request;
- (NSArray<NSString*>*)sendSynchronousRequest:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
