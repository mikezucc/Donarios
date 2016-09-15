//
//  ViewController.m
//  Spotta
//
//  Created by Michael Zuccarino on 9/13/16.
//  Copyright © 2016 Memes. All rights reserved.
//

#import "ViewController.h"

@import AVFoundation;
@import AVKit;
@import OpenGLES;
@import GLKit;
@import CoreImage;

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVCaptureSession *captureSession;

@property (strong, nonatomic) AVCaptureDevice *backCamera;

@property (strong, nonatomic) EAGLContext *glContext;
@property (strong, nonatomic) EAGLContext *glContext2;
@property (strong, nonatomic) GLKView *glView1;
@property (strong, nonatomic) GLKView *glView2;
@property (strong, nonatomic) CIContext *ciContext;
@property (strong, nonatomic) CIContext *ciContext2;

@property (atomic) BOOL madeFuckingFastTransform;
@property (atomic) CGAffineTransform fuckingFastTransform;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    /*
     ar tx = CGAffineTransformMakeTranslation(
     image.extent.width / 2,
     image.extent.height / 2)

     tx = CGAffineTransformRotate(
     tx,
     CGFloat(M_PI_2))

     tx = CGAffineTransformTranslate(
     tx,
     -image.extent.width / 2,
     -image.extent.height / 2)

     var transformImage = CIFilter(
     name: "CIAffineTransform",
     withInputParameters: [
     kCIInputImageKey: image,
     kCIInputTransformKey: NSValue(CGAffineTransform: tx)])!.outputImage!
     */
    self.madeFuckingFastTransform = NO;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVImageBuffer:imageBuffer];
    [EAGLContext setCurrentContext:self.glContext];

    if (!self.madeFuckingFastTransform) {
        self.madeFuckingFastTransform = YES;
        CGFloat imageWidth = image.extent.size.width;
        CGFloat imageHeight = image.extent.size.height;
        // just shrink to just the one rotate, unecessary caveman rotate (HOWDOYOU) here. like what is this, the boonies?
        self.fuckingFastTransform = CGAffineTransformMakeScale(0.4, 0.4);
        self.fuckingFastTransform = CGAffineTransformTranslate(self.fuckingFastTransform, imageWidth/2, imageHeight/2);
        self.fuckingFastTransform = CGAffineTransformRotate(self.fuckingFastTransform, -M_PI_2);
        self.fuckingFastTransform = CGAffineTransformTranslate(self.fuckingFastTransform, -imageWidth/2, -imageHeight/2);
    }

    //CIImage *transformedImage = [image imageByApplyingTransform:self.fuckingFastTransform];
    CIImage *transformedImage = [[CIFilter filterWithName:@"CIAffineTransform"
                                     withInputParameters:@{
                                                           kCIInputImageKey:image,
                                                           kCIInputTransformKey:[NSValue valueWithCGAffineTransform:self.fuckingFastTransform]}] outputImage];

    [self.glView1 bindDrawable];
    [self.ciContext drawImage:transformedImage inRect:[transformedImage extent] fromRect:[transformedImage extent]];
    [self.glView1 display];

    // render Right Eye
    [EAGLContext setCurrentContext:self.glContext2];
    [self.glView2 bindDrawable];
    [self.ciContext2 drawImage:transformedImage inRect:[transformedImage extent] fromRect:[transformedImage extent]];
    [self.glView2 display];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.glView1 = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height/2) context:self.glContext];
    [self.view addSubview:self.glView1];

    self.glContext2 = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.glView2 = [[GLKView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height/2, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height/2) context:self.glContext2];
    [self.view addSubview:self.glView2];

    self.ciContext = [CIContext contextWithEAGLContext:self.glContext];
    self.ciContext2 = [CIContext contextWithEAGLContext:self.glContext2];

    NSArray<AVCaptureDevice *> *deviceTypes = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice *device in deviceTypes.objectEnumerator) {
        if (device.position == AVCaptureDevicePositionBack) {
            self.backCamera = device;
        }
    }
    NSLog(@"memes");

    self.captureSession = [AVCaptureSession new];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];

    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCamera error:&error];
    if (captureInput) {
        if ([self.captureSession canAddInput:captureInput]) {
            [self.captureSession addInput:captureInput];
        }

        AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
        [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        if ([self.captureSession canAddOutput:videoOutput]) {
            [self.captureSession addOutput:videoOutput];
        }
    }

    __weak ViewController *weakSelf = self;
    dispatch_async(dispatch_queue_create("memes", DISPATCH_QUEUE_SERIAL), ^{
        [weakSelf.captureSession startRunning];
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
