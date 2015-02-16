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
   
}

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) UIImage* _image;
@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UIToolbar* toolbar;
@property (nonatomic, weak) IBOutlet
    UIBarButtonItem* startCaptureButton;
@property (nonatomic, weak) IBOutlet
    UIBarButtonItem* stopCaptureButton;

-(IBAction)startCaptureButtonPressed:(id)sender;
-(IBAction)stopCaptureButtonPressed:(id)sender;


- (void)handleTap:(UITapGestureRecognizer *)sender;

@end
