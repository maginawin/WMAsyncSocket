//
//  SRLampProtocol.m
//  WMAsyncSocket
//
//  Created by wangwendong on 16/1/14.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import "SRLampProtocol.h"


@implementation SRLampProtocol

- (SRLampProtocol *)initWithLampProtocolType:(SRLampProtocolType)type deviceIDData:(NSData *)deviceIDData subDeviceSelected:(UInt8)subDeviceSelected {
    self = [super init];
    
    if (self) {
        switch (type) {
            case SRLampProtocolTypeBlackToWhite: {
                _dataType = 0x08;
                
                _keyNumber = 0x38;
                
                _keyValue = 0x01;
            
                break;
            }
            case SRLampProtocolTypeOpenLamp: {
                _dataType = 0x02;
                
                _keyNumber = 0x12;
                
                _keyValue = 0xAB;
            
                break;
            }
            case SRLampProtocolTypeCloseLamp: {
                _dataType = 0x02;
                
                _keyNumber = 0x12;
                
                _keyValue = 0xA9;
            
                break;
            }
        }
        
        _header = 0x55;
        
        _deviceType = 0x01;
        
        unsigned const char endBytes[] = {0xAA, 0xAA};
        _endData = [NSData dataWithBytes:endBytes length:2];
        
        _deviceIDData = [NSData dataWithBytes:deviceIDData.bytes length:3];
        
        _subDeviceSelected = subDeviceSelected;
    }
    
    return self;
}

- (NSData *)sendDataFromLampProtocol {
    NSMutableData *sendData = [NSMutableData data];
    
    [sendData appendBytes:&_header length:1];
    
    [sendData appendData:_deviceIDData];
    
    [sendData appendBytes:&_deviceType length:1];
    
    [sendData appendBytes:&_subDeviceSelected length:1];
    
    [sendData appendBytes:&_dataType length:1];
    
    [sendData appendBytes:&_keyNumber length:1];
    
    [sendData appendBytes:&_keyValue length:1];
    
    _verifySum = _deviceType + _subDeviceSelected + _dataType + _keyNumber + _keyValue;
    [sendData appendBytes:&_verifySum length:1];
    
    [sendData appendData:_endData];
    
    return sendData;
}

@end
