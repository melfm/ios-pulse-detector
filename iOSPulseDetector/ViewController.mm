/*****************************************************************************
 *   ViewController.m
 ******************************************************************************
 *   by Melissa Mozifian, 25th Dec 2014
 ******************************************************************************
 *
 *
 *
 *
 *****************************************************************************/

#import "ViewController.h"






@interface ViewController ()

@end

@implementation ViewController

@synthesize imageView;
@synthesize startCaptureButton;
@synthesize toolbar;
@synthesize videoCamera;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Instantiate the gesture recognizer
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapGestureRecognizer setNumberOfTapsRequired: 1];
    //[tapGestureRecognizer setNumberOfTouchesRequired: 1];
    
    
    // Load cascade classifier from the XML file
    NSString* cascadePath = [[NSBundle mainBundle]
                             pathForResource:@"haarcascade_frontalface_alt"
                             ofType:@"xml"];
    faceDetector.load([cascadePath UTF8String]);
    

    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition =
                                AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset =
                                AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation =
                                AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    
    [self.view addGestureRecognizer: tapGestureRecognizer];
    
    self.navigationController.toolbar.barTintColor = [UIColor blackColor];
    
    
    isCapturing = NO;
    beenTapped = NO;
    
    // Start clock for timestamping
    pulseDetector.startTimer();
    
    // Call the FFT function for testing
    ////////////////////////////////////
    
    
    vDSP_Length Log2N = 10u;
    vDSP_Length N = (1u<<Log2N);

    cout << "Log2N " << Log2N << endl;
    cout << "N : " << N << endl;
    
    static const float_t TwoPi = 0x3.243f6a8885a308d313198a2e03707344ap1;
    
    
    // Generate input signal
    const float Frequency0 = 79, Frequency1 = 296, Frequency2 = 143;
    const float Phase0 = 0, Phase1 = .2f, Phase2 = .6f;
    
    // Allocate memory for the arrays.
    float *Signal = (float*)malloc(N * sizeof Signal);
    
    
    vDSP_Length i;
    for ( i = 0; i < N; ++i) {
        Signal[i] =
        cos((i * Frequency0 / N + Phase0) * TwoPi)
        + cos((i * Frequency1 / N + Phase1) * TwoPi)
        + cos((i * Frequency2 / N + Phase2) * TwoPi);
    }
    
    // The Main FFT Helper
    FFTHelperRef *fftConverter = NULL;
    
    //initialize stuff
    fftConverter = pulseDetector.FFTHelperCreate(N);
    float *fftData = pulseDetector.computeFFT(fftConverter, Signal, N);
    
    /*	Prepare expected results based on analytical transformation of
     the input signal.
     */
    float *ExpectedMemory = (float*)malloc(N * sizeof *ExpectedMemory);
    if (ExpectedMemory == NULL)
    {
        fprintf(stderr, "Error, failed to allocate memory.\n");
        exit(EXIT_FAILURE);
    }

    // Assign half of ExpectedMemory to reals and half to imaginaries.
    DSPSplitComplex Expected = { ExpectedMemory, ExpectedMemory + N/2 };
    
    for (i = 0; i < N/2; ++i)
        Expected.realp[i] = Expected.imagp[i] = 0;
    
    // Add the frequencies in the signal to the expected results.
    Expected.realp[(int) Frequency0] = N * cos(Phase0 * TwoPi);
    Expected.imagp[(int) Frequency0] = N * sin(Phase0 * TwoPi);
    
    Expected.realp[(int) Frequency1] = N * cos(Phase1 * TwoPi);
    Expected.imagp[(int) Frequency1] = N * sin(Phase1 * TwoPi);
    
    Expected.realp[(int) Frequency2] = N * cos(Phase2 * TwoPi);
    Expected.imagp[(int) Frequency2] = N * sin(Phase2 * TwoPi);
    
    // Compare the observed results to the expected results.
    pulseDetector.CompareComplexVectors(Expected, fftConverter->complexA, N/2);

}

- (void) handleTap: (UITapGestureRecognizer *)recognizer
{
    if(isCapturing){
        beenTapped = YES;
    }
    
}



-(IBAction)startCaptureButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = YES;
 
}

-(IBAction)stopCaptureButtonPressed:(id)sender
{
    if(isCapturing){
    [videoCamera stop];
    beenTapped = NO;
    pulseDetector.clearBuffers();
    isCapturing = NO;
        
    }
}

- (void)processImage:(cv::Mat&)image
{
    // Do some OpenCV processing with the image
    // Create PulseData object
    PU pdata;
    
    cv::Mat frameGreyscale;
    
    cv::Scalar color(255, 255, 0, 0);
    // Convert image to gray scale and equalize
    cv::flip(image, image, 1);
    cv::cvtColor(image, frameGreyscale, CV_BGR2GRAY);
    cv::equalizeHist(frameGreyscale, frameGreyscale);
    
    // Detect faces
    std::vector<cv::Rect> faces;
    faceDetector.detectMultiScale(image, faces, 1.1,
                                  2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
    
    if(!faces.empty()) {
        
        cv::Rect fh;
        cv::Rect grabbedFace;
        for (int i=0; i < faces.size(); i++) {
            // draw a green rectangle around the face over the original image
            if(!beenTapped) {
                pulseDetector.getForehead(faces[i], fh);
                // This is locks the forehead
                pulseDetector.getForehead(faces[0], pulseDetector._forehead); // Save forehead of 1st captured face
                cv::rectangle(image, faces[i], cv::Scalar(0, 255, 0, 0), 1, 8, 0);
                cv::putText(image, "Face", cv::Point(faces[i].x, faces[i].y), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                cv::rectangle(image, fh, cv::Scalar(0, 255, 255, 0), 1, 8, 0);
                cv::putText(image, "Forehead", cv::Point(fh.x, fh.y), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                cv::putText(image, "Tap the screen once to start processing", cv::Point(10, 40), CV_FONT_HERSHEY_PLAIN, 1.2, color);
            }
            
            else {
                // Get image data for the forehead for BPM monitoring
                cv::Mat fhimg = image(pulseDetector._forehead);
                cv::rectangle(image, pulseDetector._forehead, cv::Scalar(0, 255, 255, 0), 1, 8, 0);
                pulseDetector.gap = (MAX_SAMPLES - (pulseDetector._means.size()) ) / pulseDetector._fps;
                if( pulseDetector.gap > 0){
                    char buffer[50];
                    
                    int n = snprintf(buffer, 50, "Please wait for %0.0lf s ...", pulseDetector.gap);
                    cv::putText(image, buffer, cv::Point(10, 40), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                }
                
                pdata = pulseDetector.estimateBPM(fhimg);
                char bpmbuffer[50];
                int n = sprintf(bpmbuffer, "estimate: %0.1lf bpm", (pdata.bpm));
                cv::putText(image, bpmbuffer, cv::Point(pulseDetector._forehead.x - 30 , pulseDetector._forehead.y - 25), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                
            }
            
        }
        
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (isCapturing)
    {
        [videoCamera stop];
    }
}

- (void)dealloc
{
    videoCamera.delegate = nil;
}

@end
