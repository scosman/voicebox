//
//  BaseTestViewController.h
//  Morse
//
//  Created by Steve Cosman on 2023-05-15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestClassDefinition : NSObject

@property (nonatomic, strong) NSString* testClassName;
@property (nonatomic, strong) NSArray<UIButton*>* letterButtons;
@property (nonatomic) float probabilityOfClassRepeat;
@property (nonatomic) int weightedProbabilityOfNextClass;

@end

@interface BaseTestViewController : UIViewController

// Override this in subclasses
-(NSArray<TestClassDefinition*>*) buildKeyboardInView:(UIView*)keyboardContainer;

@end

NS_ASSUME_NONNULL_END
