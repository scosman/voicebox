//
//  ViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "ViewController.h"

#import <AVFoundation/AVSpeechSynthesis.h>

@interface ViewController () <UITextViewDelegate>

@property (nonatomic, weak) UITextView* textView;
@property (nonatomic, weak) UIButton *speakButton, *magicButton;
@property (nonatomic, strong) AVSpeechSynthesizer* speechSynthesizer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor greenColor];

    UITextView* textView = [[UITextView alloc] init];
    [self.view addSubview:textView];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.delegate = self;
    _textView = textView;

    UIButton* speakButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [speakButton setTitle:@"Speak" forState:UIControlStateNormal];
    speakButton.translatesAutoresizingMaskIntoConstraints = NO;
    [speakButton addTarget:self action:@selector(speakText:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:speakButton];
    _speakButton = speakButton;
    
    UIButton* magicButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [magicButton setTitle:@"Magic" forState:UIControlStateNormal];
    magicButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:magicButton];
    _magicButton = magicButton;
    
    [self updateButtonStates];

    const float buttonWidth = 200.0;
    const float buttonHeith = 150.0;

    // Layout
    NSArray<NSLayoutConstraint*>* constraints = @[
        // Text View
        [textView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor constant:-20.0],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],

        // Speak button
        [speakButton.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [speakButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [speakButton.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:textView.trailingAnchor multiplier:1.0],
        [speakButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [speakButton.heightAnchor constraintEqualToConstant:buttonHeith],

        // Magic button
        [magicButton.topAnchor constraintEqualToSystemSpacingBelowAnchor:speakButton.bottomAnchor multiplier:1.0],
        [magicButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [magicButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [magicButton.heightAnchor constraintEqualToConstant:buttonHeith],
    ];
    [NSLayoutConstraint activateConstraints:constraints];

    [textView becomeFirstResponder];
}

-(void) speakText:(UIButton*)sender {
    // Create an utterance.
    NSString* textToSpeak = self.textView.text;
    AVSpeechUtterance* utterance = [[AVSpeechUtterance alloc] initWithString:textToSpeak];

    // TODO -- specify voice. List all with AVSpeechSynthesisVoice.speechVoices, find
    // highest quality matching curent locale. Save result for next time.
    AVSpeechSynthesisVoice* voice = [[AVSpeechSynthesisVoice alloc] init];;
    utterance.voice = voice;
    
    // Create a speech synthesizer and speak
    if (!_speechSynthesizer) {
        @synchronized ((self)) {
            if (!_speechSynthesizer) {
                _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
            }
        }
    }
    [_speechSynthesizer speakUtterance:utterance];
}

-(void) updateButtonStates {
    if (self.textView.text.length > 0) {
        self.speakButton.enabled = YES;
        self.magicButton.enabled = YES;
        _magicButton.backgroundColor = [UIColor systemBlueColor];
        _speakButton.backgroundColor = [UIColor systemBlueColor];
    } else {
        self.speakButton.enabled = NO;
        self.magicButton.enabled = NO;
        _magicButton.backgroundColor = [UIColor grayColor];
        _speakButton.backgroundColor = [UIColor grayColor];
    }
}

#pragma - mark UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView {
    [self updateButtonStates];
}

@end
