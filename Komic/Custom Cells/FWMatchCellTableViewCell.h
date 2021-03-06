//
//  FWMatchCellTableViewCell.h
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWGameCenterHelper.h"
@import GameKit;

@protocol FWMatchCellTableViewCellDelegate
@optional
- (void)loadAMatch:(GKTurnBasedMatch *)match;
@required
- (void)reloadTableView;
@end

@interface FWMatchCellTableViewCell : UITableViewCell

@property (strong, nonatomic) GKTurnBasedMatch *match;
@property (weak, nonatomic) IBOutlet UITextView *storyText;
@property (weak, nonatomic) IBOutlet UIImageView *playerOnePhoto;
@property (weak, nonatomic) IBOutlet UIImageView *playerTwoPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *playerThreePhoto;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *playerPhotos;

@property (weak, nonatomic) id <FWMatchCellTableViewCellDelegate> delegate;

@end
