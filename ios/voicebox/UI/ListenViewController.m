//
//  ListenViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-28.
//

#import "ListenViewController.h"

#import "Constants.h"
#import "VBAudioListener.h"

@interface ListenViewController () <VBAudioListenerDelegate>

@property (nonatomic, weak) UILabel *loadingLabel, *transcriptLabel;
@property (nonatomic, weak) UIActivityIndicatorView* spinner;
@property (nonatomic, weak) UIButton* closeBtn;

@end

@implementation ListenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = APP_BACKGROUND_UICOLOR;

    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:spinner];
    _spinner = spinner;
    [spinner startAnimating];

    UILabel* loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = @"Loading...";
    loadingLabel.font = [UIFont systemFontOfSize:MAX(18.0, [UIFont labelFontSize])];
    loadingLabel.textColor = [UIColor systemGrayColor];
    loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:loadingLabel];
    _loadingLabel = loadingLabel;

    UILabel* transcriptLabel = [[UILabel alloc] init];
    transcriptLabel.text = @"";
    transcriptLabel.font = [UIFont systemFontOfSize:MAX(22.0, [UIFont labelFontSize])];
    transcriptLabel.textColor = [UIColor systemGrayColor];
    transcriptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    transcriptLabel.lineBreakMode = NSLineBreakByWordWrapping;
    transcriptLabel.numberOfLines = 0;
    [self.view addSubview:transcriptLabel];
    _transcriptLabel = transcriptLabel;

    UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeClose];
    // scale for larger tap target
    closeBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.5, 1.5);
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:closeBtn];
    _closeBtn = closeBtn;

    const float spinnerPadding = 80.0f;

    NSArray* constraints = @[
        // Loading Content
        [spinner.centerYAnchor constraintEqualToAnchor:self.view.topAnchor
                                              constant:spinnerPadding],
        [spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [loadingLabel.topAnchor constraintEqualToSystemSpacingBelowAnchor:spinner.bottomAnchor
                                                               multiplier:1.0],
        [loadingLabel.centerXAnchor constraintEqualToAnchor:spinner.centerXAnchor],

        // Close button
        [closeBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                constant:-22.0],
        [closeBtn.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                           constant:22.0],

        // Main content area
        [transcriptLabel.topAnchor constraintEqualToAnchor:loadingLabel.topAnchor
                                                  constant:spinnerPadding],
        [transcriptLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                     constant:-spinnerPadding],
        [transcriptLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                      constant:spinnerPadding],
        [transcriptLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                       constant:-spinnerPadding],

    ];
    [NSLayoutConstraint activateConstraints:constraints];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[VBAudioListener sharedInstance] registerDelegate:self];
        [[VBAudioListener sharedInstance] startListening];
    });
}

- (void)closeButtonAction:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[VBAudioListener sharedInstance] stopCapturing];
}

- (void)stateUpdate:(bool)running segments:(NSArray<NSString*>*)segments
{
    __weak ListenViewController* weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!running) {
            weakself.loadingLabel.text = @"Error starting listening";
            return;
        }

        weakself.loadingLabel.text = @"Listening...";

        if (segments) {
            NSString* transcript = @"";
            for (NSString* segment in segments) {
                transcript = [transcript stringByAppendingString:segment];
            }
            weakself.transcriptLabel.text = transcript;
        }
    });
}

@end
