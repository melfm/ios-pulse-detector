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
    
    //UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    
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
    
    isCapturing = NO;
    beenTapped = NO;
    
    
}

//- (NSInteger)supportedInterfaceOrientations
//{
//    // Only portrait orientation
//    return UIInterfaceOrientationMaskPortrait;
//}
//
//- (void)handleTap:(UITapGestureRecognizer *)sender
//{
//    if (sender.state == UIGestureRecognizerStateEnded)
//    {
//        // handling code
//        
//    }
//}

-(IBAction)detectPulseButtonPressed:(id)sender
{
    beenTapped = YES;
}

-(IBAction)startCaptureButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = YES;
    numberOfSeconds = 0;
}

-(IBAction)stopCaptureButtonPressed:(id)sender
{
    [videoCamera stop];
    isCapturing = NO;
}

- (void)processImage:(cv::Mat&)image
{
    // Do some OpenCV processing with the image
    
    // Draw all detected faces
  /*  for(unsigned int i = 0; i < faces.size(); i++)
    {
        const cv::Rect& face = faces[i];
        // Get top-left and bottom-right corner points
        cv::Point tl(face.x, face.y);
        cv::Point br = tl + cv::Point(face.width, face.height);
        
        // Draw rectangle around the face
        cv::Scalar magenta = cv::Scalar(255, 0, 255);
        cv::rectangle(image, tl, br, magenta, 4, 8, 0);
    }*/
    
    // Create PulseData object
    PU pdata;
    
    // Start clock for timestamping
    //pulseDetector._start = boost::chrono::system_clock::now();
    pulseDetector.startTimer();
    
    
    cv::Mat frameGreyscale;
    // Get some sleep after every read
    // Needed? Already seems lagging
    //cv::waitKey(50);
    
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
                cv::putText(image, "Touch the screen to start processing", cv::Point(10, 40), CV_FONT_HERSHEY_PLAIN, 1.2, color);
            }
            
            else {
                // Get image data for the forehead for BPM monitoring
                cv::Mat fhimg = image(pulseDetector._forehead);
                cv::rectangle(image, pulseDetector._forehead, cv::Scalar(0, 255, 255, 0), 1, 8, 0);
                //cv::putText(frameOriginal, "BMP Area", cv::Point(_forehead.x, _forehead.y), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                cv::putText(image, "Press 'R' to stop BPM monitoring", cv::Point(10, 40), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                pulseDetector.gap = (MAX_SAMPLES - (pulseDetector._means.size()) ) / pulseDetector._fps;
                if( pulseDetector.gap > 0){
                    char buffer[50];
                    
                    int n = snprintf(buffer, 50, "Please wait for %0.0lf s", pulseDetector.gap);
                    cv::putText(image, buffer, cv::Point(pulseDetector._forehead.x + 100, pulseDetector._forehead.y+ 25), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                }
                
                pdata = pulseDetector.estimateBPM(fhimg);
                char bpmbuffer[50];
                int n = sprintf(bpmbuffer, "estimate: %0.1lf bpm", (pdata.bpm));
                cv::putText(image, bpmbuffer, cv::Point(pulseDetector._forehead.x , pulseDetector._forehead.y), CV_FONT_HERSHEY_PLAIN, 1.2, color);
                
            }
            
            
        }
        
    }
    
   // Having timer issues - Kick off the algorithm after 10 counts
    numberOfSeconds++;
    if (numberOfSeconds > 10){
         beenTapped = YES;
    }
    
    // Show resulting image
    imageView.image = MatToUIImage(image);
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
