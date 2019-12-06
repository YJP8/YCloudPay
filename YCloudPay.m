//
//  YCloudPay.m
//  LifeService-Ass
//
//  Created by Levante on 2019/12/5.
//  Copyright © 2019 FansLift. All rights reserved.
//

#import "YCloudPay.h"
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>

@interface YCloudPay ()<WXApiDelegate>

@property (nonatomic, copy) void(^PaySuccess)(PayCode code);
@property (nonatomic, copy) void(^PayError)(PayCode code, NSString *message);

@end

@implementation YCloudPay

static id _instance;

+ (instancetype)sharedApi {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[YCloudPay alloc] init];
    });
    
    return _instance;
}

///回调处理
- (BOOL) handleOpenURL:(NSURL *) url {
    if ([url.host isEqualToString:@"safepay"]) {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
             //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
            
            NSInteger resultCode = [resultDic[@"resultStatus"] integerValue];
            switch (resultCode) {
                case 9000:     //支付成功
                    self.PaySuccess(ALIPAYSUCESS);
                    break;
                    
                case 6001:     //支付取消
                    self.PayError(ALIPAYCANCEL, @"支付取消");
                    break;
                    
                default:        //支付失败
                    self.PayError(ALIPAYERROR, @"支付失败");
                    break;
            }
        }];
        
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
        return YES;
    } //([url.host isEqualToString:@"pay"]) //微信支付
    return [WXApi handleOpenURL:url delegate:self];
}

///微信支付
- (void)wxPayWithPayParam:(NSDictionary *)pay_param
                  success:(void (^)(PayCode))successBlock
                  failure:(void (^)(PayCode, NSString * _Nonnull))failBlock {
    self.PaySuccess = successBlock;
    self.PayError = failBlock;
    
    NSString *partnerid = pay_param[@"Mch_id"];
    NSString *prepayid = pay_param[@"Prepay_id"];
    NSString *package = @"Sign=WXPay";
    NSString *noncestr = pay_param[@"Nonce_str"];
    NSString *timestamp = pay_param[@"Timestamp"];
    NSString *sign = pay_param[@"Sign"];
    
    if(![WXApi isWXAppInstalled]) {
        failBlock(WXERROR_NOTINSTALL, @"未安装微信");
        return ;
    }
    if (![WXApi isWXAppSupportApi]) {
        failBlock(WXERROR_UNSUPPORT, @"微信不支持");
        return ;
    }
    
    //发起微信支付
    PayReq* req   = [[PayReq alloc] init];
    //微信分配的商户号
    req.partnerId = partnerid;
    //微信返回的支付交易会话ID
    req.prepayId  = prepayid;
    // 随机字符串，不长于32位
    req.nonceStr  = noncestr;
    // 时间戳
    req.timeStamp = timestamp.intValue;
    //暂填写固定值Sign=WXPay
    req.package   = package;
    //签名
    req.sign      = sign;
    [WXApi sendReq:req];
    
    //日志输出
    //NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",appid,req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );
}

#pragma mark - 微信回调
// 微信终端返回给第三方的关于支付结果的结构体
- (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[PayResp class]]) {
        switch (resp.errCode) {
            case WXSuccess:
                self.PaySuccess(WXSUCESS);
                break;
                
            case WXErrCodeUserCancel:   //用户点击取消并返回
                self.PayError(WXSCANCEL, @"您取消了支付");
                break;
                
            default:        //剩余都是支付失败
                self.PayError(WXERROR, @"支付失败");
                break;
        }
    }
}

#pragma mark 支付宝支付
- (void)aliPayWithPayParam:(NSString *)pay_param
                   success:(void (^)(PayCode code))successBlock
                   failure:(nonnull void (^)(PayCode, NSString * _Nonnull message))failBlock {
    self.PaySuccess = successBlock;
    self.PayError = failBlock;
    //应用注册scheme,在AliSDKDemo-Info.plist定义URL types
    NSString *appScheme = @"LifeService-Ass";
    [[AlipaySDK defaultService] payOrder:pay_param fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        NSLog(@"----- %@",resultDic);
        NSInteger resultCode = [resultDic[@"resultStatus"] integerValue];
        switch (resultCode) {
            case 9000:     //支付成功
                successBlock(ALIPAYSUCESS);
                break;
                
            case 6001:     //支付取消
                failBlock(ALIPAYCANCEL, @"您取消了支付");
                break;
                
            default:        //支付失败
                failBlock(ALIPAYERROR, @"支付失败");
                break;
        }
    }];
}

@end
