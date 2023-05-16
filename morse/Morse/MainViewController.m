//
//  ViewController.m
//  Morse
//
//  Created by Steve Cosman on 2023-05-15.
//

#import "MainViewController.h"

#import "BaseTestViewController.h"
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
    
    UILayoutGuide *morseBtnSpaceTop = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:morseBtnSpaceTop];
    
    UIButton* morseTestBtn = [[VBButton alloc] initOptionButtonWithTitle:@"Morse Test"];
    morseTestBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:morseTestBtn];
    [morseTestBtn addTarget:self action:@selector(openMorse:) forControlEvents:UIControlEventTouchUpInside];
    
    UILayoutGuide *hawkinsBtnSpaceTop = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:hawkinsBtnSpaceTop];
    
    UIButton* hawkinsTestBtn = [[VBButton alloc] initOptionButtonWithTitle:@"Hawkins Test"];
    hawkinsTestBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hawkinsTestBtn];
    
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
        [morseTestBtn.topAnchor constraintEqualToAnchor:morseBtnSpaceTop.bottomAnchor],
        [morseTestBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [morseTestBtn.widthAnchor constraintEqualToConstant:BTN_WIDTH],
        
        // Hawkins btn Space
        [hawkinsBtnSpaceTop.topAnchor constraintEqualToAnchor:morseTestBtn.bottomAnchor],
        [hawkinsBtnSpaceTop.heightAnchor constraintEqualToConstant:BTN_space],
        
        // Hawkins button
        [hawkinsTestBtn.topAnchor constraintEqualToAnchor:hawkinsBtnSpaceTop.bottomAnchor],
        [hawkinsTestBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [hawkinsTestBtn.widthAnchor constraintEqualToConstant:BTN_WIDTH],
    ];
    [NSLayoutConstraint activateConstraints:constraints];
}

-(void) openMorse:(id)sender {
    BaseTestViewController* morseVc = [[BaseTestViewController alloc] init];
    [self presentViewController:morseVc animated:YES completion:nil];
}

@end
