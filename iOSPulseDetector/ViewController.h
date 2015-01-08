/*****************************************************************************
 *   ViewController.h
 ******************************************************************************
 *   by Melissa Mozifian, 25th Dec 2014
 ******************************************************************************
 *
 *
 *
 *
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import <opencv2/highgui/ios.h>


#import "PulseDetector.hpp"


@interface ViewController : UIViewController<CvVideoCameraDelegate>
{
    CvVideoCamera* videoCamera;
    BOOL isCapturing;
    cv::CascadeClassifier faceDetector;
    PulseDetector pulseDetector;
    BOOL beenTapped;
    int numberOfSeconds;
   
}

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UIToolbar* toolbar;
@property (nonatomic, weak) IBOutlet
    UIBarButtonItem* startCaptureButton;
@property (nonatomic, weak) IBOutlet
    UIBarButtonItem* stopCaptureButton;
@property (nonatomic, weak) IBOutlet
    UIBarButtonItem* detectPulseButton;

-(IBAction)startCaptureButtonPressed:(id)sender;
-(IBAction)stopCaptureButtonPressed:(id)sender;
-(IBAction)detectPulseButtonPressed:(id)sender;


//- (void)handleTap:(UITapGestureRecognizer *)sender;

@end
