//
//  ViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "MainViewController.h"

#import "Constants.h"
#import "VBSpeechSynthesizer.h"
#import "VBMagicEnhancer.h"
#import "VBButton.h"
#import "VBEnhanceViewController.h"

@interface MainViewController () <UITextViewDelegate, EnhanceViewSelectionDelegate>

@property (nonatomic, weak) UITextView* textView;
@property (nonatomic, weak) VBButton *speakButton, *magicButton;
@property (nonatomic, strong) VBSpeechSynthesizer* speechSynthesizer;
@property (nonatomic, strong) VBMagicEnhancer* enhancer;

@end

@implementation MainViewController

-(instancetype)init {
    self = [super init];
    self.speechSynthesizer = [[VBSpeechSynthesizer alloc] init];
    self.enhancer = [[VBMagicEnhancer alloc] init];
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
#if DEBUG
    textView.text = @"cold";
#endif
    _textView = textView;

    VBButton* speakButton =  [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"person.wave.2.fill" andTitle:@"Speak"];
    speakButton.translatesAutoresizingMaskIntoConstraints = NO;
    [speakButton addTarget:self action:@selector(speakText:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:speakButton];
    _speakButton = speakButton;
    
    VBButton* magicButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"wand.and.stars" andTitle:@"Enhance"];
    magicButton.translatesAutoresizingMaskIntoConstraints = NO;
    [magicButton addTarget:self action:@selector(enhanceText:) forControlEvents:UIControlEventPrimaryActionTriggered];
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
        [speakButton.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:textView.trailingAnchor multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE],
        [speakButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [speakButton.heightAnchor constraintEqualToConstant:buttonHeith],

        // Magic button
        [magicButton.topAnchor constraintEqualToSystemSpacingBelowAnchor:speakButton.bottomAnchor multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE],
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

-(void) enhanceText:(UIButton*)sender {
    VBEnhanceViewController* enhanceVc = [[VBEnhanceViewController alloc] init];
    enhanceVc.modalPresentationStyle = UIModalPresentationPageSheet;
    enhanceVc.selectionDelegate = self;
    [self presentViewController:enhanceVc animated:YES completion:nil];
    
    // Load suggestions from the great ML in the cloud
    NSString* fullText = self.textView.text;
    [self.enhancer enhance:fullText onComplete:^(NSArray * _Nonnull options, NSError * _Nonnull error) {
        if (error) {
            // TODO: user visible error handling
            [enhanceVc dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [enhanceVc showOptions:options];
        });
    }];
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

#pragma - mark EnhanceViewSelectionDelegate

- (void)didSelectEnhanceOption:(VBMagicEnhancerOption*)selectedOption {
    self.textView.text = selectedOption.replacementText;
}

@end
