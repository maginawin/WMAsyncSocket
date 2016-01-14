//
//  AppDelegate.m
//  WMAsyncSocket
//
//  Created by wangwendong on 16/1/14.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import "AppDelegate.h"
#import "SRLampProtocol.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    unsigned const char idBytes[] = {0x01, 0xFF, 0xAA};
    
    SRLampProtocol *lampProtocol0 = [[SRLampProtocol alloc] initWithLampProtocolType:SRLampProtocolTypeBlackToWhite deviceIDData:[NSData dataWithBytes:idBytes length:3] subDeviceSelected:0x0F];
    
    NSLog(@"black white %@", [lampProtocol0 sendDataFromLampProtocol]);
    
    SRLampProtocol *lampProtocol1 = [[SRLampProtocol alloc] initWithLampProtocolType:SRLampProtocolTypeOpenLamp deviceIDData:[NSData dataWithBytes:idBytes length:3] subDeviceSelected:0x1F];
    
    NSLog(@"close %@", [lampProtocol1 sendDataFromLampProtocol]);
    
    SRLampProtocol *lampProtocol2 = [[SRLampProtocol alloc] initWithLampProtocolType:SRLampProtocolTypeCloseLamp deviceIDData:[NSData dataWithBytes:idBytes length:3] subDeviceSelected:0x1F];
    
    NSLog(@"close %@", [lampProtocol2 sendDataFromLampProtocol]);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
