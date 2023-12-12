//
//  EnhanceViewController.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import <UIKit/UIKit.h>

#import "VBMagicEnhancer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EnhanceViewSelectionDelegate <NSObject>
- (void)didSelectEnhanceOption:(ResponseOption*)selectedOption;
@end

@interface VBEnhanceViewController : UIViewController

@property (nonatomic, weak) id<EnhanceViewSelectionDelegate> selectionDelegate;

- (void)showOptions:(NSArray<ResponseOption*>*)options;

@end

NS_ASSUME_NONNULL_END
