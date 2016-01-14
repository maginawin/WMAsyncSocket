//
//  ViewController.m
//  WMAsyncSocket
//
//  Created by wangwendong on 16/1/14.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"
#import "SRLampProtocol.h"
#import "SRLamp.h"

@interface ViewController () <GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate>

@property (strong, nonatomic) GCDAsyncSocket *tcpSocket;
@property (strong, nonatomic) GCDAsyncUdpSocket *udpSocket;

@property (strong, nonatomic) NSMutableArray *lamps;

@property (weak, nonatomic) IBOutlet UITextField *brightnessValueTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _lamps = [NSMutableArray array];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_brightnessValueTextField resignFirstResponder];
}

- (IBAction)sendBrightnessValue:(id)sender {
    if (_brightnessValueTextField.text.length < 1) {
        return;
    }
    
    unsigned const char idBytes[] = {0x01, 0xFF, 0xAA};
    
    SRLampProtocol *lampProtocol = [[SRLampProtocol alloc] initWithLampProtocolType:SRLampProtocolTypeBlackToWhite deviceIDData:[NSData dataWithBytes:idBytes length:3] subDeviceSelected:0x01];
    
    lampProtocol.keyValue = _brightnessValueTextField.text.integerValue;
    
//    [self sendUDPData:[lampProtocol sendDataFromLampProtocol] toHost:@"10.10.100.254" port:48899];
    [self setTCPData:[lampProtocol sendDataFromLampProtocol]];
}

#pragma mark - UDP

- (IBAction)connectUDP:(id)sender {
    NSError *err;
    
    [_udpSocket close];
    _udpSocket = nil;
    
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    if (![_udpSocket enableBroadcast:YES error:&err]) {
        NSLog(@"enable error %@", err);
    };
    
    if (![_udpSocket bindToPort:48899 error:&err]) {
        NSLog(@"bind port %@", err);
    };
    
//    if (![_udpSocket joinMulticastGroup:@"10.10.100.255" error:&err]) {
//        NSLog(@"jion error %@", err);
//    };
    
    [_udpSocket beginReceiving:&err];
}

- (IBAction)sendToUdp:(id)sender {
//    if (!_udpSocket.isConnected) {
//        NSLog(@"udp is not connected");
//        
//        return;
//    } else {
//        NSLog(@"udp is connected");
//    }
    
    if (!_udpSocket) {
        NSError *err;
        
        [_udpSocket close];
        _udpSocket = nil;
        
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        if (![_udpSocket enableBroadcast:YES error:&err]) {
            NSLog(@"enable error %@", err);
        };
        
        if (![_udpSocket bindToPort:48899 error:&err]) {
            NSLog(@"bind port %@", err);
        };
        
        //    if (![_udpSocket joinMulticastGroup:@"10.10.100.255" error:&err]) {
        //        NSLog(@"jion error %@", err);
        //    };
        
        [_udpSocket beginReceiving:&err];
    }
    
    NSData *data = [@"HF-A11ASSISTHREAD" dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *host = @"10.10.100.255";
    int port = 48899;
    
    for (int i = 0; i < 30; i++) {
        [_udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:0];
        
        NSLog(@"send data %@ host %@ port %d", data, host, port);
        
        if (i == 29) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // the last
                if (_lamps.count > 0) {
                    [self closeUDPSocket];
                    
                    [self setupTCPSocketWithLamp:_lamps.firstObject];
                }
            });
        }
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSLog(@"udp did connect to address %@", address);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    NSLog(@"did not connect %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"udp did not send data");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *receiveStr = [NSString stringWithCString:data.bytes encoding:NSASCIIStringEncoding];
    
    NSString *regEx = @"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(.?)){4},[0-9A-Z]{12},[0-9A-Z]*";
    NSRange receiveRange = [receiveStr rangeOfString:regEx options:NSRegularExpressionSearch];
    
    if (receiveRange.location == NSNotFound) {
        NSLog(@"normal udp receive %@", receiveStr);
    } else {
        NSArray *lampsInfos = [receiveStr componentsSeparatedByString:@","];
        
        NSString *lampIpAddress = nil;
        if (lampsInfos.count > 0) {
            lampIpAddress = lampsInfos.firstObject;
        }
        
        NSString *lampMacAddress = nil;
        if (lampsInfos.count > 1) {
            lampMacAddress = lampsInfos[1];
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ipAddress = %@", lampIpAddress];
        NSArray *hasSaved = [_lamps filteredArrayUsingPredicate:predicate];
        if (hasSaved.count == 0) {
            SRLamp *lamp = [[SRLamp alloc] init];
            lamp.ipAddress = lampIpAddress;
            lamp.macAddress = lampMacAddress;
            
            [_lamps addObject:lamp];
        }
    }
    
//    if ([@"HF-A11ASSISTHREAD" isEqualToString:receiveStr]) {
//        NSLog(@"get success receive");
//        
//        NSData *okData = [@"+ok" dataUsingEncoding:NSASCIIStringEncoding];
//        
//        [self sendUDPData:okData toHost:@"10.10.100.255" port:48899];
//    } else if ([@"+ok" isEqualToString:receiveStr]) {
//        unsigned const char bytes[] = {0x41, 0x54, 0x2B, 0x57, 0x53, 0x43, 0x41, 0x4E, 0x0D};
//        NSData *aData = [NSData dataWithBytes:bytes length:9];
//        
//        NSLog(@"a data %@", aData);
//        
//        [self sendUDPData:aData toHost:@"10.10.100.255" port:48899];
//    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"udp did send data");
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    NSLog(@"udp did close");
}

#pragma mark - TCP

- (IBAction)connect:(id)sender {
    NSError *err;
    
    _tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [_tcpSocket connectToHost:@"10.10.100.254" onPort:8899 error:&err];
}

- (IBAction)sendData:(id)sender {
    if (!_tcpSocket.isConnected) {
        NSLog(@"未连接");
    }
    
    NSData *data = [@"HF-A11ASSISTHREAD" dataUsingEncoding:NSASCIIStringEncoding];
    
    for (int i = 0; i < 30; i++) {
        [_tcpSocket writeData:data withTimeout:6 tag:100];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"连接成功 host: %@, port: %d", host, port);
    
//    [sock readDataWithTimeout:-1 tag:100];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"连接失败 %@", err);
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"did write %d", (int)tag);
    
//    [sock readDataWithTimeout:10 tag:100];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"did read %@", data);
    
//    [sock readDataWithTimeout:-1 tag:100];
}

- (void)sendUDPData:(NSData *)data toHost:(NSString *)host port:(uint16_t)port {
    if (!data) {
        return;
    }
    
    if (!_udpSocket) {
        [self setupUDPSocket];
    }
    
    [_udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:0];
}

- (void)setupUDPSocket {
    NSError *err;
    
    [_udpSocket close];
    _udpSocket = nil;
    
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    if (![_udpSocket enableBroadcast:YES error:&err]) {
        NSLog(@"enable error %@", err);
    };
    
    if (![_udpSocket bindToPort:48899 error:&err]) {
        NSLog(@"bind port %@", err);
    };
    
    [_udpSocket beginReceiving:&err];
}

- (void)closeUDPSocket {
    if (_udpSocket) {
        [_udpSocket close];
        _udpSocket = nil;
    }
}

- (void)setupTCPSocketWithLamp:(SRLamp *)lamp {
    if (!lamp) {
        return;
    }
    
    if (_tcpSocket && _tcpSocket.isConnected) {
        [_tcpSocket disconnect];
    }
    
    _tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *err;
    
    [_tcpSocket connectToHost:lamp.ipAddress onPort:8899 withTimeout:10 error:&err];
    
    NSLog(@"tcp address %@", lamp.ipAddress);
}

- (void)setTCPData:(NSData *)data {
    if (!data) {
        return;
    }
    
    if (_tcpSocket.isConnected) {
        [_tcpSocket writeData:data withTimeout:-1 tag:0];
    } else {
        [self setupTCPSocketWithLamp:_lamps.firstObject];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
