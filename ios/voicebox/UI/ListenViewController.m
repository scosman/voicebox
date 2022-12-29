//
//  ListenViewController.m
//  voicebox
//
//  Created by Steve Cosman on 2022-12-28.
//

#import "ListenViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioQueue.h>

#import "Constants.h"
#import "whisper.h"

#define NUM_BYTES_PER_BUFFER 16 * 1024

#define NUM_BUFFERS 3
#define MAX_AUDIO_SEC 30
#define SAMPLE_RATE 16000

struct whisper_context;

typedef struct
{
    int ggwaveId;
    bool isCapturing;
    bool isTranscribing;
    bool isRealtime;
    UILabel* labelReceived;

    AudioQueueRef queue;
    AudioStreamBasicDescription dataFormat;
    AudioQueueBufferRef buffers[NUM_BUFFERS];

    int n_samples;
    int16_t* audioBufferI16;
    float* audioBufferF32;

    struct whisper_context* ctx;

    void* vc;
} StateInp;

@interface ListenViewController () {
    StateInp stateInp;
}

@property (nonatomic, weak) UILabel *loadingLabel, *closedCaptioningLabel;
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

    UILabel* closedCaptioningLabel = [[UILabel alloc] init];
    closedCaptioningLabel.text = @"";
    closedCaptioningLabel.font = [UIFont systemFontOfSize:MAX(22.0, [UIFont labelFontSize])];
    closedCaptioningLabel.textColor = [UIColor systemGrayColor];
    closedCaptioningLabel.translatesAutoresizingMaskIntoConstraints = NO;
    closedCaptioningLabel.lineBreakMode = NSLineBreakByWordWrapping;
    closedCaptioningLabel.numberOfLines = 0;
    [self.view addSubview:closedCaptioningLabel];
    _closedCaptioningLabel = closedCaptioningLabel;

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
        [closedCaptioningLabel.topAnchor constraintEqualToAnchor:loadingLabel.topAnchor
                                                        constant:spinnerPadding],
        [closedCaptioningLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                           constant:-spinnerPadding],
        [closedCaptioningLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                            constant:spinnerPadding],
        [closedCaptioningLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                             constant:-spinnerPadding],

    ];
    [NSLayoutConstraint activateConstraints:constraints];

    // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self startListening];
    //});
}

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format
{
    format->mSampleRate = WHISPER_SAMPLE_RATE;
    format->mFormatID = kAudioFormatLinearPCM;
    format->mFramesPerPacket = 1;
    format->mChannelsPerFrame = 1;
    format->mBytesPerFrame = 2;
    format->mBytesPerPacket = 2;
    format->mBitsPerChannel = 16;
    format->mReserved = 0;
    format->mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
}

- (void)startListening
{
    // whisper.cpp initialization
    {
        // load the model
        NSString* modelPath = [[NSBundle mainBundle] pathForResource:@"ggml-base.en" ofType:@"bin"];

        // check if the model exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:modelPath]) {
            NSLog(@"Model file not found");
            return;
        }

        NSLog(@"Loading model from %@", modelPath);

        // create ggml context
        stateInp.ctx = whisper_init([modelPath UTF8String]);

        // check if the model was loaded successfully
        if (stateInp.ctx == NULL) {
            NSLog(@"Failed to load model");
            return;
        }
    }

    // initialize audio format and buffers
    {
        [self setupAudioFormat:&stateInp.dataFormat];

        stateInp.n_samples = 0;
        stateInp.audioBufferI16 = malloc(MAX_AUDIO_SEC * SAMPLE_RATE * sizeof(int16_t));
        stateInp.audioBufferF32 = malloc(MAX_AUDIO_SEC * SAMPLE_RATE * sizeof(float));
    }

    stateInp.isTranscribing = false;
    stateInp.isRealtime = true;
    [self startCapturing];
}

- (void)closeButtonAction:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];

    // TODO make sure this is called more
    [self stopCapturing];
}

- (void)stopCapturing
{
    NSLog(@"Stop capturing");

    stateInp.isCapturing = false;

    AudioQueueStop(stateInp.queue, true);
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueFreeBuffer(stateInp.queue, stateInp.buffers[i]);
    }

    AudioQueueDispose(stateInp.queue, true);
}

//- (IBAction)toggleCapture:(id)sender {
- (void)startCapturing
{
    // initiate audio capturing
    NSLog(@"Start capturing");

    stateInp.n_samples = 0;
    stateInp.vc = (__bridge void*)(self);

    OSStatus status = AudioQueueNewInput(&stateInp.dataFormat,
        AudioInputCallback,
        &stateInp,
        CFRunLoopGetCurrent(),
        kCFRunLoopCommonModes,
        0,
        &stateInp.queue);

    if (status == 0) {
        for (int i = 0; i < NUM_BUFFERS; i++) {
            AudioQueueAllocateBuffer(stateInp.queue, NUM_BYTES_PER_BUFFER, &stateInp.buffers[i]);
            AudioQueueEnqueueBuffer(stateInp.queue, stateInp.buffers[i], 0, NULL);
        }

        stateInp.isCapturing = true;
        status = AudioQueueStart(stateInp.queue, NULL);
        if (status == 0) {
            _loadingLabel.text = @"Listening...";
        }
    }

    if (status != 0) {
        [self stopCapturing];
    }
}

- (IBAction)onTranscribePrepare:(id)sender
{
    _closedCaptioningLabel.text = @"...";

    if (stateInp.isRealtime) {
        [self onRealtime:(id)sender];
    }

    if (stateInp.isCapturing) {
        [self stopCapturing];
    }
}

// Start needs to ser
- (IBAction)onRealtime:(id)sender
{
    stateInp.isRealtime = !stateInp.isRealtime;

    NSLog(@"Realtime: %@", stateInp.isRealtime ? @"ON" : @"OFF");
}

- (IBAction)onTranscribe:(id)sender
{
    if (stateInp.isTranscribing) {
        return;
    }

    NSLog(@"Processing %d samples", stateInp.n_samples);

    stateInp.isTranscribing = true;

    __weak ListenViewController* weakSelf = self;
    // dispatch the model to a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // process captured audio
        // convert I16 to F32
        for (int i = 0; i < self->stateInp.n_samples; i++) {
            self->stateInp.audioBufferF32[i] = (float)self->stateInp.audioBufferI16[i] / 32768.0f;
        }

        // run the model
        struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

        // get maximum number of threads on this device (max 8)
        const int max_threads = MIN(8, (int)[[NSProcessInfo processInfo] processorCount]);

        params.print_realtime = true;
        params.print_progress = false;
        params.print_timestamps = true;
        params.print_special = false;
        params.translate = false;
        params.language = "en";
        params.n_threads = max_threads;
        params.offset_ms = 0;
        params.no_context = true;
        params.single_segment = self->stateInp.isRealtime;

        CFTimeInterval startTime = CACurrentMediaTime();

        whisper_reset_timings(self->stateInp.ctx);

        if (whisper_full(self->stateInp.ctx, params, self->stateInp.audioBufferF32, self->stateInp.n_samples) != 0) {
            NSLog(@"Failed to run the model");
            weakSelf.closedCaptioningLabel.text = @"Error starting listenting.";

            return;
        }

        whisper_print_timings(self->stateInp.ctx);

        CFTimeInterval endTime = CACurrentMediaTime();

        NSLog(@"\nProcessing time: %5.3f, on %d threads", endTime - startTime, params.n_threads);

        // result text
        NSString* result = @"";

        int n_segments = whisper_full_n_segments(self->stateInp.ctx);
        for (int i = 0; i < n_segments; i++) {
            const char* text_cur = whisper_full_get_segment_text(self->stateInp.ctx, i);

            // append the text to the result
            result = [result stringByAppendingString:[NSString stringWithUTF8String:text_cur]];
        }

        const float tRecording = (float)self->stateInp.n_samples / (float)self->stateInp.dataFormat.mSampleRate;

        // append processing time
        result = [result stringByAppendingString:[NSString stringWithFormat:@"\n\n[recording time:  %5.3f s]", tRecording]];
        result = [result stringByAppendingString:[NSString stringWithFormat:@"  \n[processing time: %5.3f s]", endTime - startTime]];

        // dispatch the result to the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.closedCaptioningLabel.text = result;
            self->stateInp.isTranscribing = false;
        });
    });
}

//
// Callback implementation
//

void AudioInputCallback(void* inUserData,
    AudioQueueRef inAQ,
    AudioQueueBufferRef inBuffer,
    const AudioTimeStamp* inStartTime,
    UInt32 inNumberPacketDescriptions,
    const AudioStreamPacketDescription* inPacketDescs)
{
    StateInp* stateInp = (StateInp*)inUserData;

    if (!stateInp->isCapturing) {
        NSLog(@"Not capturing, ignoring audio");
        return;
    }

    const int n = inBuffer->mAudioDataByteSize / 2;

    NSLog(@"Captured %d new samples", n);

    if (stateInp->n_samples + n > MAX_AUDIO_SEC * SAMPLE_RATE) {
        NSLog(@"Too much audio data, ignoring");

        dispatch_async(dispatch_get_main_queue(), ^{
            ListenViewController* vc = (__bridge ListenViewController*)(stateInp->vc);
            [vc stopCapturing];
        });

        return;
    }

    for (int i = 0; i < n; i++) {
        stateInp->audioBufferI16[stateInp->n_samples + i] = ((short*)inBuffer->mAudioData)[i];
    }

    stateInp->n_samples += n;

    // put the buffer back in the queue
    AudioQueueEnqueueBuffer(stateInp->queue, inBuffer, 0, NULL);

    if (stateInp->isRealtime) {
        // dipatch onTranscribe() to the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            ListenViewController* vc = (__bridge ListenViewController*)(stateInp->vc);
            [vc onTranscribe:nil];
        });
    }
}

@end
