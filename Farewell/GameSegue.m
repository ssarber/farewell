//
//  GameSegue.m
//  Farewell
//
//  Created by Zook Gek on 5/27/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "GameSegue.h"

@implementation GameSegue

- (void)perform
{
    UIViewController *source = self.sourceViewController;
    UIViewController *destination = self.destinationViewController;
    
    [UIView transitionFromView:source.view toView:destination.view duration:0.5 options:UIViewAnimationOptionTransitionFlipFromTop completion:^(BOOL finished) {
        NSLog(@"Transition is finished.");
    }];
}

@end
