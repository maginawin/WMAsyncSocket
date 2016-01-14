//
//  SRLampProtocol.h
//  WMAsyncSocket
//
//  Created by wangwendong on 16/1/14.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SRLampProtocolType) {
    SRLampProtocolTypeOpenLamp,
    SRLampProtocolTypeCloseLamp,
    SRLampProtocolTypeBlackToWhite
};

@interface SRLampProtocol : NSObject

// Protocol header, always by 0x55
@property (nonatomic, readonly) UInt8 header;

// Protocol device ID, always by 3 bytes
@property (strong, nonatomic) NSData *deviceIDData;

// Protocol device type, always by 0x01
@property (nonatomic, readonly) UInt8 deviceType;

// Protocol lamps selected, total 8 bits
@property (nonatomic) UInt8 subDeviceSelected;

// Protocol data type, black to white is always by 0x08, switch by 0x02
@property (nonatomic, readonly) UInt8 dataType;

// Black to white by 0x38, switch by 0x12
@property (nonatomic, readonly) UInt8 keyNumber;

// Black to white value scope 0x01 ~ 0xFF, switch 0xA9 CLOSE and 0xAB OPEN
@property (nonatomic) UInt8 keyValue;

// Front 5 bits sum (deviceType & subDeviceSelected & dataType & keyNumber & keyValue)
@property (nonatomic, readonly) UInt8 verifySum;

// Always 2 bytes <0xAA, 0xAA>
@property (strong, nonatomic, readonly) NSData *endData;

- (SRLampProtocol *)initWithLampProtocolType:(SRLampProtocolType)type deviceIDData:(NSData *)deviceIDData subDeviceSelected:(UInt8)subDeviceSelected;

- (NSData *)sendDataFromLampProtocol;

@end
