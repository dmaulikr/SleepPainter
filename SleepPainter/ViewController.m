//
//  ViewController.m
//  SleepPainter
//
//  Created by Shanshan ZHAO on 24/02/15.
//  Copyright (c) 2015 Shanshan ZHAO. All rights reserved.
//

#import "ViewController.h"
#import "AlarmViewController.h"
#import "jellyEffectView.h"
#import "SleepPainterAlarmSlider.h"

#define CHANGE_SKY_INTERVAL              10
#define ALARM_HOUR_SLIDER_SIZE           140
#define ALARM_MINUTES_SLIDER_SIZE        240

@interface ViewController ()
{
    int dummyToggle; // to test sky image changing
}

@property (weak, nonatomic) IBOutlet UILabel *clockLabel;
@property (weak, nonatomic) IBOutlet UIButton *homeSetAlarmButton;

// alpha jelly effect :)
@property (strong, nonatomic) IBOutlet UIView *sideHelperView;
@property (strong, nonatomic) IBOutlet UIView *centerHelperView;
@property (weak, nonatomic) IBOutlet jellyEffectView *jellyEffectView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jellyViewTopConstrain;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sideViewTopConstrain;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerViewTopConstrain;
@property (nonatomic,strong) CADisplayLink *displayLink;
@property  NSInteger animationCount; // 动画的数量

//slider
@property (strong,nonatomic)SleepPainterAlarmSlider * hourSlider;
@property (strong,nonatomic)SleepPainterAlarmSlider * minutesSlider;
@property (nonatomic) int alarmDuration;
@property (nonatomic,strong) UILabel * wakeUpLabel;



@end

@implementation ViewController


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.animationCount = 0;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.animationCount = 0;
    }
    return self;
}

#pragma mark - view lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"SP_background_12am.png"]]];
    dummyToggle = 0;
    [self updateClock];
    [self configOwlButton];
    
    self.sideViewTopConstrain.constant   = 0;
    self.centerViewTopConstrain.constant = 0;
    self.jellyViewTopConstrain.constant  = 0;
    
    self.sideHelperView.hidden   = YES;
    self.centerHelperView.hidden = YES;
}



#pragma mark - update clock and background image
- (void)updateClock
{
    NSDateFormatter *clockFormat = [[NSDateFormatter alloc] init];
    [clockFormat setDateFormat:@"h:mm:ss a"];
    self.clockLabel.text = [clockFormat stringFromDate:[NSDate date]];
    
    // Test background image changing
    [clockFormat setDateFormat:@"s"];
    int seconds = [[clockFormat stringFromDate:[NSDate date]] intValue];
    if (seconds % CHANGE_SKY_INTERVAL == 0)
    {
        [self updateBackgroundImage];
    }
    //
    [self performSelector:@selector(updateClock) withObject:self afterDelay:1.0f];
}

- (void)updateBackgroundImage
{
    // Add animation
    CATransition *animation = [CATransition animation];
    animation.duration = 1.0f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.delegate = self;
    [self.view.layer addAnimation:animation forKey:nil];
    
    // Do dummy action, changing image every ten seconds
    switch (dummyToggle) {
        case 0:
            [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"SP_background_5am.png"]]];
            break;
        case 1:
            [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"SP_background_12am.png"]]];
            break;
        default:
            break;
    }
    dummyToggle = 1 - dummyToggle;
}

-(void)configOwlButton
{
    [self.homeSetAlarmButton setTitle:@" ,___,\n(︶,︶)..zZ\n /)__ )\n   \"  \"" forState:UIControlStateNormal];
}


- (IBAction)clickOwlToSetAlarm:(id)sender
{
    CGFloat actionSheetHeight = CGRectGetHeight(self.jellyEffectView.frame);
    CGFloat hiddenTopMargin   = 0;                  //隐藏在下面的时候，这个距离为0
    CGFloat showedTopMargin   = -actionSheetHeight; //滑到上面的时候，这个距离就是ActionSheet的高度
    CGFloat newTopMargin      = abs(self.centerViewTopConstrain.constant - hiddenTopMargin) < 1 ? showedTopMargin : hiddenTopMargin;
    //如果中间那个辅助小方块藏在下面时，那么它的下一个位置就是在（-actionSheetHeight）的位置，所以，设置新的约束值（newTopMargin = -actionSheetHeight）,即：（newTopMargin = showedTopMargin）;
    //只要小方块在上方，那么它的下一个位置就是回到底部隐藏的位置，也就是新的约束值newTopMargin ＝ hiddenTopMargin.
    
    
    //先处理旁边那个辅助方块的约束
    self.sideViewTopConstrain.constant = newTopMargin;
    [self beforeAnimation];
    [UIView animateWithDuration:0.7 delay:0.0f usingSpringWithDamping:0.6f initialSpringVelocity:0.9f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.sideHelperView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self finishAnimation];
    }];
    
    //再处理中间那个辅助方块的约束
    self.centerViewTopConstrain.constant = newTopMargin;
    [self beforeAnimation];
    [UIView animateWithDuration:0.7 delay:0.0f usingSpringWithDamping:0.7f initialSpringVelocity:2.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.centerHelperView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self finishAnimation];
    }];
    
    if (!self.minutesSlider)
    {
        self.minutesSlider = [[SleepPainterAlarmSlider alloc] initWithFrame:CGRectMake((self.jellyEffectView.frame.size.width - ALARM_MINUTES_SLIDER_SIZE)/2, 40, ALARM_MINUTES_SLIDER_SIZE, ALARM_MINUTES_SLIDER_SIZE)];
        [self.jellyEffectView addSubview:self.minutesSlider];
    }

    if (!self.hourSlider)
    {
        self.hourSlider = [[SleepPainterAlarmSlider alloc] initWithFrame:CGRectMake((self.jellyEffectView.frame.size.width - ALARM_HOUR_SLIDER_SIZE)/2, 90, ALARM_HOUR_SLIDER_SIZE, ALARM_HOUR_SLIDER_SIZE)];
        [self.jellyEffectView addSubview:self.hourSlider];
    }
}

-(void)beforeAnimation
{
    if (self.displayLink == nil)
    {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
    self.animationCount ++;
}

//动画完成之后调用
-(void)finishAnimation
{
    self.animationCount --;
    if (self.animationCount == 0)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

//实时刷新路径
-(void)displayLinkAction:(CADisplayLink *)dis
{
    CALayer *sideHelperPresentationLayer   =  (CALayer *)[self.sideHelperView.layer presentationLayer];
    CALayer *centerHelperPresentationLayer =  (CALayer *)[self.centerHelperView.layer presentationLayer];
    
    CGPoint position = [[centerHelperPresentationLayer valueForKeyPath:@"position"]CGPointValue];
    
    CGRect centerRect = [[centerHelperPresentationLayer valueForKeyPath:@"frame"]CGRectValue];
    CGRect sideRect = [[sideHelperPresentationLayer valueForKeyPath:@"frame"]CGRectValue];
    
    NSLog(@"Center:%@",NSStringFromCGRect(centerRect));
    NSLog(@"Side:%@",NSStringFromCGRect(sideRect));
    
    CGFloat newJellyViewTopConstraint      =  position.y - CGRectGetMaxY(self.view.frame);
    
    self.jellyViewTopConstrain.constant = newJellyViewTopConstraint;
    [self.jellyEffectView layoutIfNeeded];
    
    self.jellyEffectView.sideToCenterDelta = centerRect.origin.y - sideRect.origin.y;
    [self.jellyEffectView setNeedsDisplay];
    
    
}

//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqualToString:@"goToAlarmPage"])
//    {
//        if ([segue.destinationViewController isKindOfClass:[AlarmViewController class]])
//        {
//            AlarmViewController * alarmVC = (AlarmViewController*)segue.destinationViewController;
//            [self presentViewController:alarmVC animated:YES completion:nil];
//        }
//    }
//}

@end
