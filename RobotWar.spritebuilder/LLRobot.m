//
//  LLRobot.m
//  RobotWar
//
//  Created by Leonard Li on 7/1/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "LLRobot.h"
typedef NS_ENUM(NSInteger, RobotPositionState) {
    RobotPositionStateDefault,
    RobotPositionStateStrafe,
    RobotPositionStateFoundWall,
    RobotPositionStateCircle,
    RobotPositionStateCharge
};

typedef NS_ENUM(NSInteger, EnemyState) {
    EnemyStateUnknown,
    EnemyStateStill
};


@implementation LLRobot {
    RobotPositionState _lastPositionState;
    RobotPositionState _currentPositionState;
    NSInteger myHitCount;
    
    // Enemy Data
    NSInteger enemyHitCount;
    CGFloat _enemySlope;
    CGPoint _lastKnownPosition;
    NSDate *_lastKnownPositionTimestamp;
    CGPoint _previousKnownPosition;
}

- (void)run {
    while (true) {
        if (myHitCount < enemyHitCount && [self enemyNotMoving]) {
            [self showdown];
        }
        
        switch (_currentPositionState) {
            case RobotPositionStateDefault:
                _lastPositionState = RobotPositionStateDefault;
                [self moveAhead:10];
                if (_lastKnownPosition.x > 0) {
                    [self fireAhead];
                    _currentPositionState = RobotPositionStateCharge;
                }
                _currentPositionState = RobotPositionStateDefault;
                
                break;
            case RobotPositionStateCircle:
                [self circleStrafeBasicRight];
                break;
            case RobotPositionStateFoundWall:
                _lastPositionState = RobotPositionStateFoundWall;
                if (_lastPositionState == RobotPositionStateDefault) {
                    [self turnGunLeft:90];
                }
                [self turnRobotRight:90];
                [self moveBack:15];
                
                _currentPositionState = RobotPositionStateStrafe;
                break;
            case RobotPositionStateStrafe:
                _lastPositionState = RobotPositionStateStrafe;
                [self moveBack:50];
                break;
            case RobotPositionStateCharge:
                _lastPositionState = RobotPositionStateCharge;
                [self moveAhead:10];
                break;
        }
    }
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    _currentPositionState = RobotPositionStateFoundWall;
}

- (void)gotHit {
    myHitCount++;
    if (myHitCount > enemyHitCount) {
        [self moveAhead:100];
        [self moveBack:200];
    }
    NSLog(@"Hit");
}

- (void)bulletHitEnemy:(Bullet *)bullet {
    enemyHitCount++;
    [self shoot];
}

- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    _lastKnownPosition = position;
    _previousKnownPosition = _lastKnownPosition;
    _lastKnownPositionTimestamp = [NSDate date];
    if (_previousKnownPosition.x && _previousKnownPosition.y) {
        if (_previousKnownPosition.x != _lastKnownPosition.x) {
            _enemySlope = (_previousKnownPosition.y - _lastKnownPosition.y) / (_previousKnownPosition.x - _lastKnownPosition.x);
        } else {
            _enemySlope = 0;
        }
    }
}

- (BOOL)enemyNotMoving {
    return (_lastKnownPosition.x == _previousKnownPosition.x &&
            _lastKnownPosition.y == _previousKnownPosition.y);
}



#pragma mark - Robot Actions

- (void)showdown {
    [self aimAtPosition:_lastKnownPosition];
    [self shoot];
}

- (void)fireAhead {
    if ([self timeSinceLastScan] < 1000) {
        CGPoint guessPoint = CGPointMake(_lastKnownPosition.x -_enemySlope, _lastKnownPosition.y - _enemySlope);
        [self aimAtPosition:guessPoint];
        NSLog(@"%f, %f", guessPoint.x, guessPoint.y);
        [self shoot];
    }
}

- (void)aimAtPosition:(CGPoint)position {
    CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:position];
    if (angle >= 0) {
        [self turnGunRight:abs(angle)];
    } else {
        [self turnGunLeft:abs(angle)];
    }
}

- (void)circleStrafeBasicRight {
    _lastPositionState = RobotPositionStateDefault;
    [self moveAhead:24];
    [self turnRobotRight:10];
    _currentPositionState = RobotPositionStateCircle;
}

- (void)defaultChargeToWall {
    [self moveAhead:500];
    [self turnRobotRight:90];
    [self moveAhead:40];
    _currentPositionState = RobotPositionStateCircle;
}


#pragma mark - World Information

- (CGPoint)myCenterPoint {
    return [self centerPointof:[self robotBoundingBox]];
}

- (CGPoint)arenaCenterPoint {
    CGRect arenaRect = CGRectMake(0,0,[self arenaDimensions].width, [self arenaDimensions].height);
    return [self centerPointof:arenaRect];
}

- (CGPoint)centerPointof:(CGRect)rect {
    NSInteger x = [self robotBoundingBox].origin.x + ([self robotBoundingBox].size.width / 2);
    NSInteger y = [self robotBoundingBox].origin.y + ([self robotBoundingBox].size.height / 2);
    return CGPointMake(x, y);
}

- (NSInteger)timeSinceLastScan {
    NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:_lastKnownPositionTimestamp];
    return distanceBetweenDates *1000;
}





@end
