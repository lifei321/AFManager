
//
//  LFNetworkManager.m
//  AFManager
//
//  Created by shancheli on 15/12/28.
//  Copyright © 2015年 shancheli. All rights reserved.
//

#define BaseUrl @"http"

#import "LFNetworkManager.h"
#import "AFNetworkReachabilityManager.h"
#import "AFNetworking.h"
#import "AFDownloadRequestOperation.h"

// MD5加密
#import <CommonCrypto/CommonDigest.h>

@interface LFNetworkManager ()

@property(nonatomic,strong)AFHTTPSessionManager* Manager;

@property (nonatomic, retain) NSURLSessionTask *task;


@end

@implementation LFNetworkManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        
        NSURL* url = [NSURL URLWithString:BaseUrl];
        
        _Manager = [[AFHTTPSessionManager alloc]initWithBaseURL:url];
        
        //最多同时进行5个操作
        _Manager.operationQueue.maxConcurrentOperationCount = 5;
        
        //请求超时时间
        _Manager.requestSerializer.timeoutInterval = 15;
        
        
        
        
        /*********序列化*********/
        
        // 默认请求二进制
        // 默认响应是JSON
        
        // 告诉AFN，支持接受 这几种格式 的数据
//        AFJSONResponseSerializer * response = [AFJSONResponseSerializer serializer];
//         response.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/plain", @"text/html",@"text/javascript", nil];
        
        // 告诉AFN如何解析数据
        // 告诉AFN客户端, 将返回的数据当做JSON来处理，默认的是以JSON处理
//        AFJSONResponseSerializer * Jsonresponse = [AFJSONResponseSerializer serializer];
//        Jsonresponse.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/plain", @"text/html",@"text/javascript", nil];
//        _Manager.responseSerializer = Jsonresponse;
//        
//        // 告诉AFN客户端, 将返回的数据当做XML来处理
//        AFXMLParserResponseSerializer * XMLresponse = [AFXMLParserResponseSerializer serializer];
//        XMLresponse.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/plain", @"text/html",@"text/javascript", nil];
//        _Manager.responseSerializer = XMLresponse;
        
        // 告诉AFN客户端, 将返回的数据当做而进行来数据 (服务器返回什么就是什么)
        AFHTTPResponseSerializer * response = [AFHTTPResponseSerializer serializer];
        response.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/plain", @"text/html",@"text/javascript", nil];
        
        _Manager.responseSerializer = response;
        
    }
    return self;
}

#pragma mark-   单例
+(instancetype)sharedManager
{
    static LFNetworkManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedManager = [[LFNetworkManager alloc]init];
    });
    
    return sharedManager;
}


#pragma mark-   获取网络状态
+ (void)ReachabilityBlock:(ReachabilitySuccessBlock)success
{
    AFNetworkReachabilityManager *ReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    
    [ReachabilityManager startMonitoring];
    
    [ReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        if (status == 0) {
            
            success(NO);
            
        }else if (status == 1){
            success(YES);
            
        }else if (status == 2){
            success(YES);
            
        }
    }];
}

#pragma makr- 开始监听网络连接

+ (void)startMonitoring
{
    // 1.获得网络监控的管理者
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    // 2.设置网络状态改变后的处理
    [mgr setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        // 当网络状态改变了, 就会调用这个block
        switch (status)
        {
            case AFNetworkReachabilityStatusUnknown: // 未知网络
                [LFNetworkManager sharedManager].NetStatus = YES;
                break;
            case AFNetworkReachabilityStatusNotReachable: // 没有网络(断网)
                [LFNetworkManager sharedManager].NetStatus = NO;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
                [LFNetworkManager sharedManager].NetStatus = YES;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi: // WIFI
                [LFNetworkManager sharedManager].NetStatus = YES;
                break;
        }
    }];
    [mgr startMonitoring];
}

#pragma mark-   普通网络访问get post
-(void)RequestType:(RequestType)type Url:(NSString *)urlString parameters:(id)parameters requestblock:(ResultBlock)resultBlock
{
    switch (type) {
        case GET:
        {
            [_Manager GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                
                resultBlock(responseObject,nil);
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                
                resultBlock(nil,error);
                
            }];
        }
            break;
        case POST:
        {
            [_Manager POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                
                resultBlock(responseObject,nil);
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                
                resultBlock(nil,error);
                
            }];
        }
            break;
        default:
            break;
    }
}

#pragma mark-   下载
-(void)DownloadUrl:(NSString *)urlString downloadpath:(NSString *)downloadpath downloadblock:(DownloadBlock)downloadblock
{
    NSProgress *progress = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    self.task = [_Manager downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        
        NSURL *desturl = [NSURL fileURLWithPath:downloadpath];
        return desturl;
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        downloadblock(response,filePath,error);
        
    }];
    
    [self.task resume];
}

#pragma mark-   带有下载进度的下载
-(void)DownloadUrl:(NSString *)urlString downloadpath:(NSString *)downloadpath requestblock:(ResultBlock)resultBlock Progress:(DownloadProgressBlock)DownloadProgressBlock
{
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3600];
    
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:downloadpath shouldResume:YES];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        resultBlock(responseObject,nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        resultBlock(nil,error);
    }];
    
    [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        
        
        DownloadProgressBlock(bytesRead,totalBytesRead,totalBytesExpected,totalBytesReadForFile,totalBytesExpectedToReadForFile);
        
//        float percentDone = totalBytesReadForFile/(float)totalBytesExpectedToReadForFile;
//        
//        self.progressView.progress = percentDone;
//        self.progressLabel.text = [NSString stringWithFormat:@"%.0f%%",percentDone*100];
//        
//        self.currentSizeLabel.text = [NSString stringWithFormat:@"CUR : %lli M",totalBytesReadForFile/1024/1024];
//        
//        self.totalSizeLabel.text = [NSString stringWithFormat:@"TOTAL : %lli M",totalBytesExpectedToReadForFile/1024/1024];
        
//        NSLog(@"------%f",percentDone);
//        NSLog(@"Operation%i: bytesRead: %d", 1, bytesRead);
//        NSLog(@"Operation%i: totalBytesRead: %lld", 1, totalBytesRead);
//        NSLog(@"Operation%i: totalBytesExpected: %lld", 1, totalBytesExpected);
//        NSLog(@"Operation%i: totalBytesReadForFile: %lld", 1, totalBytesReadForFile);
//        NSLog(@"Operation%i: totalBytesExpectedToReadForFile: %lld", 1, totalBytesExpectedToReadForFile);
        
    }];
    [operation start];
}


//MD5
- (NSString*)md5String:(NSString*)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[32];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    // 先转MD5，再转大写
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
    
}

//上传到服务器的文件名称
- (NSString *)fileName
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-mm-dd"];
    NSString *time = [NSString stringWithFormat:@"%@",[formatter stringFromDate:currentDate]];
    return [NSString stringWithFormat:@"%@.png",[self md5String:time]];
}

#pragma mark-   上传单张
-(void)UploadUrl:(NSString*)uploadpath parameters:(NSDictionary *)dic imageData:(NSData *)imagData uploadblock:(uploadBlock)uploadblock
{
    [_Manager POST:uploadpath parameters:dic constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
//        [formData appendPartWithFormData:imagData name:@"1"];
        /*
         第一个参数: 需要上传的文件二进制
         第二个参数: 服务器对应的参数名称
         第三个参数: 文件的名称
         第四个参数: 文件的MIME类型
         */
        [formData appendPartWithFileData:imagData name:@"file" fileName:[self fileName] mimeType:@"image/png"];
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        uploadblock(task,responseObject,nil);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        uploadblock(task,nil,error);
        
    }];

}

#pragma mark-  上传多张
-(void)UploadUrl:(NSString*)uploadpath parameters:(NSDictionary *)dic DataARR:(NSMutableArray *)DataARR uploadblock:(uploadBlock)uploadblock
{
    [_Manager POST:uploadpath parameters:dic constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        for (int i = 0; i < DataARR.count; i++) {
            NSData* imagData = DataARR[i];
            [formData appendPartWithFormData:imagData name:@"1"];
            /*
             第一个参数: 需要上传的文件二进制
             第二个参数: 服务器对应的参数名称
             第三个参数: 文件的名称
             第四个参数: 文件的MIME类型
             */
            //        [formData appendPartWithFileData:data name:@"file" fileName:@"abc.png" mimeType:@"image/png"];
        }
        
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        uploadblock(task,responseObject,nil);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        uploadblock(task,nil,error);
        
    }];
}



+(void)CancelAllRequest
{
    [[LFNetworkManager sharedManager].Manager.operationQueue cancelAllOperations];
//    [_Manager.operationQueue cancelAllOperations];
}

-(void)CancelRequest:(NSString*)url
{
    
}

@end




