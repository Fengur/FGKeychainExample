//
//  ViewController.m
//  FGKeyChainVerifyDemo
//
//  Created by Fengur on 16/9/19.
//  Copyright © 2016年 code.sogou.fengur. All rights reserved.
//

#import "ViewController.h"
#import "FGKeyChainUDID.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KeyChainExample_Verify";
    self.udidLabel.text = [NSString stringWithFormat:@"\t已存的udid标识符:\n\t%@",[[FGKeyChainUDID shareKeyChainUDID] readUDID]];
    [self setValueForLabels];
    
}


- (void)setValueForLabels{
    NSDictionary *dataDict = [[FGKeyChainUDID shareKeyChainUDID]getUserNameAndPassWord];
    self.userNameLabel.text = [NSString stringWithFormat:@"\tSaveDemo存入的userName:\n\t%@",[dataDict objectForKey:@"userName"]];
    self.passwordLabel.text = [NSString stringWithFormat:@"\tSaveDemo存入的password:\n\t%@",[dataDict objectForKey:@"password"]];
}


- (IBAction)refreshDataInKeychain:(id)sender {
    [self setValueForLabels];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
