//
//  ViewController.m
//  MQTTLearn
//
//  Created by 李选雁 on 2017/8/23.
//  Copyright © 2017年 李选雁. All rights reserved.
//

#import "ViewController.h"
#import "ClientLoginViewController.h"

#import <MQTTClient/MQTTClient.h>
#import "MQTTSessionManager.h"

#import "MQTTClientManager.h"

@interface ViewController ()<MQTTSessionManagerDelegate>

@property (nonatomic,strong) MQTTSessionManager *mySessionManager;

/**
 消息级别
 */
@property (nonatomic,assign) int qos;

/**
  发送的主题
 */
@property (nonatomic,copy) NSString *rootTopic;

@end

#define MQTT_HOST @"10.98.56.191"
#define MQTT_PORT 1883

#define MQTT_TOPIC @"topic_example"
#define MQTT_GROUPID @"GID_LXY_MQTT"
#define MQTT_PRODUCTID @"PID_LXY_MQTT"
#define MQTT_CUSTOMID @"CID_LXY_MQTT"
#define ACCESS_KeyID @"LTAIEaSAa5Az17Pd"
#define ACCESS_KeySECRET @"GluPKNdLfraFzNf70soOfHILzQPlFt"

#define NNSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (MQTTSessionManager *)mySessionManager
{
    if (_mySessionManager == nil)
    {
        _mySessionManager = [[MQTTSessionManager alloc]init];
        _mySessionManager.delegate = self;
        
        self.rootTopic = @"example";
        self.qos = 2;
    }
    
    return _mySessionManager;
}

- (IBAction)clientLogin:(id)sender
{
    ClientLoginViewController *clientLoginVC = [[ClientLoginViewController alloc]init];
    [self.navigationController pushViewController:clientLoginVC animated:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //连接
    [self sessionManagerConnect];
    
    //添加监听连接的状态
    [self addSessionManagerConnectStatus];
}

#pragma mark- 建立连接
/**
 host: 服务器地址
 port: 服务器端口
 tls:  是否使用tls协议，mosca是支持tls的，如果使用了要设置成true
 keepalive: 心跳时间，单位秒，每隔固定时间发送心跳包, 心跳间隔不得大于120s
 clean: session是否清除，这个需要注意，如果是false，代表保持登录，如果客户端离线了再次登录就可以接收到离线消息
 auth: 是否使用登录验证
 user: 用户名
 pass: 密码
 willTopic: 订阅主题
 willMsg: 自定义的离线消息
 willQos: 接收离线消息的级别
 clientId: 客户端id，需要特别指出的是这个id需要全局唯一，因为服务端是根据这个来区分不同的客户端的，默认情况下一个id登录后，假如有另外的连接以这个id登录，上一个连接会被踢下线, 我使用的设备UUID
 */
- (void)sessionManagerConnect
{
    self.rootTopic = @"example";
    self.qos = 2;
    NSString *clientId = [UIDevice currentDevice].identifierForVendor.UUIDString;
    [self.mySessionManager connectTo:MQTT_HOST port:MQTT_PORT tls:false keepalive:60 clean:true auth:false user:nil pass:nil will:false willTopic:self.rootTopic willMsg:nil willQos:self.qos willRetainFlag:false withClientId:clientId ];
    
    
//     [[MQTTClientManager shareManager]connectTo:MQTT_HOST port:MQTT_PORT tls:false keepalive:60 clean:true auth:false user:nil pass:nil will:nil willTopic:self.rootTopic willMsg:nil willQos:self.qos willRetainFlag:false withClientId:clientId];
//    
//    NSString *sendMsg = @"MQTTClient_TestMsg";
//    NSData *sendData = [sendMsg dataUsingEncoding:NSUTF8StringEncoding];
//    [[MQTTClientManager shareManager]sendData:sendData];
}

#pragma mark- 订阅主题
- (void)subscribeToTopic
{
    self.mySessionManager.subscriptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:self.qos]                                                                  forKey:[NSString stringWithFormat:@"%@", self.rootTopic]];
    
    NSString *msg = @"lxyTest";
    NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [self.mySessionManager sendData:msgData topic:self.rootTopic qos:self.qos retain:false];
}

#pragma mark- 添加监听连接的状态
- (void)addSessionManagerConnectStatus
{
    [self.mySessionManager addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
}

#pragma mark- 监听当前连接状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    switch (self.mySessionManager.state)
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
            
            //订阅主题
            [self subscribeToTopic];
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
#pragma mark 获取服务器返回的数据
- (void)sessionManager:(MQTTSessionManager *)sessionManager
     didReceiveMessage:(NSData *)data
               onTopic:(NSString *)topic
              retained:(BOOL)retained
{
    NSString *msgStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
     NNSLog(@"接收到的数据topic:%@,msg:%@",topic,msgStr);
}

- (void)sessionManager:(MQTTSessionManager *)sessionManager didDeliverMessage:(UInt16)msgID
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
