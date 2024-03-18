//
//  ViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "MainViewController.h"

#import "../Util/VBStringUtils.h"
#import "Constants.h"
#import "ListenViewController.h"
#import "VBButton.h"
#import "VBEnhanceViewController.h"
#import "VBMagicEnhancer.h"
#import "VBShareViewController.h"
#import "VBSpeechSynthesizer.h"

@interface MainViewController () <UITextViewDelegate, EnhanceViewSelectionDelegate>

@property (nonatomic, weak) UITextView* textView;
@property (nonatomic, weak) UILabel* voiceboxLabel;
@property (nonatomic, weak) VBButton *speakButton, *magicButton, *listenButton;
@property (nonatomic, weak) UIButton *clearRestoreTextButton, *shareButton;
@property (nonatomic, strong) VBSpeechSynthesizer* speechSynthesizer;
@property (nonatomic, strong) VBMagicEnhancer* enhancer;
@property (nonatomic, strong) NSString* bodyBeforeLastTextboxClear;
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
    CGFloat textFontSize = IS_IPAD ? 38.0 : 24.0;
    textView.font = [UIFont systemFontOfSize:MAX([UIFont systemFontSize], textFontSize)];
    textView.textColor = BLACK_TEXT_UICOLOR;
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
    voiceboxLabel.textColor = BLACK_TEXT_UICOLOR;
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

    UIButton* clearRestoreTextButton = [UIButton buttonWithType:UIButtonTypeClose];
    // scale for more accessible tap target
    clearRestoreTextButton.transform = [self scaleTransformForClearButton:CGAffineTransformIdentity];
    clearRestoreTextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [clearRestoreTextButton addTarget:self action:@selector(clearRestoreText:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:clearRestoreTextButton];
    _clearRestoreTextButton = clearRestoreTextButton;

    const CGFloat shareButtonHeight = 46;
    UIButton* shareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [shareButton setTitle:@"     Share     " forState:UIControlStateNormal];
    shareButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    // match UIButtonTypeClose
    [shareButton setTitleColor:[UIColor colorWithRed:0.41 green:0.41 blue:0.41 alpha:1.0] forState:UIControlStateNormal];
    [shareButton setBackgroundColor:[UIColor colorWithRed:0.937254902 green:0.937254902 blue:0.937254902 alpha:1.0]];
    shareButton.layer.cornerRadius = shareButtonHeight / 2;
    shareButton.clipsToBounds = YES;
    shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    [shareButton addTarget:self action:@selector(shareText:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:shareButton];
    _shareButton = shareButton;

    VBButton* speakButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"person.wave.2.fill" andTitle:@"Speak"];
    speakButton.translatesAutoresizingMaskIntoConstraints = NO;
    [speakButton addTarget:self action:@selector(speakText:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:speakButton];
    _speakButton = speakButton;

    if (LISTEN_ENABLED) {
        VBButton* listenButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"ear" andTitle:@"Listen"];
        listenButton.translatesAutoresizingMaskIntoConstraints = NO;
        [listenButton addTarget:self action:@selector(launchListen:) forControlEvents:UIControlEventPrimaryActionTriggered];
        [self.view addSubview:listenButton];
        _listenButton = listenButton;
    }

    VBButton* magicButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"wand.and.stars" andTitle:@"Enhance"];
    magicButton.translatesAutoresizingMaskIntoConstraints = NO;
    [magicButton addTarget:self action:@selector(enhanceText:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:magicButton];
    _magicButton = magicButton;

    [self updateButtonStates];

    UILayoutGuide* buttonTopSpacer = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:buttonTopSpacer];
    UILayoutGuide* buttonBottomSpacer = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:buttonBottomSpacer];

    const float buttonWidth = IS_IPAD ? 164.0 : 100.0;
    const float buttonHeight = buttonWidth;
    const float bottomPadding = -20.0;

    // Layout

    // set the exact height of the buttons, but make it a weak constraint so they shrink to fit if needed
    NSLayoutConstraint* weakSpeakButtonHeightConstraint = [speakButton.heightAnchor constraintEqualToConstant:buttonHeight];
    [weakSpeakButtonHeightConstraint setPriority:UILayoutPriorityDefaultHigh];
    NSLayoutConstraint* weakListenButtonHeightConstraint = [_listenButton.heightAnchor constraintEqualToConstant:buttonHeight];
    [weakListenButtonHeightConstraint setPriority:UILayoutPriorityDefaultHigh];
    NSLayoutConstraint* weakMagicButtonHeightConstraint = [magicButton.heightAnchor constraintEqualToConstant:buttonHeight];
    [weakMagicButtonHeightConstraint setPriority:UILayoutPriorityDefaultHigh];
    // add some padding above the buttons so they align to textbox, but only if there's room
    NSLayoutConstraint* weakTopPaddingHeightConstraint = [buttonTopSpacer.heightAnchor constraintEqualToAnchor:voiceboxLabel.heightAnchor];
    [weakTopPaddingHeightConstraint setPriority:UILayoutPriorityDefaultLow];

    NSLayoutYAxisAnchor* magicTopAnchor = _listenButton.bottomAnchor ? _listenButton.bottomAnchor : speakButton.bottomAnchor;

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

        // Share button
        [shareButton.bottomAnchor constraintEqualToAnchor:textView.bottomAnchor
                                                 constant:-32.0],
        [shareButton.leadingAnchor constraintEqualToAnchor:textView.leadingAnchor
                                                  constant:32.0],
        [shareButton.heightAnchor constraintEqualToConstant:shareButtonHeight],

        // Clear text button
        [clearRestoreTextButton.bottomAnchor constraintEqualToAnchor:textView.bottomAnchor
                                                            constant:-32.0],
        [clearRestoreTextButton.trailingAnchor constraintEqualToAnchor:textView.trailingAnchor
                                                              constant:-32.0],

        // Space above speak button, space permitting with weak height constraint
        [buttonTopSpacer.topAnchor constraintEqualToAnchor:voiceboxLabel.topAnchor],
        weakTopPaddingHeightConstraint,

        // Speak button
        [speakButton.topAnchor constraintEqualToAnchor:buttonTopSpacer.bottomAnchor],
        [speakButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [speakButton.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:textView.trailingAnchor
                                                                  multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE],
        [speakButton.widthAnchor constraintEqualToConstant:buttonWidth],
        weakSpeakButtonHeightConstraint,

        // Magic button
        [magicButton.topAnchor constraintEqualToSystemSpacingBelowAnchor:magicTopAnchor
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

    // Listen is optional
    if (_listenButton) {
        constraints = [constraints arrayByAddingObjectsFromArray:@[
            // Listen button
            [_listenButton.topAnchor constraintEqualToSystemSpacingBelowAnchor:speakButton.bottomAnchor
                                                                    multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE],
            [_listenButton.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
            [_listenButton.widthAnchor constraintEqualToConstant:buttonWidth],
            weakListenButtonHeightConstraint,

            // Ensure buttons are equal height. If they do shrink, they should match.
            [_listenButton.heightAnchor constraintEqualToAnchor:magicButton.heightAnchor],
        ]];
    }

    [NSLayoutConstraint activateConstraints:constraints];

    [textView becomeFirstResponder];
}

- (void)clearRestoreText:(UIButton*)sender
{
    if (self.textView.text.length > 0) {
        // clear text if text view not empty. Save text so it can be restored.
        self.bodyBeforeLastTextboxClear = self.textView.text;
        self.textView.text = @"";
    } else if (self.bodyBeforeLastTextboxClear.length > 0) {
        // button is in "restore" mode, restore prior body text
        self.textView.text = self.bodyBeforeLastTextboxClear;
    }
    [self updateButtonStates];
}

- (void)shareText:(UIButton*)sender
{
    VBShareViewController* shareVC = [[VBShareViewController alloc] initWithContent:self.textView.text];
    shareVC.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:shareVC animated:YES completion:nil];
}

- (void)speakText:(UIButton*)sender
{
    NSString* textToSpeak = self.textView.text;
    [self.speechSynthesizer speak:textToSpeak];
}

- (void)launchListen:(UIButton*)sender
{
    ListenViewController* listenVc = [[ListenViewController alloc] init];
    listenVc.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:listenVc animated:YES completion:nil];
}

- (void)enhanceText:(UIButton*)sender
{
    VBEnhanceViewController* enhanceVc = [[VBEnhanceViewController alloc] init];
    enhanceVc.modalPresentationStyle = UIModalPresentationPageSheet;
    enhanceVc.selectionDelegate = self;
    [self presentViewController:enhanceVc animated:YES completion:nil];

    // Load suggestions from the great ML in the cloud
    NSString* fullText = self.textView.text;

    // These are for local testing during development
    BOOL uiDevelopment = false;
    BOOL parserDevelopment = false;
    if (uiDevelopment) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [enhanceVc showOptions:[OpenAiApiRequest developmentResponseOptions]];
        });
    } else if (parserDevelopment) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"rawResp" ofType:@"md"];
        NSString* rawMsg = [NSString stringWithContentsOfFile:path
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
        NSError* error;
        NSArray<ResponseOption*>* options = [OpenAiApiRequest processMessageString:rawMsg withError:&error];
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [enhanceVc showOptions:options];
            });
        }
    } else {
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
}

- (void)updateButtonStates
{
    BOOL hasText = self.textView.text.length > 0;
    self.speakButton.enabled = hasText;
    self.magicButton.enabled = hasText;
    self.shareButton.hidden = !hasText;

    // hide "clear" button if no text, and no text to restore
    BOOL canRestoreText = !hasText && self.bodyBeforeLastTextboxClear.length > 0;
    self.clearRestoreTextButton.hidden = !hasText && !canRestoreText;

    // rotate clear "X" into plus sign if button is in "restore" mode
    CGAffineTransform rotateTransform = CGAffineTransformIdentity;
    if (canRestoreText) {
        rotateTransform = CGAffineTransformMakeRotation(0.785398); // 45 degrees in rads
    }
    CGAffineTransform expectedTransform = [self scaleTransformForClearButton:rotateTransform];
    if (!CGAffineTransformEqualToTransform(self.clearRestoreTextButton.transform, expectedTransform)) {
        [UIView animateWithDuration:0.4
                         animations:^{
                             self.clearRestoreTextButton.transform = expectedTransform;
                         }];
    }
}

- (CGAffineTransform)scaleTransformForClearButton:(CGAffineTransform)ogTransform
{
    return CGAffineTransformScale(ogTransform, 1.5, 1.5);
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
    NSMutableAttributedString* logoString = [[NSMutableAttributedString alloc] initWithString:@"voicebox" attributes:@{ NSFontAttributeName : [VBStringUtils logoFontOfWeight:UIFontWeightLight withSize:logoFontSize] }];

    // Make "voice" semibold
    [logoString addAttribute:NSFontAttributeName value:[VBStringUtils logoFontOfWeight:UIFontWeightSemibold withSize:logoFontSize] range:NSMakeRange(0, 5)];

    return logoString;
}

#pragma - mark UITextViewDelegate

- (void)textViewDidChange:(UITextView*)textView
{
    self.bodyBeforeLastTextboxClear = nil;
    [self updateButtonStates];
}

#pragma - mark EnhanceViewSelectionDelegate

- (void)didSelectEnhanceOption:(ResponseOption*)selectedOption
{
    self.textView.text = selectedOption.fullBodyReplacement;
}

@end
