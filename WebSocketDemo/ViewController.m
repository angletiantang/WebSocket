//
//  SocketManager.h
//  WebSocketDemo
//  gitHub https://github.com/angletiantang
//  QQ 871810101
//  Created by guojianheng on 2018/4/2.
//  Copyright © 2018年 guojianheng. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
#import <SocketRocket.h>

#define WeakSelf __weak typeof(self) weakSelf = self;

@interface ViewController ()<SRWebSocketDelegate>

// webSocket对象
@property (nonatomic , strong)SRWebSocket * webSocket;
// 串行队列
@property (nonatomic , retain)dispatch_queue_t socketQueue;
// 判断是否有网络环境
@property (nonatomic , assign)BOOL isNetworkConnected;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 链接webSocket的方法;
    [self connectWebSocket];
}

// 链接webSocket的方法;
- (void)connectWebSocket
{
    // 创建一个请求对象
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://222.73.213.180:5050/AgentProxyServer"]];
    // 初始化webSocket
    self.webSocket = [[SRWebSocket alloc]initWithURLRequest:request];
    // 实现这个 SRWebSocketDelegate 协议啊
    self.webSocket.delegate = self;
    // open 就是直接连接了
    [self.webSocket open];
}

// 连接成功的代理方法
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"连接成功，可以立刻登录你公司后台的服务器了，还有开启心跳");
    // 连接成功法可以发送数据
    NSDictionary * messagetext= @{@"content":@"test",@"msgtype":@"text"};
    NSDictionary *dataDic = @{@"request":@"WeChatSend",@"openid":@"ohjPtjumsHjgUbd9-8VCXOhBLjkI",@"messagetext":messagetext};
    NSData *data= [NSJSONSerialization dataWithJSONObject:dataDic options:NSJSONWritingPrettyPrinted error:nil];
    [self sendData:data];
}

// 连接失败的代理方法

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"连接失败，这里可以实现掉线自动重连，要注意以下几点");
    NSLog(@"1.判断当前网络环境，如果断网了就不要连了，等待网络到来，在发起重连");
    NSLog(@"2.判断调用层是否需要连接，例如用户都没在聊天界面，连接上去浪费流量");
    NSLog(@"3.连接次数限制，如果连接失败了，重试10次左右就可以了，不然就死循环了。或者每隔1，2，4，8，10，10秒重连...f(x) = f(x-1) * 2, (x=5)");
}

// 关闭连接的代理方法
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"连接断开，清空socket对象，清空该清空的东西，还有关闭心跳！");
    self.webSocket = nil;
    [self.webSocket close];
    
}

// 收到服务器发来的数据会调用这个方法
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message  {
    NSLog(@"收到数据了，注意 message 是 id 类型的，学过C语言的都知道，id 是 (void *) void* 就厉害了，二进制数据都可以指着，不详细解释 void* 了");
    NSLog(@"我这后台约定的 message 是 json 格式数据收到数据，就按格式解析吧，然后把数据发给调用层");
    NSLog(@"%@",message);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"WebSocket received pong");
}

// 向服务器发送数据
// 发送的时候可能断网，可能socket还在连接，要判断一些情况，写在下面了
// 发送逻辑是，我有一个 socketQueue 的串行队列，发送请求会加到这个队列里，然后一个一个发出去，如果掉线了，重连连上后继续发送，对调用层透明，调用层不需要知道网络断开了。
- (void)sendData:(id)data {
    
    NSLog(@"%@",data);
    self.socketQueue = dispatch_queue_create("mySocketQueue", DISPATCH_QUEUE_SERIAL); //自定义队列
    // 默认网络环境OK
    self.isNetworkConnected = YES;
    WeakSelf;
    dispatch_async(self.socketQueue, ^{
        // 有网络环境的情况下
        if (weakSelf.isNetworkConnected == YES)
        {
            if (weakSelf.webSocket != nil) {
                // 只有 SR_OPEN 开启状态才能调 send 方法啊，不然要崩
                if (weakSelf.webSocket.readyState == SR_OPEN) {
                    [weakSelf.webSocket send:data];    // 发送数据
                    
                } else if (weakSelf.webSocket.readyState == SR_CONNECTING) {
                    NSLog(@"正在连接中，重连后其他方法会去自动同步数据");
                    // 每隔2秒检测一次 socket.readyState 状态，检测 10 次左右
                    // 只要有一次状态是 SR_OPEN 的就调用 [ws.socket send:data] 发送数据
                    // 如果 10 次都还是没连上的，那这个发送请求就丢失了，这种情况是服务器的问题了，小概率的
                    // 代码有点长，我就写个逻辑在这里好了
                    
                } else if (weakSelf.webSocket.readyState == SR_CLOSING || weakSelf.webSocket.readyState == SR_CLOSED) {
                    // websocket 断开了，调用 reConnect 方法重连
                    //                [weakSelf.webSocket reConnect:^{
                    //                    NSLog(@"重连成功，继续发送刚刚的数据");
                    //                    [weakSelf.webSocket send:data];
                    //                }];
                }
            } else {
                // weakSelf.webSocket == nil情况下的处理
                NSLog(@"没网络，发送失败，一旦断网 socket 会被我设置 nil 的");
                NSLog(@"其实最好是发送前判断一下网络状态比较好，我写的有点晦涩，socket==nil来表示断网");
            }
        
        }
        else
        {
            // 没有网络的处理
        }
    });
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
