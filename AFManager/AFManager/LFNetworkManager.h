//
//  LFNetworkManager.h
//  AFManager
//
//  Created by shancheli on 15/12/28.
//  Copyright © 2015年 shancheli. All rights reserved.
//

#import <Foundation/Foundation.h>

//网络状态成功回调
typedef void (^ReachabilitySuccessBlock)(BOOL status);


//网络访问成功、失败回调
typedef void(^ResultBlock)(id responseobject,NSError *error);


//下载的回调
typedef void(^DownloadBlock)(id responseo,id filepath,NSError *error);


//下载的回调
typedef void(^DownloadBlock)(id responseo,id filepath,NSError *error);


//下载进度回调
typedef void (^DownloadProgressBlock)(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile);



//上传的回调
typedef void(^uploadBlock)(NSURLSessionDataTask *task,id responseObject,NSError *error);



//网络请求类型
typedef NS_ENUM(NSUInteger,RequestType) {
    POST,
    GET
};


@interface LFNetworkManager : NSObject


@property(nonatomic,assign)BOOL NetStatus;



+(instancetype)sharedManager;


/**
 *  网络状态
 */
+(void)ReachabilityBlock:(ReachabilitySuccessBlock)success;



/**
 *   监听网络状态的变化
 *   在appdelegate中添加，即可在项目中监控网络状态的变化
 */
+ (void)startMonitoring;


/**
 *  网络访问
 *  type : 访问类型，get、post
 *  urlString : url
 *  parameters: 参数
 */
-(void)RequestType:(RequestType)type Url:(NSString *)urlString parameters:(id)parameters requestblock:(ResultBlock)resultBlock;


/**
 *  下载
 *  urlString : 下载地址
 *  downloadpath : 保存的路径
 *
 */
-(void)DownloadUrl:(NSString *)urlString downloadpath:(NSString *)downloadpath downloadblock:(DownloadBlock)downloadblock;


/**
 *  带有下载进度的下载
 *  urlString : 下载地址
 *  downloadpath : 保存的路径
 *  resultBlock: 下载完成或者失败的回调
 *  DownloadProgressBlock: 下载过程的回调
 *  bytesRead : 下载地址
 *  totalBytesRead : 下载地址
 *  totalBytesExpected : 下载地址
 *  totalBytesReadForFile : 已下载的文件大小
 *  totalBytesExpectedToReadForFile : 文件总大小
 */
-(void)DownloadUrl:(NSString *)urlString downloadpath:(NSString *)downloadpath requestblock:(ResultBlock)resultBlock Progress:(DownloadProgressBlock)DownloadProgressBlock;

/**
 *  上传单张照片
 *  urlString : 上传的url
 *  dic : 上传用到的参数
 *  imagData : 图片的二进制数据
 *
 */
-(void)UploadUrl:(NSString*)uploadpath parameters:(NSDictionary *)dic imageData:(NSData *)imagData uploadblock:(uploadBlock)uploadblock;


/**
 *  上传多张照片
 *  urlString : 上传的url
 *  dic : 上传用到的参数
 *  DataARR : 保存图片的二进制数据 的数组
 *
 */
-(void)UploadUrl:(NSString*)uploadpath parameters:(NSDictionary *)dic DataARR:(NSMutableArray *)DataARR uploadblock:(uploadBlock)uploadblock;



/**
 *  取消网络访问
 *  url : 要取消的url
 *
 */
+(void)CancelAllRequest;

-(void)CancelRequest:(NSString*)url;



@end
