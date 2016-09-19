//
//  FGKeyChainUDID.m
//  TTSDemo
//
//  Created by Fengur on 16/9/18.
//  Copyright © 2016年 code.sogou.fengur. All rights reserved.
//

#import "FGKeyChainUDID.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

#define KEY_UDID @"KEY_UDID"
#define KEY_IN_KEYCHAIN @"KEY_IN_KEYCHAIN"

#define KEY_USERNAME @"KEY_USERNAME"
#define USERNAMEKEY_IN_KEYCHAIN @"USERNAMEKEY_IN_KEYCHAIN"

#define KEY_PASSWORD @"KEY_PASSWORD"
#define PASSWORDKEY_IN_KEYCHAIN @"PASSWORDKEY_IN_KEYCHAIN"

@implementation FGKeyChainUDID

+ (instancetype)shareKeyChainUDID {
    static FGKeyChainUDID *keyChainUDID = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        keyChainUDID = [[self alloc] init];
    });
    return keyChainUDID;
}

- (NSString *)readUDID {
    if (_udid == nil || _udid.length == 0) {
        NSMutableDictionary *udidKVPairs = (NSMutableDictionary *)[
            [FGKeyChainUDID shareKeyChainUDID] loadDataInService:KEY_IN_KEYCHAIN];
        NSString *uuid = [udidKVPairs objectForKey:KEY_UDID];
        if (uuid == nil || uuid.length == 0) {
            uuid = [self openUDID];
            [self saveUDID:uuid];
        }
        _udid = uuid;
    }
    return _udid;
}

- (NSString *)openUDID {
    NSString *identifierForVendor = [[UIDevice currentDevice].identifierForVendor UUIDString];
    return [identifierForVendor stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

- (void)saveUDID:(NSString *)udid {
    NSMutableDictionary *udidKVPairs = [NSMutableDictionary new];
    [udidKVPairs setObject:udid forKey:KEY_UDID];
    [[FGKeyChainUDID shareKeyChainUDID] saveTargetData:udidKVPairs ToService:KEY_IN_KEYCHAIN];
}

- (void)deleteUDID {
    [[FGKeyChainUDID shareKeyChainUDID] deleteDataInService:KEY_IN_KEYCHAIN];
}

- (NSMutableDictionary *)getKeyChainDataWithService:(NSString *)service {
    return [NSMutableDictionary
        dictionaryWithObjectsAndKeys:(__bridge_transfer id)kSecClassGenericPassword,
                                     (__bridge_transfer id)kSecClass, service,
                                     (__bridge_transfer id)kSecAttrService, service,
                                     (__bridge_transfer id)kSecAttrAccount,
                                     (__bridge_transfer id)kSecAttrAccessibleAfterFirstUnlock,
                                     (__bridge_transfer id)kSecAttrAccessible, nil];
}

- (void)saveTargetData:(id)data ToService:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeyChainDataWithService:service];
    SecItemDelete((__bridge_retained CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data]
                      forKey:(__bridge_transfer id)kSecValueData];
    SecItemAdd((__bridge_retained CFDictionaryRef)keychainQuery, NULL);
}

- (id)loadDataInService:(NSString *)service {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeyChainDataWithService:service];

    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge_transfer id)kSecReturnData];
    [keychainQuery setObject:(__bridge_transfer id)kSecMatchLimitOne
                      forKey:(__bridge_transfer id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge_retained CFDictionaryRef)keychainQuery,
                            (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)keyData];
        } @catch (NSException *e) {
            NSLog(@"提取数据失败\nUnarchive of %@ failed: %@", service, e);
        } @finally {
        }
    }
    return ret;
}

- (void)deleteDataInService:(NSString *)service {
    NSMutableDictionary *keyChainData = [self getKeyChainDataWithService:service];
    SecItemDelete((__bridge_retained CFDictionaryRef)keyChainData);
}

- (void)saveUserName:(NSString *)userName passWord:(NSString *)passWord {
    NSMutableDictionary *userNameDict = [NSMutableDictionary new];
    [userNameDict setObject:userName forKey:KEY_USERNAME];

    NSMutableDictionary *passWordDict = [NSMutableDictionary new];
    [passWordDict setObject:passWord forKey:KEY_PASSWORD];

    [self saveTargetData:userNameDict ToService:USERNAMEKEY_IN_KEYCHAIN];
    [self saveTargetData:passWordDict ToService:PASSWORDKEY_IN_KEYCHAIN];
}

- (NSDictionary *)getUserNameAndPassWord{
    NSMutableDictionary *userNameDict = [NSMutableDictionary new];
    NSMutableDictionary *passWordDict = [NSMutableDictionary new];
    userNameDict = (NSMutableDictionary *)[
                                           [FGKeyChainUDID shareKeyChainUDID] loadDataInService:USERNAMEKEY_IN_KEYCHAIN];
    passWordDict = (NSMutableDictionary *)[
                                           [FGKeyChainUDID shareKeyChainUDID] loadDataInService:PASSWORDKEY_IN_KEYCHAIN];
    NSString *userName = [userNameDict objectForKey:KEY_USERNAME];
    NSString *password = [passWordDict objectForKey:KEY_PASSWORD];
    NSMutableDictionary *targetDict = [[NSMutableDictionary alloc]init];
    [targetDict setObject:userName forKey:@"userName"];
    [targetDict setObject:password forKey:@"password"];
    return targetDict;
}


@end
