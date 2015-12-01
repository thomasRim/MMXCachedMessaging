//
//  ViewController.m
//  MMXCachedMessaging
//
//  Created by Vladimir Yevdokimov on 11/23/15.
//  Copyright © 2015 Vladimir Yevdokimov. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIView *baseV;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [_slider setThumbImage:[UIImage imageNamed:@"opt_dot"] forState:UIControlStateNormal];
    _baseV.layer.cornerRadius = 10;
    _baseV.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _baseV.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
