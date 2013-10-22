//
//  APAppDelegate.m
//  APPaginalTableViewExample
//
//  Created by Antol Peshkov on 22.10.13.
//  Copyright (c) 2013 brainSTrainer. All rights reserved.
//

#import "APAppDelegate.h"
#import "APViewController.h"

@implementation APAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.window.rootViewController = [[APViewController alloc] init];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
