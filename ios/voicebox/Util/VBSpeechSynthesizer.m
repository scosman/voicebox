//
//  VBSpeechSynthesizer.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBSpeechSynthesizer.h"

#import <AVFoundation/AVSpeechSynthesis.h>
#import <UIKit/UIKit.h>

@interface VBSpeechSynthesizer ()

@property (nonatomic, strong) AVSpeechSynthesizer* avSpeechSynthesizer;

@end

@implementation VBSpeechSynthesizer

- (instancetype)init
{
    self = [super init];

    // register memory warning listener
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    return self;
}

- (void)speak:(NSString*)textToSpeak
{
    AVSpeechUtterance* utterance = [[AVSpeechUtterance alloc] initWithString:textToSpeak];

    // TODO -- slow down the default utterance a bit for making it clearer

    // TODO -- specify voice. List all with AVSpeechSynthesisVoice.speechVoices, find
    // highest quality matching curent locale. Save result for next time.
    // AVSpeechSynthesisVoice* voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
    // voice = [AVSpeechSynthesisVoice voiceWithIdentifier:@"com.apple.speech.synthesis.voice.Fred"];
    // en-US, Name: Fred, Quality: Default [com.apple.speech.synthesis.voice.Fred]
    AVSpeechSynthesisVoice* voice = [[AVSpeechSynthesisVoice alloc] init];
    /*NSArray* speechVoices = [AVSpeechSynthesisVoice speechVoices];
    NSLog(@"Voices: (%d) %@", speechVoices.count, speechVoices);
    for (AVSpeechSynthesisVoice* candidateVoice in speechVoices) {
        if (candidateVoice.quality > voice.quality) {
     // Need to check gender, and region
            voice = candidateVoice;
        }
    }*/
    utterance.voice = voice;

    // Create a speech synthesizer if not available. May be removed under memory presure so always check.
    if (!_avSpeechSynthesizer) {
        @synchronized((self)) {
            if (!_avSpeechSynthesizer) {
                _avSpeechSynthesizer = [[AVSpeechSynthesizer alloc] init];
            }
        }
    }

    [_avSpeechSynthesizer speakUtterance:utterance];
}

- (void)handleMemoryWarning:(NSNotification*)notification
{
    _avSpeechSynthesizer = nil;
}

@end
