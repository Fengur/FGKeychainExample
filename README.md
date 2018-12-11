# FGKeychainExample
Share keychain data between apps
## 一、利用KeyChain生成靠谱的UDID
#### 首先我们回顾一下iOS不同版本获取机器UDID的方法
- **iOS 5.0**
iOS 2.0以后**UIDevice**提供一个获取设备唯一标识符的方法**uniqueIdentifier**，通过该方法我们可以获取设备的序列号，这个也是目前为止唯一可以确认官方提供的唯一标示符。但是由于该方法过于敏感，获取的唯一标识符与手机一一对应，Apple觉得可能会泄露用户隐私，所以在 iOS 5.0之后该方法就被舍弃了。
因为舍弃的代码依然被调用，苹果公司规定上传到App Store的产品都不允许再使用uniqueIdentifier方法，代码使用到被检测就会被干回幼儿园重念，所以这条路基本上是被pass掉了。
- **iOS 6.0**
iOS6新增了两个用于代替**uniqueIdentifier**的接口：**identifierForVendor**，**advertisingIdentifier**
**identifierForVendor**

>The value of this property is the same for apps that come from the same vendor running on the same device. A different value is returned for apps on the same device that come from different vendors, and for apps on different devices regardless of vendor. The value of this property may be nil if the app is running in the background, before the user has unlocked the device the first time after the device has been restarted. If the value is nil, wait and get the value again later. The value in this property remains the same while the app (or another app from the same vendor) is installed on the iOS device. The value changes when the user deletes all of that vendor’s apps from the device and subsequently reinstalls one or more of them. Therefore, if your app stores the value of this property anywhere, you should gracefully handle situations where the identifier changes.

意思就是通过这个方法获取到的ID，会在卸载重装之后被重置，所以这条路也是不通的了。
但是程序员毕竟是统治世界的真正能力者，所以大家想到了使用WiFi的mac地址来标识设备。具体实施的方法大家可以在网上翻一翻，小型 [传送门]([http://stackoverflow.com/questions/677530/how-can-i-programmatically-get-the-mac-address-of-an-iphone](http://stackoverflow.com/questions/677530/how-can-i-programmatically-get-the-mac-address-of-an-iphone))。

- **iOS 7.0**　
iOS7之前大家使用的mac地址再次得到苹果霸霸的制裁，使用之前的方法获取到的mac地址全部都变成了02:00:00:00:00:00，在网上零零星星的听见别人说啥**keyChain**可以的，仔细研究了一下，测试了一波,发现确实比较靠谱。

###什么是KeyChain
从事iOS开发的筒子大部分用的都是苹果本，即使使用黑苹果也一定都知道OS系统中有一个**KeyChain**(钥匙串)，在早期的开发中，真机调试都是需要安装证书的，这些证书就是保存在**KeyChain**中，还有我们平时在**chrome**和**safari**中保存的账号和密码都是存在**keychain**中的，有些时候我们忘记了密码想去看一下，也要去到**keychain**中找。iOS系统只有一个**KeyChain**，每个程序都可以往**KeyChain**中记录数据，而且只能读取到自己程序（或者**约定好的小伙伴**）记录在**KeyChain**中的数据。iOS中**Security.framework**提供了四个方法来操作**KeyChain**中的数据。官方文档 [传送门](https://developer.apple.com/reference/security/1658642-keychain_services#//apple_ref/doc/uid/TP30000898)
> 查询
 OSStatus SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result);

>添加 
OSStatus SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result);

> 更新
OSStatus SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);   

>删除
 OSStatus SecItemDelete(CFDictionaryRef query) 


这里让我们来使用**KeyChain**获取一波UDID

```
#import "FGKeyChainUDID.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

#define KEY_UDID @"KEY_UDID"
#define KEY_IN_KEYCHAIN @"KEY_IN_KEYCHAIN"

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
 // 存在直接取出，不存在进行创建-存储-取出
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
```
## 二、利用KeyChain进行多应用的数据共享，账号共用。
**应用场景**:之前我在使用美团团购app的时候，发现我打开应用并没有注册，它已经读取到了我美图外卖中的美团账号进入了app，只需要添加少量个人信息就可以正常使用，在使用百度贴吧时，发现贴吧也可以读取其他百度产品的百度账号，瞬间觉得高大厦，因为大家都知道iOS的沙盒机制，在没有打开应用的前提下，他就获取到了目标数据，这跟传统的SSO是有本质区别了，一番研究发现，他们是用到了keyChain来完成这个功能。经过好久之前一个下午的摸索，实现了这个乍一看很吊的功能。

- 创建两个Demo，一个 用于存，一个用于取。

![图片.png](http://upload-images.jianshu.io/upload_images/1155603-ee99275968cbbe10.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
**FGKeyChainDemo**用于存储数据,**FGKeyChainVerifyDemo**用去提取和验证数据
- 给两个工程都添加**KeyChain Sharing**

![图片.png](http://upload-images.jianshu.io/upload_images/1155603-ee7a8ec543789895.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
**注意**：这里两个应用的**keyChainGroups**必须处于互相包含状态

然后两个工程中都会见到如下**entitlements**


![图片.png](http://upload-images.jianshu.io/upload_images/1155603-03d1cda3fc27abf6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![图片.png](http://upload-images.jianshu.io/upload_images/1155603-665900a43cae6174.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

到这里就已经配置完毕，为了存储数据代码方便，这里用到我写的一小工具类，两个工程都导入一份。这里为了方便测试，给它提供一个直接存储两个数据的方法。
```
- (void)saveUserName:(NSString *)userName passWord:(NSString *)passWord;
```

![图片.png](http://upload-images.jianshu.io/upload_images/1155603-4b59fcae79c013d8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**注意**：两个工程所访问的**KeyChain**是同一个,所以我们需要共享的数据需要有一个约定好的key，例如百度搜索和百度贴吧，访问的为**BaiduKey**(只做假设，便于理解)，这样才能够保证数据的统一性。

```
// 用户名
#define KEY_USERNAME @"KEY_USERNAME"
#define USERNAMEKEY_IN_KEYCHAIN @"USERNAMEKEY_IN_KEYCHAIN"
// 密码
#define KEY_PASSWORD @"KEY_PASSWORD"
#define PASSWORDKEY_IN_KEYCHAIN @"PASSWORDKEY_IN_KEYCHAIN"

```
在**FGKeyChainDemo**中存入数值

![图片.png](http://upload-images.jianshu.io/upload_images/1155603-98ec926eb1ffd29a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


```
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

```
执行完这个操作以后，在**FGKeyChainVerifyDemo**执行读取数据操作来刷新UI

```
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
```
见证小奇迹的时刻就这样的到了，在不打开应用的时候，已经取到了另一个的账号和密码。
![图片.png](http://upload-images.jianshu.io/upload_images/1155603-cd0134efb29a3e82.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

测试工程 [传送门](https://github.com/Fengur/FGKeychainExample),如有错误或需要补充，敬请指出。
