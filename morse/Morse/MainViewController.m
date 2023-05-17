//
//  ViewController.m
//  Morse
//
//  Created by Steve Cosman on 2023-05-15.
//

#import "MainViewController.h"

#import "MorseOneTestViewController.h"
#import "MorseTwoTestViewController.h"
#import "KeyboardTestViewController.h"
#import "Constants.h"
#import "VBButton.h"

#define BTN_WIDTH 380.0
#define BTN_space 42.0

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = APP_BACKGROUND_UICOLOR;
    
    UILayoutGuide *topSpace = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:topSpace];
    
    UILabel* titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Morse";
    titleLabel.numberOfLines = 1;
    titleLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:56];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    titleLabel.textColor = BLACK_TEXT_UICOLOR;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:titleLabel];
    
    UILabel* subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"__ ___ ._. ... .";
    subtitleLabel.numberOfLines = 1;
    subtitleLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:16];
    [subtitleLabel setTextAlignment:NSTextAlignmentCenter];
    subtitleLabel.textColor = BLACK_TEXT_UICOLOR;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:subtitleLabel];
    
    UILayoutGuide *buttonSpaceTop = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:buttonSpaceTop];
    
    UIButton* keyboardTestBtn = [[VBButton alloc] initOptionButtonWithTitle:@"26er Test"];
    keyboardTestBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:keyboardTestBtn];
    [keyboardTestBtn addTarget:self action:@selector(openKeyboardTest:) forControlEvents:UIControlEventTouchUpInside];
    
    UILayoutGuide *morseBtnSpaceTop = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:morseBtnSpaceTop];
    
    UIButton* morseOneTestBtn = [[VBButton alloc] initOptionButtonWithTitle:@"Morse One Test"];
    morseOneTestBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:morseOneTestBtn];
    [morseOneTestBtn addTarget:self action:@selector(openMorseOne:) forControlEvents:UIControlEventTouchUpInside];
    
    UILayoutGuide *morseTwoSpaceTop = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:morseTwoSpaceTop];
    
    UIButton* morseTwoTestBtn = [[VBButton alloc] initOptionButtonWithTitle:@"Morse Two Test"];
    morseTwoTestBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:morseTwoTestBtn];
    [morseTwoTestBtn addTarget:self action:@selector(openMorseTwo:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray<NSLayoutConstraint*>* constraints = @[
        // Top Space
        [topSpace.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [topSpace.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.18],
        
        // Title
        [titleLabel.topAnchor constraintEqualToAnchor:topSpace.bottomAnchor],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        
        // Subtitle
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:2],
        [subtitleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        
        // Top btn Space
        [buttonSpaceTop.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor],
        [buttonSpaceTop.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.15],
        
        // keyboard button
        [keyboardTestBtn.topAnchor constraintEqualToAnchor:buttonSpaceTop.bottomAnchor],
        [keyboardTestBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [keyboardTestBtn.widthAnchor constraintEqualToConstant:BTN_WIDTH],
        
        // Morse btn Space
        [morseBtnSpaceTop.topAnchor constraintEqualToAnchor:keyboardTestBtn.bottomAnchor],
        [morseBtnSpaceTop.heightAnchor constraintEqualToConstant:BTN_space],
        
        // morse button
        [morseOneTestBtn.topAnchor constraintEqualToAnchor:morseBtnSpaceTop.bottomAnchor],
        [morseOneTestBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [morseOneTestBtn.widthAnchor constraintEqualToConstant:BTN_WIDTH],
        
        // Morse 2 btn Space
        [morseTwoSpaceTop.topAnchor constraintEqualToAnchor:morseOneTestBtn.bottomAnchor],
        [morseTwoSpaceTop.heightAnchor constraintEqualToConstant:BTN_space],
        
        // Morse 2 button
        [morseTwoTestBtn.topAnchor constraintEqualToAnchor:morseTwoSpaceTop.bottomAnchor],
        [morseTwoTestBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [morseTwoTestBtn.widthAnchor constraintEqualToConstant:BTN_WIDTH],
    ];
    [NSLayoutConstraint activateConstraints:constraints];
}

-(void) openKeyboardTest:(id)sender {
    KeyboardTestViewController* kbvc = [[KeyboardTestViewController alloc] init];
    [self presentViewController:kbvc animated:YES completion:nil];
}

-(void) openMorseOne:(id)sender {
    MorseOneTestViewController* morseVc = [[MorseOneTestViewController alloc] init];
    [self presentViewController:morseVc animated:YES completion:nil];
}

-(void) openMorseTwo:(id)sender {
    MorseTwoTestViewController* morseVc = [[MorseTwoTestViewController alloc] init];
    [self presentViewController:morseVc animated:YES completion:nil];
}

-(void) openHawkins:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Coming soon"
                                   message:@"Hawkins is coming soon (ish)."
                                   preferredStyle:UIAlertControllerStyleAlert];
     
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
       handler:^(UIAlertAction * action) {}];
     
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
