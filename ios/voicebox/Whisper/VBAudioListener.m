//
//  VBAudioListener.m
//  voicebox
//
//  Created by Steve Cosman on 2023-03-01.
//  Modified from example available here with MIT licence: https://github.com/ggerganov/whisper.cpp
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioQueue.h>

#import "VBAudioListener.h"
#import "whisper.h"

#define NUM_BYTES_PER_BUFFER 16 * 1024

#define NUM_BUFFERS 3
#define MAX_AUDIO_SEC 60
#define SAMPLE_RATE WHISPER_SAMPLE_RATE

struct whisper_context;

// TODO idiomatic ObjC
typedef struct
{
    int ggwaveId;
    bool isCapturing;
    bool isTranscribing;
    bool shutdownStarted;

    AudioQueueRef queue;
    AudioStreamBasicDescription dataFormat;
    AudioQueueBufferRef buffers[NUM_BUFFERS];

    int n_samples;
    int16_t* audioBufferI16;
    float* audioBufferF32;

    struct whisper_context* ctx;

    __weak VBAudioListener* listener;
} StateInp;


@interface VBAudioListener () {
    StateInp stateInp;
}

@property (nonatomic, strong) NSHashTable *delegates;

@end

@implementation VBAudioListener

static VBAudioListener *sharedInstance = nil;

+ (VBAudioListener*)sharedInstance
{
    @synchronized(VBAudioListener.class) {
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
        
        return sharedInstance;
    }
}

+(void)releaseSharedInstance {
    @synchronized(VBAudioListener.class) {
        if (sharedInstance) {
            // set state so delayed callbacks don't accidentially "restart" server
            sharedInstance->stateInp.shutdownStarted = true;
            // helps memory get cleared sooner, prior to callbacks
            sharedInstance->stateInp.listener = nil;
            [sharedInstance stopCapturing];
            sharedInstance = nil;
        }
    }
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _delegates = [NSHashTable weakObjectsHashTable];
        
        // whisper.cpp initialization
        
        /* Important: must run in "release" mode to have reasonable perf. Debug kills it.
         *
         * From rough experimentation, the base model seems to work well enough, so sticking to that
         * for now. The small model works too, with similar CPU but double the memory, and slower
         * processing time (CPU probably isn't telling whole story).
         *
         * The distil mode (ggml-distil-small / ggml-medium-32-2.en) should be better (better model, similar perf). However, the need this chunking strategy
         * implemented for production usage. Keep deving on base/small, and switch to distil when fully supported
         *
         * Plan: ggml-distil-small is great. only a bit more processing than base. Better quality. Prob don't need to wait for second round processing nearly as much with small quality.
         *
         * If you want to play with this, add the models to "Copy Bundle Resources" step of build.
         */
        // load the whisper model
        NSString* modelPath = [[NSBundle mainBundle] pathForResource:@"ggml-base.en" ofType:@"bin"];
        //NSString* modelPath = [[NSBundle mainBundle] pathForResource:@"ggml-distil-small.en" ofType:@"bin"];
        //NSString* modelPath = [[NSBundle mainBundle] pathForResource:@"ggml-medium-32-2.en" ofType:@"bin"];

        // check if the model exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:modelPath]) {
            NSLog(@"Model file not found");
        }

        NSLog(@"Loading model from %@", modelPath);

        // create ggml context
        whisper_init_with_params
        stateInp.ctx = whisper_init([modelPath UTF8String]);

        // check if the model was loaded successfully
        if (stateInp.ctx == NULL) {
            NSLog(@"Failed to load model");
        }
    }
    return self;
}

-(void)dealloc {
    whisper_free(stateInp.ctx);
    free(stateInp.audioBufferI16);
    free(stateInp.audioBufferF32);
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueFreeBuffer(stateInp.queue, stateInp.buffers[i]);
    }
}

-(void) registerDelegate:(id <VBAudioListenerDelegate>)delegate {
    [_delegates addObject:delegate];
}

-(void) deregisterDelegate:(id <VBAudioListenerDelegate>)delegate {
    [_delegates removeObject:delegate];
}

-(void) distributeStateUpdate:(bool)running segments:(nullable NSArray<NSString*>*)segments
{
    for (id <VBAudioListenerDelegate>delegate in _delegates) {
        if (stateInp.shutdownStarted) {
            [delegate stateUpdate:false segments:nil];
        } else {
            [delegate stateUpdate:running segments:segments];
        }
    }
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
    if (stateInp.ctx == NULL) {
        // initialization failed
        [self distributeStateUpdate:false segments:nil];
        return;
    }
    
    // initialize audio format and buffers
    [self setupAudioFormat:&stateInp.dataFormat];

    stateInp.n_samples = 0;
    if (!stateInp.audioBufferI16) {
        stateInp.audioBufferI16 = malloc(MAX_AUDIO_SEC * SAMPLE_RATE * sizeof(int16_t));
    }
    if (!stateInp.audioBufferF32) {
        stateInp.audioBufferF32 = malloc(MAX_AUDIO_SEC * SAMPLE_RATE * sizeof(float));
    }

    stateInp.isTranscribing = false;
    
    // TODO - might already be capturing!
    [self startCapturing];
}

- (void)stopCapturing
{
    // TODO test dispatch
    __block VBAudioListener* blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Stop capturing");
        
        blockSelf->stateInp.isCapturing = false;
        
        AudioQueueStop(blockSelf->stateInp.queue, true);
        for (int i = 0; i < NUM_BUFFERS; i++) {
            AudioQueueFreeBuffer(blockSelf->stateInp.queue, blockSelf->stateInp.buffers[i]);
        }
        
        AudioQueueDispose(blockSelf->stateInp.queue, true);
        
        [self distributeStateUpdate:false segments:nil];
    });
}

- (void)startCapturing
{
    __block VBAudioListener* blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // initiate audio capturing
        NSLog(@"Start capturing");
        
        blockSelf->stateInp.n_samples = 0;
        
        __weak VBAudioListener* weakself = blockSelf;
        blockSelf->stateInp.listener = weakself;
        
        OSStatus status = AudioQueueNewInput(&blockSelf->stateInp.dataFormat,
                                             AudioInputCallback,
                                             &blockSelf->stateInp,
                                             CFRunLoopGetCurrent(),
                                             kCFRunLoopCommonModes,
                                             0,
                                             &blockSelf->stateInp.queue);
        
        if (status != 0) {
            return;
        }
        for (int i = 0; i < NUM_BUFFERS; i++) {
            AudioQueueAllocateBuffer(blockSelf->stateInp.queue, NUM_BYTES_PER_BUFFER, &blockSelf->stateInp.buffers[i]);
            AudioQueueEnqueueBuffer(blockSelf->stateInp.queue, blockSelf->stateInp.buffers[i], 0, NULL);
        }
        
        blockSelf->stateInp.isCapturing = true;
    
        status = AudioQueueStart(blockSelf->stateInp.queue, NULL);
        
        if (status != 0) {
            [self stopCapturing];
        }
        bool running = status == 0;
        [blockSelf distributeStateUpdate:running segments:nil];
    });
}

- (IBAction)onTranscribe
{
    // TODO -- this guard system isn't ideal. Caller using main thread so works, but ugh.
    if (stateInp.isTranscribing) {
        return;
    }

    NSLog(@"Processing %d samples", stateInp.n_samples);

    stateInp.isTranscribing = true;

    // dispatch the model to a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // process captured audio
        // convert I16 to F32
        NSLog(@"Transcribing: %d", self->stateInp.n_samples);
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
        // TODO P1: `params.suppress_non_speech_tokens = true;` once it makes it to stable release
        params.n_threads = max_threads;
        // TODO: think we're processing whole thing each time?
        params.offset_ms = 0;
        params.no_context = true;
        params.single_segment = false;

        CFTimeInterval startTime = CACurrentMediaTime();

        whisper_reset_timings(self->stateInp.ctx);

        int whisperStatus = whisper_full(self->stateInp.ctx, params, self->stateInp.audioBufferF32, self->stateInp.n_samples);
        if (whisperStatus != 0) {
            NSLog(@"Failed to run the model");
            [self distributeStateUpdate:false segments:nil];
            return;
        }

        whisper_print_timings(self->stateInp.ctx);

        CFTimeInterval endTime = CACurrentMediaTime();

        NSLog(@"\nProcessing time: %5.3f, on %d threads", endTime - startTime, params.n_threads);

        int n_segments = whisper_full_n_segments(self->stateInp.ctx);
        NSMutableArray<NSString*>* segments = [[NSMutableArray alloc] initWithCapacity:n_segments];
        for (int i = 0; i < n_segments; i++) {
            const char* text_cur = whisper_full_get_segment_text(self->stateInp.ctx, i);
            [segments addObject:[NSString stringWithUTF8String:text_cur]];
        }

        const float tRecording = (float)self->stateInp.n_samples / (float)self->stateInp.dataFormat.mSampleRate;

        // log processing time
        NSLog(@"[recording time:  %5.3f s] [processing time: %5.3f s]", tRecording, endTime - startTime);

        // dispatch needed as using the main thread as bad sync mechanism for `isTranscribing`
        dispatch_async(dispatch_get_main_queue(), ^{
            [self distributeStateUpdate:true segments:segments];
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
    
    if (stateInp->shutdownStarted) {
        return;
    }

    const int n = inBuffer->mAudioDataByteSize / 2;

    NSLog(@"Captured %d new samples", n);

    if (stateInp->n_samples + n > MAX_AUDIO_SEC * SAMPLE_RATE) {
        NSLog(@"Too much audio data, ignoring");

        dispatch_async(dispatch_get_main_queue(), ^{
            VBAudioListener* listener = stateInp->listener;
            [listener stopCapturing];
        });

        return;
    }

    for (int i = 0; i < n; i++) {
        stateInp->audioBufferI16[stateInp->n_samples + i] = ((short*)inBuffer->mAudioData)[i];
    }

    stateInp->n_samples += n;

    // put the buffer back in the queue
    AudioQueueEnqueueBuffer(stateInp->queue, inBuffer, 0, NULL);

    // dipatch onTranscribe() to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        VBAudioListener* listener = stateInp->listener;
        [listener onTranscribe];
    });
}

@end
