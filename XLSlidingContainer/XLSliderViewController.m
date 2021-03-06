//
//  ViewController.m
//  Slider
//
//  Created by mathias Claassen on 17/3/15.
//  Copyright (c) 2015 Xmartlabs. All rights reserved.
//

#import "XLSliderViewController.h"

@interface XLSliderViewController ()

@property (nonatomic) IBOutlet UIView *dragView;
@property (nonatomic) UIView *upperView;
@property (nonatomic) UIView *lowerView;
@property (nonatomic) NSInteger panDirection;
@property (weak, nonatomic) IBOutlet UIView *navView;

@property (nonatomic) UIViewController <XLSliderController> *lowerController;
@property (nonatomic) UIViewController <XLSliderController> *upperController;

@end

@interface XLSliderViewController () <UIGestureRecognizerDelegate>
@end

@implementation XLSliderViewController
{
    BOOL _initialPositionSetUp;
    BOOL _dragState;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _initialPositionSetUp = NO;
    _dragState = YES;
    
    if(!_dataSource)
        _dataSource = self;
    if(!_delegate)
        _delegate = self;

    [self addChildViewController:self.upperController];
    [self addChildViewController:self.lowerController];
    
    if (![self.upperView superview]){
        [self.navView addSubview:self.upperView];
    }
    if (![self.dragView superview]){
        [self.navView addSubview:self.dragView];
    }
    
    if (![self.lowerView superview]){
        [self.navView addSubview:self.lowerView];
    }
    
    [self.upperView addSubview:self.upperController.view];
    [self.lowerView addSubview:self.lowerController.view];
    
    [self.lowerController minimizedController:[self getMovementDifference]];
    [self.upperController maximizedController:[self getMovementDifference]];
    
    [self.lowerController didMoveToParentViewController:self];
    [self.upperController didMoveToParentViewController:self];
    
    UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDragView:)];
    pgr.delegate = self;
    [self.navView addGestureRecognizer:pgr];
}


-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!_initialPositionSetUp){
        _initialPositionSetUp = YES;
        [self drawViews];
    }
    self.lowerController.view.frame = [self frameForLowerController];
    self.upperController.view.frame = [self frameForUpperController];
}

#pragma mark - Getter and Setter

-(UIView *)navView{
    if(!_navView)
        return self.view;
    return _navView;
}

-(UIView *)upperView{
    if (_upperView) return _upperView;
    _upperView = [[UIView alloc] init];
    return _upperView;
}

-(UIView *)lowerView{
    if (_lowerView) return _lowerView;
    _lowerView = [[UIView alloc] init];
    return _lowerView;
}

-(UIView *)dragView
{
    if (_dragView) return _dragView;
    
    if ([self.dataSource respondsToSelector:@selector(getDragView)]){
        _dragView = [self.dataSource getDragView];
        if (_dragView)
            return _dragView;
    }
    
    _dragView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 42.0)];
    _dragView.backgroundColor = [UIColor darkGrayColor];
    
    return _dragView;
}

-(UIViewController *)lowerController{
    if(!_lowerController)
        _lowerController = [_dataSource getLowerControllerFor:self];
    return _lowerController;
}

-(UIViewController *)upperController{
    if (!_upperController)
        _upperController = [_dataSource getUpperControllerFor:self];;
    return _upperController;
}

#pragma mark - Helper functions

-(CGFloat)dragViewHeight{
    return CGRectGetHeight(self.dragView.frame);
}

-(CGFloat)getMovementDifference{
    return (CGRectGetHeight(self.navView.frame) - [self getUpperViewMin] - [self getLowerViewMin] - [self dragViewHeight] );
}

#pragma mark - Frame Management

-(void)drawViews{
    
    CGRect middle = CGRectMake(0, (self.navView.bounds.size.height - [self getLowerViewMin] - [self dragViewHeight]), self.navView.bounds.size.width, [self dragViewHeight]);
    self.dragView.frame = middle;
    CGRect upper = CGRectMake(0, 0, self.navView.bounds.size.width, (self.navView.bounds.size.height - [self getLowerViewMin] - [self dragViewHeight] ));
    self.upperView.frame = upper;
    CGRect lower = CGRectMake(0, (self.navView.bounds.size.height - [self getLowerViewMin]), self.navView.bounds.size.width, [self getLowerViewMin]);
    self.lowerView.frame = lower;
}

-(CGRect) frameForLowerController{
    CGRect rect = CGRectMake(self.lowerView.bounds.origin.x, self.lowerView.bounds.origin.y, self.lowerView.bounds.size.width, self.lowerView.bounds.size.height);
    return rect;
}

-(CGRect) frameForUpperController{
    CGRect rect = CGRectMake(self.upperView.bounds.origin.x, self.upperView.bounds.origin.y, self.upperView.bounds.size.width, self.upperView.bounds.size.height);
    return rect;
}

-(void)updateViews:(CGPoint) translation forState:(UIGestureRecognizerState) state {
    
    CGRect f0 = self.dragView.frame;
    CGRect f1 = self.upperView.frame;
    CGRect f2 = self.lowerView.frame;
    
    if ([self.delegate getMovementTypeFor:self] == XLSliderContainerMovementTypeHideUpperPushLower){
        if (state == UIGestureRecognizerStateEnded){
            if ((self.panDirection > 0) || ((self.panDirection == 0) && (self.dragView.frame.origin.y > 0.5*CGRectGetHeight(self.navView.frame)))){
                
                f2.size.height = [self getLowerViewMin];
                f2.origin.y = self.navView.frame.size.height - [self getLowerViewMin];
                
                f0.origin.y = f2.origin.y - f0.size.height;
                
                f1.size.height = f0.origin.y;
                
            }
            else {
                f1.size.height = [self getUpperViewMin];
                
                f0.origin.y = f1.origin.y + f1.size.height;
                
                f2.size.height = self.navView.bounds.size.height - f0.size.height;
                f2.origin.y = f0.origin.y + f0.size.height;
            }
        
        }
        else{
        
            f0.origin.y += translation.y;
            
            f1.size.height += translation.y;
            
            f2.size.height -= translation.y;
            f2.origin.y += translation.y;

        }
    }
    else if ([self.delegate getMovementTypeFor:self] == XLSliderContainerMovementTypePush){
        if (state == UIGestureRecognizerStateEnded){
            if ((self.panDirection > 0) || ((self.panDirection == 0) && (self.dragView.frame.origin.y > 0.5*CGRectGetHeight(self.navView.frame)))){
                
                f2.size.height = [self getLowerViewMin];
                f2.origin.y = self.navView.frame.size.height - [self getLowerViewMin];
                
                f0.origin.y = f2.origin.y - f0.size.height;
                
                f1.origin.y = 0;
                
            }
            else {
                f1.origin.y = [self getUpperViewMin] - f1.size.height;
                
                f0.origin.y = f1.origin.y + f1.size.height;
                
                f2.size.height = self.navView.bounds.size.height - f0.size.height;
                f2.origin.y = f0.origin.y + f0.size.height;
            }
            
        }
        else{
            
            f0.origin.y += translation.y;
            
            f1.origin.y += translation.y;
            
            f2.size.height -= translation.y;
            f2.origin.y += translation.y;
            
        }
    }
    self.lowerView.frame = f2;
    self.upperView.frame = f1;
    self.dragView.frame = f0;
    
    self.lowerController.view.frame = [self frameForLowerController];
    self.upperController.view.frame = [self frameForUpperController];

}

- (void)panDragView:(UIPanGestureRecognizer *)gr {
    CGPoint location = [gr locationInView:self.dragView];
    if ([self.dragView hitTest:location withEvent:nil] == NO && _dragState)
    {
        [gr setTranslation:CGPointZero inView:self.navView];
        return;
    }
    else
    {
        _dragState = NO;
        for(UIGestureRecognizer *g in self.lowerController.view.gestureRecognizers)
        {
            [g setEnabled:NO];
        }
        for(UIGestureRecognizer *g in self.upperController.view.gestureRecognizers)
        {
            [g setEnabled:NO];
        }
    }
    
    CGPoint dy = [gr translationInView:self.navView];
    [gr setTranslation:CGPointZero inView:self.navView];
    
    __weak XLSliderViewController* weakself = self;
    
    if (gr.state == UIGestureRecognizerStateEnded)
    {
        _dragState = YES;
        for(UIGestureRecognizer *g in self.lowerController.view.gestureRecognizers)
        {
            [g setEnabled:YES];
        }
        for(UIGestureRecognizer *g in self.upperController.view.gestureRecognizers)
        {
            [g setEnabled:YES];
        }
        
        CGFloat actualPos = self.lowerView.frame.origin.y;
        CGFloat lowerContDiff = (CGRectGetHeight(self.navView.frame) - [self getLowerViewMin] - actualPos);
        CGFloat upperContDiff = (actualPos - [self getUpperViewMin] - [self dragViewHeight]);
        if ((self.panDirection > 0) || ((self.panDirection == 0) && (self.dragView.frame.origin.y > 0.5*CGRectGetHeight(self.navView.frame)))){
            [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseIn animations:^{
                
                [weakself updateViews:dy forState:gr.state];
                if ([weakself.lowerController respondsToSelector:@selector(minimizedController:)])
                    [weakself.lowerController minimizedController: lowerContDiff];
                if ([weakself.upperController respondsToSelector:@selector(maximizedController:)])
                    [weakself.upperController maximizedController: upperContDiff];
                
            } completion:nil];
            
        }
        else{
            [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseIn animations:^{
                
                [weakself updateViews:dy forState:gr.state];
                
                if ([weakself.upperController respondsToSelector:@selector(minimizedController:)])
                    [weakself.upperController minimizedController:upperContDiff];
                if ([weakself.lowerController respondsToSelector:@selector(maximizedController:)])
                    [weakself.lowerController maximizedController:lowerContDiff];
                
            } completion:nil];
        }
        return;
    }
    
    
    if (dy.y > 0) {
        CGFloat xx = (self.navView.bounds.size.height - (self.lowerView.frame.origin.y + dy.y));
        if (xx <= [self getLowerViewMin])
            dy.y = self.navView.bounds.size.height - self.lowerView.frame.origin.y - [self getLowerViewMin];
    } else {
        if (self.upperView.frame.origin.y + self.upperView.frame.size.height + dy.y <= [self getUpperViewMin])
            dy.y = [self getUpperViewMin] - CGRectGetHeight(self.upperView.frame) - self.upperView.frame.origin.y;
    }
    [weakself updateViews:dy forState:gr.state];
    if ([weakself.upperController respondsToSelector:@selector(updateFrameForYPct: absolute:)]){
        CGFloat yPct = 100 * ((self.dragView.frame.origin.y - [self getUpperViewMin]) / (self.navView.bounds.size.height - [self getUpperViewMin] - [self getLowerViewMin] - [self dragViewHeight]));
        [weakself.upperController updateFrameForYPct:yPct absolute:dy.y];
        
    }
    if ([weakself.lowerController respondsToSelector:@selector(updateFrameForYPct:absolute:)]){
        CGFloat yPct = 100 - 100 * ((self.dragView.frame.origin.y - [self getUpperViewMin]) / (self.navView.bounds.size.height - [self getUpperViewMin] - [self getLowerViewMin] - [self dragViewHeight]));
        [weakself.lowerController updateFrameForYPct:yPct absolute:dy.y];
    }
    
    self.panDirection = dy.y;
}

#pragma mark - Reload functions

- (void) reloadLowerViewController
{
    if(self.lowerController){
        [self.lowerController willMoveToParentViewController:nil];
        [self.lowerController.view removeFromSuperview];
        [self.lowerController removeFromParentViewController];
        
        self.lowerController = [_dataSource getLowerControllerFor:self];
    
        [self addChildViewController:self.lowerController];
        [self.lowerView addSubview:self.lowerController.view];
        [self.lowerController didMoveToParentViewController:self];
        
        [self.lowerController minimizedController:[self getMovementDifference]];
    }
}

- (void) reloadUpperViewController{
    if(self.upperController)
    {
        [self.upperController willMoveToParentViewController:nil];
        [self.upperController.view removeFromSuperview];
        [self.upperController removeFromParentViewController];
        
        self.upperController = [_dataSource getUpperControllerFor:self];
        
        [self addChildViewController:self.upperController];
        [self.upperView addSubview:self.upperController.view];
        [self.upperController didMoveToParentViewController:self];
        
        [self.upperController maximizedController:[self getMovementDifference]];
    }
}

#pragma mark - XLSliderViewControllerDataSource

- (UIViewController *) getLowerControllerFor:(XLSliderViewController *)sliderViewController;
{
    NSAssert(NO, @"_dataSource must be set");
    return nil;
}

- (UIViewController *) getUpperControllerFor:(XLSliderViewController *)sliderViewController;
{
    NSAssert(NO, @"_dataSource must be set");
    return nil;
}

#pragma mark - XLSliderViewControllerDelegate

- (CGFloat) getUpperViewMin{
    return (CGRectGetHeight(self.navView.frame) / 6);
}

- (CGFloat) getLowerViewMin{
    return ((CGRectGetHeight(self.navView.frame) - [self dragViewHeight]) / 4);
}

-(XLSliderContainerMovementType)getMovementTypeFor:(XLSliderViewController *)sliderViewController{
    return XLSliderContainerMovementTypePush;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
