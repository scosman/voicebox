//
//  EnhanceViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBEnhanceViewController.h"

#import "../Util/VBStringUtils.h"
#import "Constants.h"
#import "VBButton.h"

@interface VBEnhanceViewController ()

@property (nonatomic, strong) NSArray<ResponseOption*>*options, *optionsLoadedInView, *rootOptions;
@property (nonatomic, weak) UILabel *loadingLabel, *titleLabel;
@property (nonatomic, weak) UIActivityIndicatorView* spinner;
@property (nonatomic, weak) UIButton *closeBtn, *backBtn;
@property (nonatomic, weak) UIView* optionsStackView;

@end

@implementation VBEnhanceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = APP_BACKGROUND_UICOLOR;

    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:spinner];
    _spinner = spinner;

    UILabel* loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = [self randomLoadingLabel];
    loadingLabel.font = [UIFont systemFontOfSize:MAX(18.0, [UIFont labelFontSize])];
    loadingLabel.textColor = [UIColor systemGrayColor];
    loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:loadingLabel];
    _loadingLabel = loadingLabel;

    UILabel* titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.hidden = true;
    titleLabel.font = [VBStringUtils logoFontOfWeight:UIFontWeightBold withSize:(IS_IPAD ? 32 : 28)];
    [self.view addSubview:titleLabel];
    _titleLabel = titleLabel;

    UIButton* backBtn = [[VBButton alloc] initSecondaryButtonWithTitle:@" Back"];
    UIImage* backImg = [UIImage systemImageNamed:@"chevron.backward.circle.fill"];
    [backBtn setImage:backImg forState:UIControlStateNormal];
    backBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [backBtn addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:backBtn];
    _backBtn = backBtn;

    UIButton* closeBtn = [VBButton buttonWithType:UIButtonTypeClose];
    // scale for larger tap target
    closeBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.5, 1.5);
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:closeBtn];
    _closeBtn = closeBtn;

    UIView* optionsStackView = [[UIView alloc] init];
    optionsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:optionsStackView];
    _optionsStackView = optionsStackView;

    NSArray* constraints = @[
        // Title
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor
                                             constant:IS_IPAD ? 34.0 : 22.0],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        // Loading Content
        [spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [loadingLabel.topAnchor constraintEqualToSystemSpacingBelowAnchor:spinner.bottomAnchor
                                                               multiplier:1.0],
        [loadingLabel.centerXAnchor constraintEqualToAnchor:spinner.centerXAnchor],

        // Back button
        [backBtn.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor
                                              constant:22],
        [backBtn.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                          constant:22.0],

        // Close button
        [closeBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                constant:-22.0],
        [closeBtn.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                           constant:26.0],

        // Main content area
        [optionsStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [optionsStackView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor
                                                   multiplier:0.8],
        [optionsStackView.topAnchor constraintEqualToAnchor:backBtn.bottomAnchor],
        [optionsStackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                      constant:-15],
    ];
    [NSLayoutConstraint activateConstraints:constraints];

    [self updateState];
}

- (void)backButtonAction:(UIButton*)sender
{
    _options = _rootOptions;
    [self updateState];
}

- (void)closeButtonAction:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectOptionAction:(ResponseOption*)optionSelected
{
    if (optionSelected.hasSuboptions) {
        self.options = optionSelected.subOptions;
        [self updateState];
    } else {
        [self.selectionDelegate didSelectEnhanceOption:optionSelected];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showOptions:(NSArray<ResponseOption*>*)options
{
    _options = options;
    if (!_rootOptions) {
        _rootOptions = options;
    }
    [self updateState];
}

- (void)updateOptionsButtons
{
    NSArray<ResponseOption*>* options = _options;

    @synchronized(self) {
        if (options == _optionsLoadedInView) {
            return;
        }
        _optionsLoadedInView = options;
    }

    // remove old options
    for (UIView* oldView in _optionsStackView.subviews) {
        [oldView removeFromSuperview];
    }

    NSMutableArray* constraints = [[NSMutableArray alloc] initWithCapacity:(options.count * 2 + 8)];
    NSLayoutYAxisAnchor* topAnchor;

    BOOL allTopics = true;

    VBButton *topButton, *bottonButton;
    for (ResponseOption* option in options) {
        if (!option.hasSuboptions) {
            allTopics = false;
        }

        VBButton* optionButton = [[VBButton alloc] initOptionButtonWithTitle:option.displayName hasSuboptions:option.hasSuboptions];
        optionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_optionsStackView addSubview:optionButton];

        __weak VBEnhanceViewController* weakSelf = self;
        UIAction* buttonAction = [UIAction actionWithHandler:^(__kindof UIAction* _Nonnull action) {
            [weakSelf selectOptionAction:option];
        }];
        [optionButton addAction:buttonAction forControlEvents:UIControlEventPrimaryActionTriggered];

        [constraints addObject:[optionButton.widthAnchor constraintEqualToAnchor:_optionsStackView.widthAnchor]];

        if (topAnchor) {
            [constraints addObject:[optionButton.topAnchor constraintLessThanOrEqualToSystemSpacingBelowAnchor:topAnchor multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE]];
        }
        topAnchor = optionButton.bottomAnchor;

        if (!topButton) {
            topButton = optionButton;
        }
        bottonButton = optionButton;
    }

    if (allTopics) {
        _titleLabel.text = @"Select Topic";
        [_titleLabel sizeToFit];
    } else {
        _titleLabel.text = @"Select";
        [_titleLabel sizeToFit];
    }
    _titleLabel.hidden = options.count == 0;

    VBButton* cancelBtn = [[VBButton alloc] initOptionCancelButton];
    cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_optionsStackView addSubview:cancelBtn];
    [cancelBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [constraints addObjectsFromArray:@[
        [cancelBtn.bottomAnchor constraintEqualToAnchor:_optionsStackView.bottomAnchor
                                               constant:-24.0],
        [cancelBtn.widthAnchor constraintEqualToConstant:300.0],
        [cancelBtn.centerXAnchor constraintEqualToAnchor:_optionsStackView.centerXAnchor],
    ]];

    // center the set of buttons
    if (topButton && bottonButton) {
        UILayoutGuide* topSpaceGuide = [[UILayoutGuide alloc] init];
        [self.view addLayoutGuide:topSpaceGuide];
        UILayoutGuide* bottomSpaceGuide = [[UILayoutGuide alloc] init];
        [self.view addLayoutGuide:bottomSpaceGuide];
        [constraints addObjectsFromArray:@[
            // space at top and botton equal
            [topSpaceGuide.heightAnchor constraintEqualToAnchor:bottomSpaceGuide.heightAnchor],

            // Top spacing
            [topSpaceGuide.topAnchor constraintEqualToAnchor:_optionsStackView.topAnchor],
            [topButton.topAnchor constraintEqualToAnchor:topSpaceGuide.bottomAnchor],

            // Bottom spacing
            [bottomSpaceGuide.bottomAnchor constraintEqualToAnchor:cancelBtn.topAnchor],
            [bottonButton.bottomAnchor constraintEqualToAnchor:bottomSpaceGuide.topAnchor],
        ]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateState
{
    if (!_options || _options.count == 0) {
        [_spinner startAnimating];
        _spinner.hidden = NO;
        _loadingLabel.hidden = NO;
        _optionsStackView.hidden = YES;
    } else {
        [_spinner stopAnimating];
        _spinner.hidden = YES;
        _loadingLabel.hidden = YES;
        _optionsStackView.hidden = NO;
    }

    [self updateOptionsButtons];

    _backBtn.hidden = !(_options && _options != _rootOptions);
}

- (NSString*)randomLoadingLabel
{
    NSArray* const labelOptions = @[
        @"Working our magic...",
        @"Enhance, enhance, enhance...",
        @"Magic incoming...",
        @"Talking to the machines...",
        @"Calling an intern..."
    ];

    return labelOptions[arc4random() % labelOptions.count];
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
