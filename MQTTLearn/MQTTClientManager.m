//
//  MQTTClientManager.m
//  MQTTLearn
//
//  Created by lxy on 2017/8/25.
//  Copyright © 2017年 李选雁. All rights reserved.
//

#import "MQTTClientManager.h"


#define NNSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface MQTTClientManager ()<MQTTSessionManagerDelegate>

@property (nonatomic,strong)MQTTSessionManager *mqttManager;


/**
 是否使用tls协议，mosca是支持tls的，如果使用了要设置成true
 */
@property (nonatomic,assign)BOOL tls;

/**
 session是否清除，这个需要注意，如果是false，代表保持登录，如果客户端离线了再次登录就可以接收到离线消息
 */
@property (nonatomic,assign)BOOL clean;

/**
 是否使用登录验证
 */
@property (nonatomic,assign)BOOL auth;

@property (nonatomic,assign)BOOL willRetainFlag;

/**
 服务器端口
 */
@property (nonatomic,assign) NSInteger port;

/**
 心跳时间，单位秒，每隔固定时间发送心跳包, 心跳间隔不得大于120s
 */
@property (nonatomic,assign) NSInteger keepalive;

/**
 接收离线消息的级别
 */
@property (nonatomic,assign) MQTTQosLevel willQos;
/**
 服务器地址
 */
@property (nonatomic,copy)NSString *host;

/**
 用户名
 */
@property (nonatomic,copy)NSString *user;

/**
 密码
 */
@property (nonatomic,copy)NSString *pass;

/**
 订阅主题
 */
@property (nonatomic,copy)NSString *willTopic;

/**
 客户端id，需要特别指出的是这个id需要全局唯一，因为服务端是根据这个来区分不同的客户端的，默认情况下一个id登录后，假如有另外的连接以这个id登录，上一个连接会被踢下线, 我使用的设备UUID
 */
@property (nonatomic,copy)NSString *clientId;


@property (nonatomic,strong)NSData *will;

/**
 自定义的离线消息
 */
@property (nonatomic,strong)NSData *willMsg;

@end

@implementation MQTTClientManager

+ (MQTTClientManager *)shareManager
{
    static MQTTClientManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MQTTClientManager alloc]init];
    });
    
    return manager;
}

-(MQTTSessionManager *)mqttManager
{
    if (_mqttManager == nil)
    {
        _mqttManager = [[MQTTSessionManager alloc]init];
        _mqttManager.delegate = self;
    }
    
    return _mqttManager;
}

#pragma mark- 连接服务器
- (void)connectTo:(NSString *)host
             port:(NSInteger)port
              tls:(BOOL)tls
        keepalive:(NSInteger)keepalive
            clean:(BOOL)clean
             auth:(BOOL)auth
             user:(NSString *)user
             pass:(NSString *)pass
             will:(NSData *)will
        willTopic:(NSString *)willTopic
          willMsg:(NSData *)willMsg
          willQos:(MQTTQosLevel)willQos
   willRetainFlag:(BOOL)willRetainFlag
     withClientId:(NSString *)clientId
{
    self.host = host;
    self.port = port;
    self.tls = tls;
    self.keepalive = keepalive;
    self.clean = clean;
    self.auth = auth;
    self.user = user;
    self.pass = pass;
    self.will = will;
    self.willTopic = willTopic;
    self.willMsg = willMsg;
    self.willQos = willQos;
    self.willRetainFlag = willRetainFlag;
    self.clientId = clientId;
    
    //连接服务器
    [self connectMQTTServer];
    
    //监听连接服务器的状态
    [self addSessionManagerConnectStatus];
}

#pragma mark- 连接服务器
- (void)connectMQTTServer
{
    [self.mqttManager connectTo:self.host port:self.port tls:self.tls keepalive:self.keepalive clean:self.clean auth:self.auth user:self.user pass:self.pass willTopic:self.willTopic will:self.will willQos:self.willQos willRetainFlag:self.willRetainFlag withClientId:self.clientId];
}

#pragma mark-  发送数据
- (void)sendData:(NSData *)sendMsg
{
    [self.mqttManager sendData:sendMsg topic:self.willTopic qos:self.willQos retain:false];
}

#pragma mark-  断开连接
- (void)close
{
    //断开
    [self.mqttManager disconnect];
    
    self.delegate = nil;
    self.mqttManager = nil;
    self.host = nil;
    self.port = 0;
    self.tls = false;
    self.keepalive = 0;
    self.clean = false;
    self.auth = false;
    self.user = nil;
    self.pass = nil;
    self.willTopic = nil;
    self.will = nil;
    self.willQos = 0;
    self.willRetainFlag = false;
    self.clientId = nil;
}

#pragma mark- 添加监听连接的状态
- (void)addSessionManagerConnectStatus
{
    [self.mqttManager addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
}

#pragma mark- 监听当前连接状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    switch (self.mqttManager.state)
    {
        case MQTTSessionManagerStateStarting:
        { //开始连接
            NNSLog(@"开始连接");
            break;
        }
        case MQTTSessionManagerStateConnecting:
        {  //正在连接
            NNSLog(@"正在连接");
            break;
        }
        case MQTTSessionManagerStateConnected:
        {   //已经连接
            NNSLog(@"已经连接");
            break;
        }
        case MQTTSessionManagerStateError:
        {   //连接异常
            NNSLog(@"连接异常");
            break;
        }
        case MQTTSessionManagerStateClosing:
        {   //连接正在关闭
            NNSLog(@"连接正在关闭");
            break;
        }
        case MQTTSessionManagerStateClosed:
        {   //连接已经关闭
            NNSLog(@"连接已经关闭");
            break;
        }
        default:
            break;
    }
}

#pragma mark- MQTTSessionManagerDelegate
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained
{
    NSString *handleMsg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NNSLog(@"handleMessage:%@",handleMsg);
}

#pragma mark- 接收消息
- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained
{
    NSString *reciveMsg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NNSLog(@"收到消息ReceiveMessage:%@",reciveMsg);
}

@end
