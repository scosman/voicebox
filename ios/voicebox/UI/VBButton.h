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

- (instancetype)initOptionButtonWithTitle:(NSString*)title;
- (instancetype)initOptionCancelButton;

@end

NS_ASSUME_NONNULL_END
