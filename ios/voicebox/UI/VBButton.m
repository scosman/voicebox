//
//  VBButton.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBButton.h"

#import "Constants.h"

@interface VBButton ()

@property (nonatomic, strong) UIColor *backgroundColor, *disabledBgColor, *highlightBgColor;

@end

@implementation VBButton

- (instancetype)initLargeSymbolButtonWithSystemImageNamed:(NSString*)systemImageName andTitle:(NSString*)title
{
    self = [super init];

    UIButtonConfiguration* config = UIButtonConfiguration.filledButtonConfiguration;
    config.image = [UIImage systemImageNamed:systemImageName withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:28.0]];
    config.imagePlacement = NSDirectionalRectEdgeTop;
    config.imagePadding = 8.0;
    config.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:MAX([UIFont labelFontSize], 24.0)] }];
    self.configuration = config;

    [self setupStandardActionButtonColor];

    return self;
}

- (instancetype)initOptionButtonWithTitle:(NSString*)title
{
    self = [super init];

    UIButtonConfiguration* config = UIButtonConfiguration.filledButtonConfiguration;
    config.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:MAX([UIFont labelFontSize], 24.0)] }];
    config.contentInsets = NSDirectionalEdgeInsetsMake(16, 16, 16, 16);
    config.background.backgroundColor = ACTION_BUTTON_UICOLOR;
    self.configuration = config;

    [self setupStandardActionButtonColor];

    return self;
}

- (instancetype)initOptionCancelButton
{
    self = [super init];

    UIButtonConfiguration* config = UIButtonConfiguration.grayButtonConfiguration;
    config.attributedTitle = [[NSAttributedString alloc] initWithString:@"Cancel" attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:MAX([UIFont labelFontSize], 24.0)] }];
    config.contentInsets = NSDirectionalEdgeInsetsMake(16, 16, 16, 16);
    config.baseForegroundColor = ACTION_BUTTON_UICOLOR;
    self.configuration = config;

    return self;
}

- (void)setupStandardActionButtonColor
{
    self.backgroundColor = ACTION_BUTTON_UICOLOR;
    self.disabledBgColor = ACTION_BUTTON_DISABLED_UICOLOR;
    self.highlightBgColor = ACTION_BUTTON_HIGHLIGHT_UICOLOR;
    self.configurationUpdateHandler = [self actionButtonColorConfigUpdateHandler];
}

- (void (^)(UIButton*))actionButtonColorConfigUpdateHandler
{
    __weak VBButton* weakSelf = self;
    return ^(UIButton* button) {
        UIButtonConfiguration* config = button.configuration;

        if (!button.isEnabled) {
            config.background.backgroundColor = weakSelf.disabledBgColor;
        } else if (button.isHighlighted) {
            config.background.backgroundColor = weakSelf.highlightBgColor;
        } else {
            config.background.backgroundColor = weakSelf.backgroundColor;
        }

        button.configuration = config;
    };
    ;
}

@end
