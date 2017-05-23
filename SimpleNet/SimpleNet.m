//
//  SimpleNet.m
//  AllLivePlayer
//
//  Created by GrayLeo on 2017/3/7.
//  Copyright © 2017年 hzky. All rights reserved.
//

#import "SimpleNet.h"

#define CONNECT_TIMEOUT 20.0  //网络请求超时时间

@interface SimpleNet () <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *host;
@end

@implementation SimpleNet

+ (instancetype)sharedInstance {
    //todo-
    static SimpleNet *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SimpleNet alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 1;// 配置一次只能对服务器一个连接
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

- (void)getWithUrlString:(NSString *)url
              parameters:(NSDictionary *)parameters
                 success:(SuccessHandler)successHandler
                 failure:(FailedHandler)failedHandler {
    //拼接url和参数
    NSString *urlString = _host ? [_host stringByAppendingString:url] : url;
    NSMutableString *paramString = [NSMutableString string];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *curParam = [NSString stringWithFormat:@"%@%@=%@",paramString.length==0?@"?":@"&",key,obj];
        [paramString appendString:curParam];
    }];
    if (paramString.length > 0) {
        urlString = [urlString stringByAppendingString:paramString];
    }
    //编码一次，防止url里有汉字导致NSURL为nil的问题
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //创建request
    NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    rq.HTTPMethod = @"GET";
    rq.timeoutInterval = CONNECT_TIMEOUT;
    //添加header
    [self addCommonHeaderForRequest:rq];
    //加密request和参数
    
    //创建task
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:rq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self requestHandleWithData:data response:response error:error success:successHandler failure:failedHandler];
    }];
    [task resume];
}

- (void)postWithUrlString:(NSString *)url
               parameters:(NSDictionary *)parameters
                  success:(SuccessHandler)successHandler
                  failure:(FailedHandler)failedHandler {
    //url
    NSString *urlString = _host ? [_host stringByAppendingString:url] : url;
    //创建request
    NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    rq.HTTPMethod = @"POST";
    rq.timeoutInterval = CONNECT_TIMEOUT;
    //添加参数
    NSMutableString *bodyString = [NSMutableString string];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *appendStr = [NSString stringWithFormat:@"%@%@=%@",bodyString.length==0?@"":@"&",key,obj];
        [bodyString appendString:appendStr];
    }];
    NSMutableData *requestBody = [NSMutableData data];
    [requestBody appendData:[[bodyString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]dataUsingEncoding:NSUTF8StringEncoding]];
    [rq setHTTPBody:requestBody];
    
    //添加通用header 以及 数据签名
    [self addCommonHeaderForRequest:rq];
    //加密request和参数
    
    //创建task
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:rq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self requestHandleWithData:data response:response error:error success:successHandler failure:failedHandler];
    }];
    [task resume];
}

- (void)addCommonHeaderForRequest:(NSMutableURLRequest *)request {

}

- (void)requestHandleWithData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error success:(SuccessHandler)successHandler
                      failure:(FailedHandler)failedHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!data || error) {
            if (failedHandler) failedHandler(response, nil, nil, nil, error);
            return;
        }
        
        NSString *resultStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (successHandler) successHandler(response,data,resultStr,resultDic);
    });
}

#pragma mark - NSURLSessionDelegate 代理方法
//主要就是处理HTTPS请求的
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = protectionSpace.serverTrust;
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}


@end
