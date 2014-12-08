//
//  ViewController.m
//  syncDataDemo
//
//  Created by Xiaohe Hu on 12/8/14.
//  Copyright (c) 2014 Neoscape. All rights reserved.
//

#import "ViewController.h"
#import "SyncManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidStart) name:SyncManagerSyncDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidFinish) name:SyncManagerSyncDidFinishNotification object:nil];
}

#pragma mark - Update UI

- (void)syncDidStart {

}

- (void)syncDidFinish {

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
