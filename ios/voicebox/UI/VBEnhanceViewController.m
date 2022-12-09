//
//  EnhanceViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-06.
//

#import "VBEnhanceViewController.h"

#import "Constants.h"
#import "VBButton.h"

@interface VBEnhanceViewController ()

@property (nonatomic, strong) NSArray<NSString*> *options, *optionsLoadedInView;
@property (nonatomic, weak) UILabel* loadingLabel;
@property (nonatomic, weak) UIActivityIndicatorView* spinner;
@property (nonatomic, weak) UIButton* closeBtn;
@property (nonatomic, weak) UIView* optionsStackView;

@end

@implementation VBEnhanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:spinner];
    _spinner = spinner;
    
    UILabel* loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = [self randomLoadingLabel];
    loadingLabel.font = [UIFont systemFontOfSize:MAX(18.0, [UIFont systemFontSize])];
    loadingLabel.textColor = [UIColor systemGrayColor];
    loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:loadingLabel];
    _loadingLabel = loadingLabel;
    
    // TODO -- bigger, more accessible!
    UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeClose];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:closeBtn];
    _closeBtn = closeBtn;
    
    UIView* optionsStackView = [[UIView alloc] init];
    optionsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:optionsStackView];
    _optionsStackView = optionsStackView;
    
    NSArray* constraints = @[
        // Loading Content
        [spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [loadingLabel.topAnchor constraintEqualToSystemSpacingBelowAnchor:spinner.bottomAnchor multiplier:1.0],
        [loadingLabel.centerXAnchor constraintEqualToAnchor:spinner.centerXAnchor],
        
        // Close button
        [closeBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-22.0],
        [closeBtn.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:22.0],
        
        // Main content area
        [optionsStackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [optionsStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [optionsStackView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.8],
        [optionsStackView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.95],
    ];
    [NSLayoutConstraint activateConstraints:constraints];
    
    [self updateState];
}

-(void) closeButtonAction:(UIButton*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void) selectOptionAction:(UIButton*)sender {
    // TODO: passing content strings via button label? ugh.
    NSString* selectedEnhancedContent = sender.titleLabel.text;
    [self.selectionDelegate didSelectEnhanceOption:selectedEnhancedContent];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) showOptions:(NSArray<NSString*>*)options {
    _options = options;
    [self updateState];
}

-(void) updateOptionsButtons {
    NSArray<NSString*>* options = _options;
    
    @synchronized (self) {
        if (options == _optionsLoadedInView) {
            return;
        }
        _optionsLoadedInView = options;
    }
    
    // remove old options
    for (UIView* oldView in _optionsStackView.subviews) {
        [oldView removeFromSuperview];
    }
    
    NSMutableArray* constraints = [[NSMutableArray alloc] initWithCapacity:(options.count*2 + 3)];
    NSLayoutYAxisAnchor* topAnchor = _optionsStackView.topAnchor;
    
    for (NSString* option in options) {
        VBButton* optionButton = [[VBButton alloc] initOptionButtonWithTitle:option];
        optionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_optionsStackView addSubview:optionButton];
        [optionButton addTarget:self action:@selector(selectOptionAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
        
        [constraints addObjectsFromArray:@[
            [optionButton.topAnchor constraintLessThanOrEqualToSystemSpacingBelowAnchor:topAnchor multiplier:ACCESSIBLE_SYSTEM_SPACING_MULTIPLE],
            [optionButton.widthAnchor constraintEqualToAnchor:_optionsStackView.widthAnchor]
        ]];
        
        topAnchor = optionButton.bottomAnchor;
    }
    
    
    VBButton* cancelBtn = [[VBButton alloc] initOptionCancelButton];
    cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_optionsStackView addSubview:cancelBtn];
    [cancelBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [constraints addObjectsFromArray:@[
        [cancelBtn.bottomAnchor constraintEqualToAnchor:_optionsStackView.bottomAnchor constant:-24.0],
        [cancelBtn.widthAnchor constraintEqualToConstant:300.0],
        [cancelBtn.centerXAnchor constraintEqualToAnchor:_optionsStackView.centerXAnchor],
    ]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

-(void) updateState {
    if (!_options) {
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
}

-(NSString*) randomLoadingLabel {
    NSArray* const labelOptions = @[
        @"Working our magic...",
        @"Enhance, enhance, enhance...",
        @"Magic incoming...",
        @"Talking to the machines...",
        @"Calling an intern, one sec...",
        @"Making stuff up..."
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
