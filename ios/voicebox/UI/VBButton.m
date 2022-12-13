//
//  VBButton.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBButton.h"

#import "Constants.h"

@implementation VBButton

-(instancetype)initLargeSymbolButtonWithSystemImageNamed:(NSString*)systemImageName andTitle:(NSString*)title {
    self = [super init];
    
    UIButtonConfiguration* config = UIButtonConfiguration.filledButtonConfiguration;
    config.image = [UIImage systemImageNamed:systemImageName withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:32.0]];
    config.imagePlacement = NSDirectionalRectEdgeTop;
    config.imagePadding = 16.0;
    config.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:MAX([UIFont systemFontSize], 24.0)]}];
    config.background.backgroundColor = ACTION_BUTTON_UICOLOR;
    self.configuration = config;
    
    return self;
}

-(instancetype)initOptionButtonWithTitle:(NSString*)title {
    self = [super init];
    
    UIButtonConfiguration* config = UIButtonConfiguration.filledButtonConfiguration;
    config.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:MAX([UIFont systemFontSize], 24.0)]}];
    config.contentInsets = NSDirectionalEdgeInsetsMake(16, 16, 16, 16);
    config.background.backgroundColor = ACTION_BUTTON_UICOLOR;
    self.configuration = config;
    
    return self;
}

-(instancetype)initOptionCancelButton {
    self = [super init];
    
    UIButtonConfiguration* config = UIButtonConfiguration.grayButtonConfiguration;
    config.attributedTitle = [[NSAttributedString alloc] initWithString:@"Cancel" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:MAX([UIFont systemFontSize], 24.0)]}];
    config.contentInsets = NSDirectionalEdgeInsetsMake(16, 16, 16, 16);
    config.baseForegroundColor = ACTION_BUTTON_UICOLOR;
    self.configuration = config;
    
    return self;
}

@end
