//
//  FWInitialFlowViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/11/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWInitialFlowViewController.h"

NSString *const kFWUserHasSeenInitialFlowUserDefault = @"FWUserHasSeenInitialFlowUserDefault";

@interface FWInitialFlowViewController ()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIButton *textLabelButton;
@property (weak, nonatomic) IBOutlet UIButton *beginButton;

@property (strong, nonatomic) NSArray *textArray;
@property (nonatomic) NSUInteger textIndex;

@property (strong, nonatomic) UISwipeGestureRecognizer *swipeGestureRecognizer;

@property (assign, nonatomic) BOOL userHasSeenInitialFlow;

@end

@implementation FWInitialFlowViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _textIndex = -1;
    [self.textLabel sizeToFit];
    self.beginButton.hidden = YES;
    
    self.swipeGestureRecognizer  = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(changeText:)];
    self.swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.swipeGestureRecognizer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([self hasSeenInitialFlow] == NO) {
        
        // User has seen the initial flow, don't show again
        [defaults setObject:[NSNumber numberWithBool: YES] forKey:kFWUserHasSeenInitialFlowUserDefault];
        [defaults synchronize];
    }
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)hasSeenInitialFlow
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:kFWUserHasSeenInitialFlowUserDefault] boolValue];
}

- (NSArray *)textArray {
    if (!_textArray) {
        _textArray= @[@"You, dear Sir or Madam, are a comedian. You can write stand-up comedy big-time.\n\
Dane Cook ain't got nothin' on you. What, no way?\n\
Yes way. \
Because you've got help now.",
                      
@"Enlist a friend you think is funny to write it with you. You write a sentence (surely you \
can write a sentence), then pass the turn to the friend and she (or he) will write a sentence or two. Before long, you'll have \
yourself a masterpiece you can sell to Comedy Central(tm) or something. Trust me.",

@"Why should you trust me, you ask? Whatever.\n\
Just tap the damn button."];
    }
    
    return _textArray;
}


- (IBAction)changeText:(id)sender
{
    [UIView transitionWithView:self.textLabel duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.textLabel.text = [self newSentence];
    } completion:nil];
}


- (NSString *)newSentence
{
    self.beginButton.hidden = self.userHasSeenInitialFlow? NO : YES;
    
    if (self.textIndex >= self.textArray.count - 1) {
        self.textIndex = 0;
    } else {
        self.textIndex = self.textIndex + 1;
    }
    if (self.textIndex == self.textArray.count - 1) {
        void (^initialFlowFinishedBlock)() = ^{
            self.userHasSeenInitialFlow = YES;
            self.beginButton.hidden =  NO;
            self.beginButton.alpha = 1;
            
            // I still like the black color!
            //  self.view.backgroundColor = [UIColor blackColor];
        };
        
        [UIView transitionWithView:self.beginButton duration:0
                           options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                               self.beginButton.alpha = 0;
                               self.textLabelButton.userInteractionEnabled = NO;
                               
                           } completion:^ (BOOL finished){
                               [UIView animateWithDuration:.75
                                                     delay:3.5
                                                   options: UIViewAnimationOptionTransitionCrossDissolve
                                                animations:^{
                                                    initialFlowFinishedBlock();
                                                } completion:nil];
                           }];
    }
    return self.textArray[self.textIndex];
}

@end
