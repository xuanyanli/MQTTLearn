//
//  MQTTClientManager.h
//  MQTTLearn
//
//  Created by lxy on 2017/8/25.
//  Copyright © 2017年 李选雁. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MQTTSessionManager.h"

@protocol CustomeMQTTClientManagerDelegate <NSObject>

@optional

@end

@interface MQTTClientManager : NSObject

@property (nonatomic,assign)id<CustomeMQTTClientManagerDelegate>delegate;

+ (MQTTClientManager *)shareManager;

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
     withClientId:(NSString *)clientId;

/**
 发送数据
 */
- (void)sendData:(NSData *)sendMsg;

/**
 断开连接
 */
- (void)close;

@end
