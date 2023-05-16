//
//  BaseTestViewController.m
//  Morse
//
//  Created by Steve Cosman on 2023-05-15.
//

#import "BaseTestViewController.h"

#import "Constants.h"
#import "VBButton.h"

@interface TestRun : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*> *classNameToMissCount, *classNameToCorrectCount, *classNameToTotalSeekTime;
@property (nonatomic, strong) NSDate* startTime;


-(void) correctForTestClass:(NSString*)testClassName withTime:(NSTimeInterval)time;
-(void) missForForTestClass:(NSString*)testClassName withTime:(NSTimeInterval)time;

// per class
// int correct, misses
// float: total seek time (can get average from count)

@end

@implementation TestRun

-(instancetype)init {
    self = [super init];
    if (self) {
        _classNameToMissCount = [[NSMutableDictionary alloc] init];
        _classNameToCorrectCount = [[NSMutableDictionary alloc] init];
        _classNameToTotalSeekTime = [[NSMutableDictionary alloc] init];
        _startTime = [NSDate date];
    }
    return self;
}

-(void) correctForTestClass:(NSString*)testClassName withTime:(NSTimeInterval)time{
    NSNumber* correctCount = _classNameToCorrectCount[testClassName];
    if (correctCount) {
        correctCount = @(correctCount.intValue+1);
    } else {
        correctCount = @1;
    }
    _classNameToCorrectCount[testClassName] = correctCount;
    [self addSeekTimeForTestClass:testClassName withTime:time];
}

-(void) missForForTestClass:(NSString*)testClassName withTime:(NSTimeInterval)time {
    NSNumber* missCount = _classNameToMissCount[testClassName];
    if (missCount) {
        missCount = @(missCount.intValue+1);
    } else {
        missCount = @1;
    }
    _classNameToMissCount[testClassName] = missCount;
    [self addSeekTimeForTestClass:testClassName withTime:time];
}

-(void) addSeekTimeForTestClass:(NSString*)testClassName withTime:(NSTimeInterval)time {
    NSNumber* totalTime = _classNameToTotalSeekTime[testClassName];
    if (totalTime) {
        totalTime = @(totalTime.doubleValue + time);
    } else {
        totalTime = @(time);
    }
    _classNameToTotalSeekTime[testClassName] = totalTime;
}

@end

@implementation TestClassDefinition
@end

@interface BaseTestViewController ()

@property (nonatomic, strong) NSDictionary<NSString*, TestClassDefinition*>* testClassesByName;

@property (nonatomic, strong) TestRun* currentTestRun;
@property (nonatomic, strong) NSDate* currentTargetButtonSeekStartTime;

@property (nonatomic, weak) UILabel *instructions;
@property (nonatomic, weak) UIButton *startButton, *currentTestTarget, *pasteboardResultsBtn;
@property (nonatomic, strong) NSLayoutConstraint* landscapeHeightConstraint, *portraitHeighConstraint;

@end

@implementation BaseTestViewController

-(instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return  self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = APP_BACKGROUND_UICOLOR;
    
    UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeClose];
    //closeBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.5, 1.5);
    [closeBtn addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:closeBtn];
    
    UILabel* instructions = [[UILabel alloc] init];
    instructions.text = @"Hit each button as it lights up.\n\nThe test will continue for 1 minute.\n\nTry to be as quick as you can without making any mistakes.";
    instructions.numberOfLines = 0;
    instructions.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:30];
    instructions.textColor = BLACK_TEXT_UICOLOR;
    instructions.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:instructions];
    _instructions = instructions;
    
    UIButton* startBtn = [[VBButton alloc] initOptionButtonWithTitle:@"Start"];
    startBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [startBtn addTarget:self action:@selector(startTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startBtn];
    _startButton = startBtn;

    UIButton* copyResultsBtn = [[VBButton alloc] initOptionButtonWithTitle:@"Copy Results"];
    copyResultsBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [copyResultsBtn addTarget:self action:@selector(copyResults:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:copyResultsBtn];
    copyResultsBtn.hidden = YES;
    _pasteboardResultsBtn = copyResultsBtn;
    
    UIView* keyboardContainer = [[UIView alloc] init];
    keyboardContainer.backgroundColor = [UIColor systemGray3Color];
    keyboardContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:keyboardContainer];
    
    NSLayoutConstraint* landscapeHeightConstraint = [keyboardContainer.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.45];
    landscapeHeightConstraint.priority = 999;
    _landscapeHeightConstraint = landscapeHeightConstraint;
    NSLayoutConstraint* portraitHeighConstraint = [keyboardContainer.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.32];
    portraitHeighConstraint.priority = 999;
    _portraitHeighConstraint = portraitHeighConstraint;
    
    [self updateConstraintsFor:self.view.frame.size];
    
    NSArray<NSLayoutConstraint*>* constraints = @[
        // Close
        [closeBtn.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor constant:32],
        [closeBtn.rightAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.rightAnchor constant:-12],
        [closeBtn.heightAnchor constraintEqualToConstant:50],
        [closeBtn.widthAnchor constraintEqualToConstant:50],
        
        // Instructions
        [instructions.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor constant:85],
        [instructions.widthAnchor constraintEqualToConstant:620],
        [instructions.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        
        // Keyboard container
        [keyboardContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [keyboardContainer.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
        portraitHeighConstraint,
        landscapeHeightConstraint,
        
        // Start button
        [startBtn.topAnchor constraintEqualToAnchor:instructions.bottomAnchor constant:45],
        [startBtn.widthAnchor constraintEqualToConstant:320],
        [startBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        
        // Copy results button
        [copyResultsBtn.topAnchor constraintEqualToAnchor:instructions.bottomAnchor constant:45],
        [copyResultsBtn.widthAnchor constraintEqualToConstant:320],
        [copyResultsBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ];
    [NSLayoutConstraint activateConstraints:constraints];
    
    NSArray<TestClassDefinition*>* classes = [self buildKeyboardInView:keyboardContainer];
    NSMutableDictionary* classesByName = [[NSMutableDictionary alloc] init];
    for (TestClassDefinition* class in classes) {
        classesByName[class.testClassName] = class;
    }
    self.testClassesByName = classesByName;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateConstraintsFor:size];
}

-(void)updateConstraintsFor:(CGSize)size {
    if (size.width > size.height) {
        _portraitHeighConstraint.active = NO;
        _portraitHeighConstraint.priority = 1;
        _landscapeHeightConstraint.active = YES;
        _landscapeHeightConstraint.priority = 999;
        
    } else {
        _landscapeHeightConstraint.active = NO;
        _landscapeHeightConstraint.priority = 1;
        _portraitHeighConstraint.active = YES;
        _portraitHeighConstraint.priority = 999;
    }
    [self.view setNeedsLayout];
}

// Morse for now, but move to subclass
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
    CGFloat shortBtnHeight = 65;
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

-(void) closeTapped:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void) startTapped:(id)sender {
    _startButton.hidden = YES;
    _instructions.textAlignment = NSTextAlignmentCenter;
    
    // TODO -- remove shorcut
    /*dispatch_async(dispatch_get_main_queue(), ^{
        self->_instructions.text = @"\n\nGo go go!";
        [self startTest];
    });
    return;;*/
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 5; i > 0; i--) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_instructions.text = [NSString stringWithFormat:@"\n\nStarting in %d seconds", i];
            });
            [NSThread sleepForTimeInterval:1.0];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_instructions.text = @"\n\nGo go go!";
            [self startTest];
        });
    });
}

-(void) startTest {
    [self registerAllButtons];
    
    _currentTestRun = [[TestRun alloc] init];
    [self selectNextTestButton];
}

-(void) registerAllButtons {
    for (TestClassDefinition* testClass in self.testClassesByName.allValues) {
        for (UIButton* button in testClass.letterButtons) {
            if (button.allTargets.count == 0) {
                [button addTarget:self action:@selector(testButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            }
            // hacking accessibilityIdentifier in an accessibility app...
            button.accessibilityIdentifier = testClass.testClassName;
        }
    }
}

-(void) selectNextTestButton {
    // Deselect current
    if (_currentTestTarget) {
        UIButtonConfiguration* config = UIButtonConfiguration.grayButtonConfiguration;
        config.baseBackgroundColor = [UIColor systemGray6Color];
        _currentTestTarget.configuration = config;
    }
    
    NSTimeInterval timeSinceTestStart = -[_currentTestRun.startTime timeIntervalSinceNow];
    if (timeSinceTestStart > 60.0) {
        // Test is done!
        [self endTest];
        return;
    }
    
    // Next button
    
    // Should we continue with same class?
    TestClassDefinition* currentTestClass = self.testClassesByName[_currentTestTarget.accessibilityIdentifier];
    float rand = arc4random() % 10000 / 10000.0;
    TestClassDefinition* nextTestClass = nil;
    if (currentTestClass && rand < currentTestClass.probabilityOfClassRepeat) {
        // we should repeat from this class
        nextTestClass = currentTestClass;
    } else {
        // TODO -- new "word" random
        nextTestClass = [self newWordTestClass];
    }
    // Pick button from next class
    int buttonIndex = arc4random() % nextTestClass.letterButtons.count;
    _currentTestTarget = nextTestClass.letterButtons[buttonIndex];
    _currentTargetButtonSeekStartTime = [NSDate new];
    
    // highlight button
    UIButtonConfiguration* config = UIButtonConfiguration.grayButtonConfiguration;
    config.baseBackgroundColor = [UIColor greenColor];
    _currentTestTarget.configuration = config;
}

-(TestClassDefinition*) newWordTestClass {
    // pick next word class. Never this class, and then balance by weighted random
    NSString* currentClassName = _currentTestTarget.accessibilityIdentifier;
    TestClassDefinition* currentTestClass = self.testClassesByName[currentClassName];
    
    int totalWeighted = 0;
    for (TestClassDefinition* class in _testClassesByName.allValues) {
        if (currentTestClass != class) {
            totalWeighted += class.weightedProbabilityOfNextClass;
        }
    }
    int randLeft = arc4random() % totalWeighted;
    for (TestClassDefinition* class in _testClassesByName.allValues) {
        if (currentTestClass != class) {
            randLeft -= class.weightedProbabilityOfNextClass;
            if (randLeft < 0) {
                return class;
            }
        }
    }
    return _testClassesByName.allValues.lastObject;
}

-(void) testButtonTapped:(id)sender {
    if (!_currentTestRun) {
        return;
    }
    
    NSTimeInterval seekTime = -[_currentTargetButtonSeekStartTime timeIntervalSinceNow];
    if (sender == _currentTestTarget) {
        [_currentTestRun correctForTestClass:_currentTestTarget.accessibilityIdentifier withTime:seekTime];
    } else {
        [_currentTestRun missForForTestClass:_currentTestTarget.accessibilityIdentifier withTime:seekTime];
    }
    [self selectNextTestButton];
}

-(void) endTest {
    int hits = 0;
    for (NSNumber* h in _currentTestRun.classNameToCorrectCount.allValues) {
        hits += h.intValue;
    }
    int misses = 0;
    for (NSNumber* m in _currentTestRun.classNameToMissCount.allValues) {
        misses += m.intValue;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_instructions.text = [NSString stringWithFormat:@"\nTime up!\n\n%d hits\n%d misses", hits, misses];
        self->_pasteboardResultsBtn.hidden = NO;
    });
}

-(void) copyResults:(id)sender {
    NSDictionary* jsonStructure = @{
        @"testType": NSStringFromClass([self class]),
        @"hits": _currentTestRun.classNameToCorrectCount,
        @"misses": _currentTestRun.classNameToMissCount,
        @"seekTime": _currentTestRun.classNameToTotalSeekTime,
    };
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonStructure options:NSJSONWritingPrettyPrinted error:&err];

    NSLog(@"results = %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
    [UIPasteboard generalPasteboard].string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
