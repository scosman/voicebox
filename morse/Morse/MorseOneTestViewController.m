//
//  MorseTestViewController.m
//  Morse
//
//  Created by Steve Cosman on 2023-05-16.
//

#import "MorseOneTestViewController.h"
#import "VBButton.h"

@interface MorseOneTestViewController ()

@end

@implementation MorseOneTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(NSArray<TestClassDefinition*>*) buildKeyboardInView:(UIView*)keyboardContainer {
    UIButton* morseButton1 = [[VBButton alloc] initKeyboardButton];
    morseButton1.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:morseButton1];
    
    UIButton* morseButton2 = [[VBButton alloc] initKeyboardButton];
    morseButton2.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:morseButton2];
    
    CGFloat padding = 25;
    CGFloat centerPadding = 13;
    CGFloat topPadding = 10;
    CGFloat shortBtnHeight = 65;
    NSArray<NSLayoutConstraint*>* constraints = @[
        // morse button 1
        [morseButton1.topAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.topAnchor constant:topPadding],
        [morseButton1.bottomAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.bottomAnchor constant:-padding],
        [morseButton1.leftAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.leftAnchor constant:padding],
        [morseButton1.rightAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:-centerPadding],
        
        // morse button 2
        [morseButton2.topAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.topAnchor constant:topPadding],
        [morseButton2.bottomAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.bottomAnchor constant:-padding],
        [morseButton2.rightAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.rightAnchor constant:-padding],
        [morseButton2.leftAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:centerPadding],
        
    ];
    [NSLayoutConstraint activateConstraints:constraints];
        
    TestClassDefinition* morseClass = [[TestClassDefinition alloc] init];
    morseClass.testClassName = @"Morse Keys";
    morseClass.letterButtons = @[morseButton1, morseButton2];
    morseClass.probabilityOfClassRepeat = 1.01;
    
    // Weighted probability of next "word" type
    morseClass.weightedProbabilityOfNextClass = 30;
    
    return @[
        morseClass
    ];
}

@end
