//
//  SocketManager.h
//  WebSocketDemo
//  gitHub https://github.com/angletiantang
//  QQ 871810101
//  Created by guojianheng on 2018/4/2.
//  Copyright © 2018年 guojianheng. All rights reserved.
//

#import "SocketViewController.h"
#import "SocketManager.h"

@interface SocketViewController ()

@end

@implementation SocketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 开启连接
    NSString *url = @"ws://222.73.213.180:5050/AgentProxyServer";
    [[SocketManager sharedInsatance] webSocketOpen:url connect:^{
        NSLog(@"成功连接");
    } receive:^(id message, SocketReceiveType type) {
        if (type == SocketReceiveTypeForMessage) {
            NSLog(@"接收 类型1--%@",message);
        }
        else if (type == SocketReceiveTypeForPong){
            NSLog(@"接收 类型2--%@",message);
        }
    } failure:^(NSError *error) {
        NSLog(@"连接失败");
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[SocketManager sharedInsatance] webSocketClose:^(NSInteger code, NSString *reason, BOOL wasClean) {
        NSLog(@"code = %ld,reason = %@",(long)code,reason);
    }];
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
