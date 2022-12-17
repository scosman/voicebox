//
//  ViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "MainViewController.h"

#import "Constants.h"
#import "VBButton.h"
#import "VBEnhanceViewController.h"
#import "VBMagicEnhancer.h"
#import "VBSpeechSynthesizer.h"

@interface MainViewController () <UITextViewDelegate, EnhanceViewSelectionDelegate>

@property (nonatomic, weak) UITextView* textView;
@property (nonatomic, weak) UILabel* voiceboxLabel;
@property (nonatomic, weak) VBButton *speakButton, *magicButton;
@property (nonatomic, weak) UIButton* clearTextButton;
@property (nonatomic, strong) VBSpeechSynthesizer* speechSynthesizer;
@property (nonatomic, strong) VBMagicEnhancer* enhancer;
@property (nonatomic) BOOL hasShownIntroAnimation;

@end

@implementation MainViewController

- (instancetype)init
{
    self = [super init];
    self.speechSynthesizer = [[VBSpeechSynthesizer alloc] init];
    self.enhancer = [[VBMagicEnhancer alloc] init];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = APP_BACKGROUND_UICOLOR;

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

    UILabel* voiceboxLabel = [[UILabel alloc] init];
    voiceboxLabel.attributedText = [self logoLabelAttributedString];
    voiceboxLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:voiceboxLabel];
    _voiceboxLabel = voiceboxLabel;

    // Animate logo on intro. Technically viewDidLoad can be called many times so guard.
    if (!self.hasShownIntroAnimation) {
        self.voiceboxLabel.hidden = YES;
        [self showLogoAnimation];
    }
    self.hasShownIntroAnimation = YES;

    // Animate logo on tap, just for fun
    UITapGestureRecognizer* tapLogoGesture = [[UITapGestureRecognizer alloc] init];
    [tapLogoGesture addTarget:self action:@selector(showLogoAnimation)];
    [voiceboxLabel addGestureRecognizer:tapLogoGesture];
    voiceboxLabel.userInteractionEnabled = YES;

    UIButton* clearTextButton = [UIButton buttonWithType:UIButtonTypeClose];
    // scale for more accessible tap target
    clearTextButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.5, 1.5);
    clearTextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [clearTextButton addTarget:self action:@selector(clearText:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:clearTextButton];
    _clearTextButton = clearTextButton;

    VBButton* speakButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"person.wave.2.fill" andTitle:@"Speak"];
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

    UILayoutGuide* buttonBottomSpacer = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:buttonBottomSpacer];

    const float buttonWidth = 164.0;
    const float buttonHeight = buttonWidth;
    const float topPadding = 10.0;
    const float bottomPadding = -20.0;

    // Layout

    // set the exact height of the buttons, but make it a weak constraint so they shrink to fit if needed
    NSLayoutConstraint* weakSpeakButtonHeightConstraint = [speakButton.heightAnchor constraintEqualToConstant:buttonHeight];
    [weakSpeakButtonHeightConstraint setPriority:UILayoutPriorityDefaultLow];
    NSLayoutConstraint* weakMagicButtonHeightConstraint = [magicButton.heightAnchor constraintEqualToConstant:buttonHeight];
    [weakMagicButtonHeightConstraint setPriority:UILayoutPriorityDefaultLow];

    NSArray<NSLayoutConstraint*>* constraints = @[
        // Logo
        [voiceboxLabel.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor
                                                constant:8.0],
        [voiceboxLabel.centerXAnchor constraintEqualToAnchor:textView.centerXAnchor],

        // Text View
        [textView.topAnchor constraintEqualToAnchor:voiceboxLabel.bottomAnchor
                                           constant:8.0],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor
                                              constant:bottomPadding],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],

        // Clear text button
        [clearTextButton.bottomAnchor constraintEqualToAnchor:textView.bottomAnchor
                                                     constant:-32.0],
        [clearTextButton.trailingAnchor constraintEqualToAnchor:textView.trailingAnchor
                                                       constant:-32.0],

        // Speak button
        [speakButton.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor
                                              constant:topPadding],
        [speakButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [speakButton.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:textView.trailingAnchor
                                                                  multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE],
        [speakButton.widthAnchor constraintEqualToConstant:buttonWidth],
        weakSpeakButtonHeightConstraint,

        // Magic button
        [magicButton.topAnchor constraintEqualToSystemSpacingBelowAnchor:speakButton.bottomAnchor
                                                              multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE],
        [magicButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [magicButton.widthAnchor constraintEqualToConstant:buttonWidth],
        weakMagicButtonHeightConstraint,

        // Ensure buttons are equal height. If they do shrink, they should match.
        [speakButton.heightAnchor constraintEqualToAnchor:magicButton.heightAnchor],

        // Button spacer, grows to prevent buttons from stretching vertically
        [buttonBottomSpacer.topAnchor constraintEqualToAnchor:magicButton.bottomAnchor],
        [buttonBottomSpacer.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor
                                                        constant:bottomPadding],
    ];

    [NSLayoutConstraint activateConstraints:constraints];

    [textView becomeFirstResponder];
}

- (void)clearText:(UIButton*)sender
{
    self.textView.text = @"";
    [self updateButtonStates];
}

- (void)speakText:(UIButton*)sender
{
    NSString* textToSpeak = self.textView.text;
    [self.speechSynthesizer speak:textToSpeak];
}

- (void)enhanceText:(UIButton*)sender
{
    VBEnhanceViewController* enhanceVc = [[VBEnhanceViewController alloc] init];
    enhanceVc.modalPresentationStyle = UIModalPresentationPageSheet;
    enhanceVc.selectionDelegate = self;
    [self presentViewController:enhanceVc animated:YES completion:nil];

    // Load suggestions from the great ML in the cloud
    NSString* fullText = self.textView.text;
    [self.enhancer enhance:fullText
                onComplete:^(NSArray* _Nonnull options, NSError* _Nonnull error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error || options.count == 0) {
                            // TODO: user visible error handling
                            [enhanceVc dismissViewControllerAnimated:YES completion:nil];
                            return;
                        }
                        [enhanceVc showOptions:options];
                    });
                }];
}

- (void)updateButtonStates
{
    BOOL hasText = self.textView.text.length > 0;
    self.speakButton.enabled = hasText;
    self.magicButton.enabled = hasText;
    self.clearTextButton.hidden = !hasText;
}

- (void)showLogoAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView transitionWithView:self.voiceboxLabel
                          duration:0.4
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{
                            self.voiceboxLabel.hidden = NO;
                        }
                        completion:nil];
    });
}

const float logoFontSize = 38.0;

- (NSAttributedString*)logoLabelAttributedString
{
    // UIFontWeightLight
    NSMutableAttributedString* logoString = [[NSMutableAttributedString alloc] initWithString:@"voicebox" attributes:@{ NSFontAttributeName : [self logoFontOfWeight:UIFontWeightLight] }];

    // Make "voice" semibold
    [logoString addAttribute:NSFontAttributeName value:[self logoFontOfWeight:UIFontWeightSemibold] range:NSMakeRange(0, 5)];

    return logoString;
}

- (UIFont*)logoFontOfWeight:(UIFontWeight)weight
{
    // weird trick needed to get SF Pro Rounded
    UIFont* systemFont = [UIFont systemFontOfSize:logoFontSize weight:weight];
    UIFontDescriptor* sfRoundedFontDescriptor = [systemFont.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    UIFont* roundedSystemFont = [UIFont fontWithDescriptor:sfRoundedFontDescriptor size:logoFontSize];
    return roundedSystemFont ? roundedSystemFont : systemFont;
}

#pragma - mark UITextViewDelegate

- (void)textViewDidChange:(UITextView*)textView
{
    [self updateButtonStates];
}

#pragma - mark EnhanceViewSelectionDelegate

- (void)didSelectEnhanceOption:(VBMagicEnhancerOption*)selectedOption
{
    self.textView.text = selectedOption.replacementText;
}

@end
