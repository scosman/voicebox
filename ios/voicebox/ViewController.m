//
//  ViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "ViewController.h"

#import "VBSpeechSynthesizer.h"
#import "VBButton.h"

@interface ViewController () <UITextViewDelegate>

@property (nonatomic, weak) UITextView* textView;
@property (nonatomic, weak) VBButton *speakButton, *magicButton;
@property (nonatomic, strong) VBSpeechSynthesizer* speechSynthesizer;

@end

@implementation ViewController

-(instancetype)init {
    self = [super init];
    self.speechSynthesizer = [[VBSpeechSynthesizer alloc] init];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    UITextView* textView = [[UITextView alloc] init];
    [self.view addSubview:textView];
    // Font side, at least 32, larger if system font is huge
    textView.font = [UIFont systemFontOfSize:MAX([UIFont systemFontSize], 38.0)];
    textView.textContainerInset = UIEdgeInsetsMake(23, 25, 23, 25);
    textView.layer.cornerRadius = 25;
    textView.clipsToBounds = YES;
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.delegate = self;
    _textView = textView;

    VBButton* speakButton =  [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"person.wave.2.fill" andTitle:@"Speak"];
    speakButton.translatesAutoresizingMaskIntoConstraints = NO;
    [speakButton addTarget:self action:@selector(speakText:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:speakButton];
    _speakButton = speakButton;
    
    VBButton* magicButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"wand.and.stars" andTitle:@"Enhance"];
    magicButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:magicButton];
    _magicButton = magicButton;
    
    [self updateButtonStates];

    const float buttonWidth = 200.0;
    const float buttonHeith = 150.0;
    const float accessibleSystemSpaceMultiplier = 3.0;

    // Layout
    NSArray<NSLayoutConstraint*>* constraints = @[
        // Text View
        [textView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor constant:-20.0],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],

        // Speak button
        [speakButton.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [speakButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [speakButton.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:textView.trailingAnchor multiplier:accessibleSystemSpaceMultiplier],
        [speakButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [speakButton.heightAnchor constraintEqualToConstant:buttonHeith],

        // Magic button
        [magicButton.topAnchor constraintEqualToSystemSpacingBelowAnchor:speakButton.bottomAnchor multiplier:accessibleSystemSpaceMultiplier],
        [magicButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [magicButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [magicButton.heightAnchor constraintEqualToConstant:buttonHeith],
    ];
    [NSLayoutConstraint activateConstraints:constraints];

    [textView becomeFirstResponder];
}

-(void) speakText:(UIButton*)sender {
    NSString* textToSpeak = self.textView.text;
    [self.speechSynthesizer speak:textToSpeak];
}

-(void) updateButtonStates {
    BOOL hasText = self.textView.text.length > 0;
    self.speakButton.enabled = hasText;
    self.magicButton.enabled = hasText;
}

#pragma - mark UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView {
    [self updateButtonStates];
}

@end
