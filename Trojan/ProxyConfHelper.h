//
//  ProxyConfHelper.h
//  Trojan
//
//  Created by ParadiseDuo on 2020/5/3.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>

@interface ProxyConfHelper : NSObject

+ (BOOL)isVersionOk;

+ (void)install;

+ (void)enablePACProxy:(NSString*) PACFilePath;

+ (void)enableGlobalProxy;

+ (void)disableProxy:(NSString*) PACFilePath;

+ (NSString*)startPACServer:(NSString*) PACFilePath;

+ (void)stopPACServer;

+ (void)enableWhiteListProxy;

@end
