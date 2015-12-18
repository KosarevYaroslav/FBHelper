//
//  ViewController.m
//  FBHelper
//
//  Created by Sergey Zhdanov on 17/12/15.
//  Copyright © 2015 Drive Pixels Studio. All rights reserved.
//

#import "ViewController.h"
#import "FBHelper.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)shareImgTap:(id)sender {
    [FBHelper shareFacebookLink:@"http://spasibosberbank.ru"
                          title:@"Test sharing"
                    description:@"This is some description for this super mega cool content. Yeah, it so long!"
                          image:_imageView.image
                       callBack:^(BOOL success, id result) {
                           NSLog(@"share image result: %@", result);
                       }];
}

- (IBAction)shareLinkTap:(id)sender {

    NSString *contentURL = @"http://spasibosberbank.ru";
    NSString *imageURL = @"https://pp.vk.me/c7007/v7007456/30f98/KMhUrYf106M.jpg";
    NSString *contentDescription = @"This is some description for this super mega cool content. Yeah, it so long!";
    NSString *contentTitle = @"Test sharing";

    [FBHelper shareFacebookLink:contentURL title:contentTitle description:contentDescription
                       imageUrl:imageURL callBack:^(BOOL success, id result) {
                NSLog(@"share image result: %@", result);
    }];
}

- (IBAction)loginTap:(id)sender {
    [FBHelper loginCallBack:^(BOOL success, id result) {
        NSLog(@"login res: %@", result);
    }];
}

- (IBAction)logoutTap:(id)sender {
}

@end
