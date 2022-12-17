//
//  VBSpeechSynthesizer.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VBSpeechSynthesizer : NSObject

- (void)speak:(NSString*)textToSpeak;

@end

NS_ASSUME_NONNULL_END
