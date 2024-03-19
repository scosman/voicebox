//
//  VBShareViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2024-03-18.
//

#import "VBShareViewController.h"
#import "../Util/VBStringUtils.h"
#import "Constants.h"
#import "VBButton.h"

@interface VBShareViewController ()

@property (nonatomic, strong) NSString* content;
@property (nonatomic, weak) UILabel* titleLabel;
@property (nonatomic, weak) VBButton *stringCopyButton, *emailButton, *otherShareButton;
@property (nonatomic, weak) UIButton* closeBtn;

@end

@implementation VBShareViewController

- (instancetype)initWithContent:(NSString*)content
{
    self = [super init];
    if (self) {
        self.content = content;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = APP_BACKGROUND_UICOLOR;

    UILabel* titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Share";
    titleLabel.font = [VBStringUtils logoFontOfWeight:UIFontWeightBold withSize:(IS_IPAD ? 32 : 28)];
    [titleLabel sizeToFit];
    [self.view addSubview:titleLabel];
    _titleLabel = titleLabel;

    VBButton* otherShareButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"square.and.arrow.up" andTitle:@"More"];
    otherShareButton.translatesAutoresizingMaskIntoConstraints = NO;
    [otherShareButton addTarget:self action:@selector(otherShare:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:otherShareButton];
    _otherShareButton = otherShareButton;

    VBButton* emailButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"envelope" andTitle:@"Email"];
    emailButton.translatesAutoresizingMaskIntoConstraints = NO;
    [emailButton addTarget:self action:@selector(email:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:emailButton];
    _emailButton = emailButton;

    VBButton* stringCopyButton = [[VBButton alloc] initLargeSymbolButtonWithSystemImageNamed:@"doc.on.doc" andTitle:@"Copy"];
    stringCopyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [stringCopyButton addTarget:self action:@selector(stringCopy:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:stringCopyButton];
    _stringCopyButton = stringCopyButton;

    UIButton* closeBtn = [VBButton buttonWithType:UIButtonTypeClose];
    // scale for larger tap target
    closeBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.5, 1.5);
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:closeBtn];
    _closeBtn = closeBtn;

    const float buttonWidth = 300;
    const float buttonHeight = 140;
    const float buttonPadding = 24;

    NSArray<NSLayoutConstraint*>* constraints = @[
        // Title
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor
                                             constant:IS_IPAD ? 44.0 : 22.0],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        // Close button
        [closeBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                constant:-22.0],
        [closeBtn.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                           constant:26.0],

        // Email: centered
        [emailButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [emailButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [emailButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [emailButton.heightAnchor constraintEqualToConstant:buttonHeight],

        // Copy: above
        [stringCopyButton.bottomAnchor constraintEqualToAnchor:emailButton.topAnchor
                                                      constant:-buttonPadding],
        [stringCopyButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stringCopyButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [stringCopyButton.heightAnchor constraintEqualToConstant:buttonHeight],

        // Other: below
        [otherShareButton.topAnchor constraintEqualToAnchor:emailButton.bottomAnchor
                                                   constant:buttonPadding],
        [otherShareButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [otherShareButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [otherShareButton.heightAnchor constraintEqualToConstant:buttonHeight],
    ];
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)stringCopy:(UIButton*)sender
{
    UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.content;
    [_stringCopyButton setBackgroundColor:[UIColor systemGreenColor]];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)email:(UIButton*)sender
{
    NSString* body = self.content;
    // Mailto required /r/n
    body = [body stringByReplacingOccurrencesOfString:@"\n" withString:@"\r\n"];

    NSURLComponents* urlComps = [NSURLComponents componentsWithString:@"mailto:"];
    urlComps.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"body"
                                    value:body]
        // TODO: smart ML @"subject"
    ];
    NSURL* url = urlComps.URL;

    [[UIApplication sharedApplication] openURL:url
                                       options:@{}
                             completionHandler:^(BOOL success) {
                                 if (success) {
                                     [self dismissViewControllerAnimated:YES completion:nil];
                                 } else {
                                     UIAlertController* errVC = [UIAlertController alertControllerWithTitle:@"Error Launching Email" message:@"We could not launch your default email application." preferredStyle:UIAlertControllerStyleAlert];
                                     UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                             style:UIAlertActionStyleDefault
                                                                                           handler:nil];
                                     [errVC addAction:defaultAction];
                                     [self presentViewController:errVC animated:YES completion:nil];
                                 }
                             }];
}

- (void)otherShare:(UIButton*)sender
{
    UIActivityViewController* shareVC = [[UIActivityViewController alloc] initWithActivityItems:@[ self.content ] applicationActivities:nil];

    if (shareVC.popoverPresentationController) {
        shareVC.popoverPresentationController.sourceView = _otherShareButton;
    }

    [self presentViewController:shareVC animated:YES completion:nil];
}

- (void)closeButtonAction:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
