//
//  FGKeyChainUDID.h
//  TTSDemo
//
//  Created by Fengur on 16/9/18.
//  Copyright © 2016年 code.sogou.fengur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FGKeyChainUDID : NSObject

@property (nonatomic, copy) NSString *udid;

+ (instancetype)shareKeyChainUDID;

- (NSString *)readUDID;

- (void)saveUserName:(NSString *)userName passWord:(NSString *)passWord;

- (NSDictionary *)getUserNameAndPassWord;

@end
