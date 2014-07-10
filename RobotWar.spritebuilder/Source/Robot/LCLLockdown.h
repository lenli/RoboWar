//
//  LCLLockdown.h
//  RobotWar
//
//  Created by Leonard Li on 7/7/14.
//  Copyright (c) 2014 MakeGamesWithUs. All rights reserved.
//

#import "Robot.h"
typedef NS_ENUM(NSInteger, RobotState) {
    RobotStateDefault,
    RobotStateSearching
};

typedef NS_ENUM(NSInteger, EnemyPosition) {
    EnemyPositionUnknown,
    EnemyPositionKnown
};



@interface LCLLockdown : Robot
@property (nonatomic, assign) RobotState myState;
@property (nonatomic, assign) EnemyPosition enemyState;

@end
