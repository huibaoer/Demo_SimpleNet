//
//  SimpleNet.h
//  AllLivePlayer
//
//  Created by GrayLeo on 2017/3/7.
//  Copyright © 2017年 hzky. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SuccessHandler)(NSURLResponse *response, NSData *data, NSString *resultStr, NSDictionary *resultDic);
typedef void (^FailedHandler)(NSURLResponse *response, NSData *data, NSString *resultStr, NSDictionary *resultDic, NSError *error);

@interface SimpleNet : NSObject

+ (instancetype)sharedInstance;

- (void)getWithUrlString:(NSString *)url
              parameters:(NSDictionary *)parameters
                 success:(SuccessHandler)successHandler
                 failure:(FailedHandler)failedHandler;

- (void)postWithUrlString:(NSString *)url
               parameters:(NSDictionary *)parameters
                  success:(SuccessHandler)successHandler
                  failure:(FailedHandler)failedHandler;

@end
