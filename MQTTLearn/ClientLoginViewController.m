//
//  ClientLoginViewController.m
//  MQTTLearn
//
//  Created by lxy on 2017/8/25.
//  Copyright © 2017年 李选雁. All rights reserved.
//  MQTT 登录连接

#import "ClientLoginViewController.h"

#import <MQTTClient/MQTTClient.h>

#define MQTT_HOST @"10.98.56.191"
#define MQTT_PORT 1883

#define MQTT_TOPIC @"example"

@interface ClientLoginViewController ()<MQTTSessionDelegate>

@property (nonatomic,strong)MQTTSession *mqttSession;

@property (nonatomic,strong)MQTTCFSocketTransport *socketTransport;

@end

@implementation ClientLoginViewController

-(MQTTSession *)mqttSession
{
    if (_mqttSession == nil)
    {
        _mqttSession = [[MQTTSession alloc]init];
    }
    
    return _mqttSession;
}

-(MQTTCFSocketTransport *)socketTransport
{
    if (_socketTransport == nil)
    {
        _socketTransport = [[MQTTCFSocketTransport alloc]init];
    }
    
    return _socketTransport;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //创建MQTTSession
    [self createMQTTSession];
}

#pragma mark-   创建MQTTSession
- (void)createMQTTSession
{
    self.socketTransport.host = MQTT_HOST;
    self.socketTransport.port = MQTT_PORT;
    
    self.mqttSession.transport = self.socketTransport;
    self.mqttSession.delegate = self;
    
    [self.mqttSession connectAndWaitTimeout:10];
}

#pragma mark- MQTTSessionDelegate
- (void)connected:(MQTTSession *)session
{
    [self.mqttSession subscribeTopic:MQTT_TOPIC];
}

/*连接状态回调*/
-(void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error{
    NSDictionary *events = @{
                             @(MQTTSessionEventConnected): @"connected",
                             @(MQTTSessionEventConnectionRefused): @"账号或密码错误，服务器拒绝连接",
                             @(MQTTSessionEventConnectionClosed): @"connection closed",
                             @(MQTTSessionEventConnectionError): @"connection error",
                             @(MQTTSessionEventProtocolError): @"protocoll error",
                             @(MQTTSessionEventConnectionClosedByBroker): @"connection closed by broker"
                             };
    NSLog(@"-----------------MQTT连接状态%@-----------------",[events objectForKey:@(eventCode)]);
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    NSString *jsonStr=[NSString stringWithUTF8String:data.bytes];
    NSLog(@"-----------------MQTT收到消息主题：%@内容：%@",topic,jsonStr);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
