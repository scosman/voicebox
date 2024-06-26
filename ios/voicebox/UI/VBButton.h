//
//  VBButton.h
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VBButton : UIButton

- (instancetype)initLargeSymbolButtonWithSystemImageNamed:(NSString*)systemImageName andTitle:(NSString*)title;

- (instancetype)initOptionButtonWithTitle:(NSString*)title hasSuboptions:(bool)hasSuboptions;
- (instancetype)initSecondaryButtonWithTitle:(NSString*)title;
- (instancetype)initOptionCancelButton;
- (instancetype)initKeyboardButton;

@end

NS_ASSUME_NONNULL_END
