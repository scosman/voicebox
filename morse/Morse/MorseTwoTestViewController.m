//
//  MorseTestViewController.m
//  Morse
//
//  Created by Steve Cosman on 2023-05-16.
//

#import "MorseTwoTestViewController.h"
#import "VBButton.h"

@interface MorseTwoTestViewController ()

@end

@implementation MorseTwoTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(NSArray<TestClassDefinition*>*) buildKeyboardInView:(UIView*)keyboardContainer {
    UIButton* spaceButton = [[VBButton alloc] initKeyboardButton];
    spaceButton.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:spaceButton];
    
    UIButton* deleteButton = [[VBButton alloc] initKeyboardButton];
    deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:deleteButton];
    
    UIButton* modesButton = [[VBButton alloc] initKeyboardButton];
    modesButton.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:modesButton];
    
    UIButton* quickKeyButton = [[VBButton alloc] initKeyboardButton];
    quickKeyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:quickKeyButton];
    
    UIButton* morseButton1 = [[VBButton alloc] initKeyboardButton];
    morseButton1.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:morseButton1];
    
    UIButton* morseButton2 = [[VBButton alloc] initKeyboardButton];
    morseButton2.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:morseButton2];
    
    //morseButton2.configuration = [UIButtonConfiguration filledButtonConfiguration];
    
    CGFloat padding = 25;
    CGFloat centerPadding = 13;
    CGFloat topPadding = 10;
    CGFloat shortBtnHeight = 75;
    NSArray<NSLayoutConstraint*>* constraints = @[
        // Space
        [spaceButton.bottomAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.bottomAnchor constant:-padding],
        [spaceButton.rightAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.rightAnchor constant:-padding],
        [spaceButton.leftAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:centerPadding],
        [spaceButton.heightAnchor constraintEqualToConstant:shortBtnHeight],
        
        // Quick Key
        [quickKeyButton.bottomAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.bottomAnchor constant:-padding],
        [quickKeyButton.leftAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.leftAnchor constant:padding],
        [quickKeyButton.rightAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:-centerPadding],
        [quickKeyButton.heightAnchor constraintEqualToConstant:shortBtnHeight],
        
        // Delete Key
        [deleteButton.topAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.topAnchor constant:topPadding],
        [deleteButton.rightAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.rightAnchor constant:-padding],
        [deleteButton.leftAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:centerPadding],
        [deleteButton.heightAnchor constraintEqualToConstant:shortBtnHeight],
        
        // Modes Key
        [modesButton.topAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.topAnchor constant:topPadding],
        [modesButton.leftAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.leftAnchor constant:padding],
        [modesButton.rightAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:-centerPadding],
        [modesButton.heightAnchor constraintEqualToConstant:shortBtnHeight],
        
        // morse button 1
        [morseButton1.topAnchor constraintEqualToAnchor:modesButton.bottomAnchor constant:padding],
        [morseButton1.bottomAnchor constraintEqualToAnchor:quickKeyButton.topAnchor constant:-padding],
        [morseButton1.leftAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.leftAnchor constant:padding],
        [morseButton1.rightAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:-centerPadding],
        
        // morse button 2
        [morseButton2.topAnchor constraintEqualToAnchor:modesButton.bottomAnchor constant:padding],
        [morseButton2.bottomAnchor constraintEqualToAnchor:quickKeyButton.topAnchor constant:-padding],
        [morseButton2.rightAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.rightAnchor constant:-padding],
        [morseButton2.leftAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor constant:centerPadding],
        
    ];
    [NSLayoutConstraint activateConstraints:constraints];
    
    TestClassDefinition* spaceTestClass = [[TestClassDefinition alloc] init];
    spaceTestClass.testClassName = @"Space Key";
    spaceTestClass.letterButtons = @[spaceButton];
    spaceTestClass.probabilityOfClassRepeat = 0.0;
    
    TestClassDefinition* deleteTestClass = [[TestClassDefinition alloc] init];
    deleteTestClass.testClassName = @"Delete Key";
    deleteTestClass.letterButtons = @[deleteButton];
    deleteTestClass.probabilityOfClassRepeat = 0.02;
    
    TestClassDefinition* quickKeyClass = [[TestClassDefinition alloc] init];
    quickKeyClass.testClassName = @"Quick Key";
    quickKeyClass.letterButtons = @[quickKeyButton];
    quickKeyClass.probabilityOfClassRepeat = 0.0;
    
    TestClassDefinition* modesClass = [[TestClassDefinition alloc] init];
    modesClass.testClassName = @"Modes Key";
    modesClass.letterButtons = @[modesButton];
    modesClass.probabilityOfClassRepeat = 0.0;
    
    TestClassDefinition* morseClass = [[TestClassDefinition alloc] init];
    morseClass.testClassName = @"Morse Keys";
    morseClass.letterButtons = @[morseButton1, morseButton2];
    morseClass.probabilityOfClassRepeat = 0.80;
    
    // Weighted probability of next "word" type
    spaceTestClass.weightedProbabilityOfNextClass = 20;
    deleteTestClass.weightedProbabilityOfNextClass = 4;
    quickKeyClass.weightedProbabilityOfNextClass = 2;
    modesClass.weightedProbabilityOfNextClass = 1;
    morseClass.weightedProbabilityOfNextClass = 30;
    
    return @[
        spaceTestClass, deleteTestClass, quickKeyClass, modesClass, morseClass
    ];
}

@end
