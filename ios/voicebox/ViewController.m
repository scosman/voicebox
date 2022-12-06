//
//  ViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-05.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, weak) UITextView* textView;
@property (nonatomic, weak) UIButton *speakButton, *magicButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor greenColor];

    UITextView* textView = [[UITextView alloc] init];
    [self.view addSubview:textView];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView = textView;

    UIButton* speakButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [speakButton setTitle:@"Speak" forState:UIControlStateNormal];
    speakButton.backgroundColor = [UIColor orangeColor];
    speakButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:speakButton];
    _speakButton = speakButton;
    
    UIButton* magicButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [magicButton setTitle:@"Magic" forState:UIControlStateNormal];
    magicButton.backgroundColor = [UIColor orangeColor];
    magicButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:magicButton];
    _magicButton = magicButton;

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


@end
