//
//  YCloudPay.h
//  LifeService-Ass
//
//  Created by Levante on 2019/12/5.
//  Copyright © 2019 FansLift. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PayCode) {
    
    WXSUCESS            = 1001,   /**< 成功    */
    WXERROR             = 1002,   /**< 失败    */
    WXSCANCEL           = 1003,   /**< 取消    */
    WXERROR_NOTINSTALL  = 1004,   /**< 未安装微信   */
    WXERROR_UNSUPPORT   = 1005,   /**< 微信不支持    */
    WXERROR_PARAM       = 1006,   /**< 支付参数解析错误   */
    
    ALIPAYSUCESS        = 1101,   /**< 支付宝支付成功 */
    ALIPAYERROR         = 1102,   /**< 支付宝支付错误 */
    ALIPAYCANCEL        = 1103,   /**< 支付宝支付取消 */
};


@interface YCloudPay : NSObject


/**
 *  获取单例
 */
+ (instancetype)sharedApi;

/**
 *  发起微信支付请求
 *
 *  @param pay_param    支付参数 json串
 *  @param successBlock 成功
 *  @param failBlock    失败
 */
- (void)wxPayWithPayParam:(NSDictionary *)pay_param
                  success:(void (^)(PayCode code))successBlock
                  failure:(void (^)(PayCode code, NSString *message))failBlock;

/**
 *  发起支付宝支付请求
 *
 *  @param pay_param    支付参数，订单信息
 *  @param successBlock 成功
 *  @param failBlock    失败
 */
- (void)aliPayWithPayParam:(NSString *)pay_param
                  success:(void (^)(PayCode code))successBlock
                  failure:(void (^)(PayCode code, NSString *message))failBlock;



/// 支付回调
/// @param url url
- (BOOL) handleOpenURL:(NSURL *) url;


@end

NS_ASSUME_NONNULL_END
