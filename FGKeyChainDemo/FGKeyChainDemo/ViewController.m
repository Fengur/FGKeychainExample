//
//  ViewController.m
//  FGKeyChainDemo
//
//  Created by Fengur on 16/9/19.
//  Copyright © 2016年 code.sogou.fengur. All rights reserved.
//

#import "FGKeyChainUDID.h"
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KeyChainSave";

    self.uuidTextField.text = [[FGKeyChainUDID shareKeyChainUDID] readUDID];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
- (IBAction)saveDataToKeyChain:(id)sender {
    [[FGKeyChainUDID shareKeyChainUDID] saveUserName:_userNameTextField.text
                                            passWord:_passWordTextField.text];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
