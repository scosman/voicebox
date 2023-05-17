//
//  KeyboardTestViewController.m
//  Morse
//
//  Created by Steve Cosman on 2023-05-16.
//

#import "KeyboardTestViewController.h"

#import "VBButton.h"

@interface KeyboardKeyRow : NSObject

@property (nonatomic, strong) UIView* rowView;
@property (nonatomic, strong) NSArray<UIButton*>* buttons;

@end

@implementation KeyboardKeyRow
@end

@interface KeyboardTestViewController ()

@end

@implementation KeyboardTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#define KEY_HEIGHT_MULTI 0.15
#define BTN_SPACE 20

-(NSArray<TestClassDefinition*>*) buildKeyboardInView:(UIView*)keyboardContainer {
    UIButton* spaceButton = [[VBButton alloc] initKeyboardButton];
    spaceButton.translatesAutoresizingMaskIntoConstraints = NO;
    [keyboardContainer addSubview:spaceButton];
    
    
    KeyboardKeyRow* numbersRow = [self buildRowWithNumKeys:11 forContainer:keyboardContainer];
    KeyboardKeyRow* firstLetterRow = [self buildRowWithNumKeys:10 forContainer:keyboardContainer];
    KeyboardKeyRow* secondLetterRow = [self buildRowWithNumKeys:9 forContainer:keyboardContainer];
    KeyboardKeyRow* thirdLetterRow = [self buildRowWithNumKeys:8 forContainer:keyboardContainer];
    
    NSArray<NSLayoutConstraint*>* constraints = @[
        // Space
        [spaceButton.bottomAnchor constraintEqualToAnchor:keyboardContainer.layoutMarginsGuide.bottomAnchor constant:-10],
        [spaceButton.widthAnchor constraintEqualToAnchor:keyboardContainer.widthAnchor multiplier:0.5],
        [spaceButton.heightAnchor constraintEqualToAnchor:keyboardContainer.heightAnchor multiplier:KEY_HEIGHT_MULTI],
        [spaceButton.centerXAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor],
        
        // Third Row
        [thirdLetterRow.rowView.centerXAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor],
        [thirdLetterRow.rowView.bottomAnchor constraintEqualToAnchor:spaceButton.topAnchor constant:-BTN_SPACE],
        [thirdLetterRow.rowView.widthAnchor constraintEqualToAnchor:keyboardContainer.widthAnchor],
        [thirdLetterRow.rowView.heightAnchor constraintEqualToAnchor:spaceButton.heightAnchor],
        
        // Second Row
        [secondLetterRow.rowView.centerXAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor],
        [secondLetterRow.rowView.bottomAnchor constraintEqualToAnchor:thirdLetterRow.rowView.topAnchor constant:-BTN_SPACE],
        [secondLetterRow.rowView.widthAnchor constraintEqualToAnchor:keyboardContainer.widthAnchor],
        [secondLetterRow.rowView.heightAnchor constraintEqualToAnchor:spaceButton.heightAnchor],
        
        // First Row
        [firstLetterRow.rowView.centerXAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor],
        [firstLetterRow.rowView.bottomAnchor constraintEqualToAnchor:secondLetterRow.rowView.topAnchor constant:-BTN_SPACE],
        [firstLetterRow.rowView.widthAnchor constraintEqualToAnchor:keyboardContainer.widthAnchor],
        [firstLetterRow.rowView.heightAnchor constraintEqualToAnchor:spaceButton.heightAnchor],
        
        // Number Row
        [numbersRow.rowView.centerXAnchor constraintEqualToAnchor:keyboardContainer.centerXAnchor],
        [numbersRow.rowView.bottomAnchor constraintEqualToAnchor:firstLetterRow.rowView.topAnchor constant:-BTN_SPACE],
        [numbersRow.rowView.widthAnchor constraintEqualToAnchor:keyboardContainer.widthAnchor],
        [numbersRow.rowView.heightAnchor constraintEqualToAnchor:spaceButton.heightAnchor multiplier:0.7],
    ];
    [NSLayoutConstraint activateConstraints:constraints];
    
    TestClassDefinition* spaceTestClass = [[TestClassDefinition alloc] init];
    spaceTestClass.testClassName = @"Space Key";
    spaceTestClass.letterButtons = @[spaceButton];
    spaceTestClass.probabilityOfClassRepeat = 0.0;
    
    TestClassDefinition* deleteTestClass = [[TestClassDefinition alloc] init];
    deleteTestClass.testClassName = @"Delete Key";
    deleteTestClass.letterButtons = @[numbersRow.buttons.lastObject];
    deleteTestClass.probabilityOfClassRepeat = 0.15;
    
    TestClassDefinition* numbersKeys = [[TestClassDefinition alloc] init];
    numbersKeys.testClassName = @"Numbers Keys";
    NSArray* numberKeys = [numbersRow.buttons subarrayWithRange:NSMakeRange(0, 10)];
    numbersKeys.letterButtons = numberKeys;
    numbersKeys.probabilityOfClassRepeat = 0.6;

    
    TestClassDefinition* letterKeys = [[TestClassDefinition alloc] init];
    letterKeys.testClassName = @"Letter Keys";
    NSMutableArray* letterButtons = [[NSMutableArray alloc] init];
    [letterButtons addObjectsFromArray:thirdLetterRow.buttons];
    [letterButtons addObjectsFromArray:secondLetterRow.buttons];
    [letterButtons addObjectsFromArray:firstLetterRow.buttons];
    letterKeys.letterButtons = letterButtons;
    letterKeys.probabilityOfClassRepeat = 0.80;
    
    // Weighted probability of next "word" type
    spaceTestClass.weightedProbabilityOfNextClass = 20;
    deleteTestClass.weightedProbabilityOfNextClass = 4;
    numbersKeys.weightedProbabilityOfNextClass = 3;
    letterKeys.weightedProbabilityOfNextClass = 30;
    
    return @[
        spaceTestClass, deleteTestClass, numbersKeys, letterKeys
    ];
}

-(KeyboardKeyRow*) buildRowWithNumKeys:(int)count forContainer:(UIView*)keyboardContainer {
    NSAssert(count >= 2, @"rows must have 2+ buttons... because below");
    KeyboardKeyRow* kbRow = [[KeyboardKeyRow alloc] init];
    
    NSMutableArray<UIButton*>* buttons = [[NSMutableArray alloc] init];
    
    UIView* rowView = [[UIView alloc] init];
    [keyboardContainer addSubview:rowView];
    rowView.translatesAutoresizingMaskIntoConstraints = NO;
    kbRow.rowView = rowView;
    
    NSArray<NSLayoutConstraint*>* constraints = @[];
    
    for (int i = 0; i < count; i++) {
        UIButton* btn = [[VBButton alloc] initKeyboardButton];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [rowView addSubview:btn];
        
        if (buttons.count > 0) {
            constraints = [constraints arrayByAddingObject:[btn.leftAnchor constraintEqualToAnchor:buttons.lastObject.rightAnchor constant:BTN_SPACE]];
        }
        
        constraints = [constraints arrayByAddingObjectsFromArray:@[
            [btn.bottomAnchor constraintEqualToAnchor:rowView.bottomAnchor],
            [btn.widthAnchor constraintEqualToAnchor:keyboardContainer.heightAnchor multiplier:KEY_HEIGHT_MULTI],
            [btn.heightAnchor constraintEqualToAnchor:rowView.heightAnchor],
        ]];
        
        [buttons addObject:btn];
    }
    
    /*UIButton* lastBtn = [[VBButton alloc] initKeyboardButton];
    lastBtn.translatesAutoresizingMaskIntoConstraints = NO;

    [rowView addSubview:lastBtn];
    
    constraints = [constraints arrayByAddingObjectsFromArray:@[
        [lastBtn.bottomAnchor constraintEqualToAnchor:rowView.bottomAnchor],
        [lastBtn.leftAnchor constraintEqualToAnchor:buttons.lastObject.rightAnchor constant:BTN_SPACE],
        [lastBtn.widthAnchor constraintEqualToAnchor:keyboardContainer.heightAnchor multiplier:KEY_HEIGHT_MULTI],
        [lastBtn.heightAnchor constraintEqualToAnchor:rowView.heightAnchor],
    ]];
    
    [buttons addObject:btn];*/
    
    UILayoutGuide *leftSpace = [[UILayoutGuide alloc] init];
    [keyboardContainer addLayoutGuide:leftSpace];
    UILayoutGuide *rightSpace = [[UILayoutGuide alloc] init];
    [keyboardContainer addLayoutGuide:rightSpace];
    
    constraints = [constraints arrayByAddingObjectsFromArray:@[
        [leftSpace.leftAnchor constraintEqualToAnchor:rowView.leftAnchor],
        [buttons.firstObject.leftAnchor constraintEqualToAnchor:leftSpace.rightAnchor],
        [rightSpace.rightAnchor constraintEqualToAnchor:rowView.rightAnchor],
        [buttons.lastObject.rightAnchor constraintEqualToAnchor:rightSpace.leftAnchor],
        [leftSpace.widthAnchor constraintEqualToAnchor:rightSpace.widthAnchor]
    ]];
    
     [NSLayoutConstraint activateConstraints:constraints];
    
    
    
    kbRow.buttons = buttons;
    return kbRow;
}


@end
