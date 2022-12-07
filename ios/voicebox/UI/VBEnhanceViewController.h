//
//  EnhanceViewController.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EnhanceViewSelectionDelegate <NSObject>
- (void)didSelectEnhanceOption:(NSString *)selectedOption;
@end

@interface VBEnhanceViewController : UIViewController

@property (nonatomic, weak) id<EnhanceViewSelectionDelegate> selectionDelegate;

-(void) showOptions:(NSArray<NSString*>*)options;

@end

NS_ASSUME_NONNULL_END
