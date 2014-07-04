//
//  LCLSniperBot.m
//  RobotWar
//
//  Created by Leonard Li on 7/4/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "LCLSniperBot.h"

typedef NS_ENUM(NSInteger, RobotPositionState) {
    RobotPositionStateDefault,
    RobotPositionStateCharge,
    RobotPositionStateShowdown
};

@implementation LCLSniperBot {
    RobotPositionState _lastPositionState;
    RobotPositionState _currentPositionState;
    NSInteger _myHitCount;
    NSInteger _shotsFired;
    NSInteger _shotsTaken;
    BOOL _isInEvasiveManuevers;

    // Enemy Data
    NSInteger _enemyHitCount;
    CGFloat _enemySlope;
    CGPoint _lastKnownPosition;
    NSDate *_lastKnownPositionTimestamp;
    CGPoint _previousKnownPosition;
}

- (void)run {
    while (true) {
        if (_myHitCount < _enemyHitCount && [self enemyNotMoving]) {
            _lastPositionState = RobotPositionStateShowdown;
        }
        switch (_currentPositionState) {
            case RobotPositionStateDefault:
                _lastPositionState = RobotPositionStateDefault;
                NSUInteger randomDistance = arc4random_uniform(10) + 1;
                [self moveAhead:randomDistance];
                _currentPositionState = RobotPositionStateCharge;
                break;
            case RobotPositionStateCharge:
                //                NSLog(@"RobotPositionStateCharge");
                _lastPositionState = RobotPositionStateCharge;
                [self moveAhead:10];
                if (_lastKnownPosition.x > 0) {
                    [self fireAhead];
                    _currentPositionState = RobotPositionStateCharge;
                }
                break;
            case RobotPositionStateShowdown:
                NSLog(@"RobotPositionStateShowdown");
                _lastPositionState = RobotPositionStateShowdown;
                [self showdown];
                break;
        }
    }
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    [self cancelActiveAction];
    [self turnRobotRight:180];
    [self moveAhead:10];
    [self aimAtPosition:[self arenaCenterPoint]];
}

- (void)gotHit {
    [self cancelActiveAction];
    _myHitCount++;
    _shotsTaken++;
    if ((_myHitCount > _enemyHitCount && !_isInEvasiveManuevers)|| _shotsTaken > 2) {
        _isInEvasiveManuevers = YES;
        _shotsTaken = 0;
        [self moveAhead:100];
        [self fireAhead];
        _isInEvasiveManuevers = NO;
    }
}

- (void)bulletHitEnemy:(Bullet *)bullet {
    _shotsFired = 0;
    _shotsTaken = 0;
    _enemyHitCount++;
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
    NSLog(@"Showdown");
    [self aimAtPosition:_lastKnownPosition];
    [self shoot];
}

- (void)fireAhead {
    CGPoint guessPoint = CGPointMake(_lastKnownPosition.x -_enemySlope, _lastKnownPosition.y - _enemySlope);
    [self aimAtPosition:guessPoint];
    [self shoot];
    _shotsFired++;
    if (_shotsFired > 2) {
        _lastKnownPosition.x = _lastKnownPosition.x - (self.headingDirection.x *20);
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

#pragma mark - World Information

- (CGPoint)myCenterPoint {
    return [self centerPointof:[self robotBoundingBox]];
}

- (CGPoint)arenaCenterPoint {
    CGFloat x = [self arenaDimensions].width / 2;
    CGFloat y = [self arenaDimensions].height / 2;
    return CGPointMake(x, y);
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

- (CGPoint)arenaPointFromDirection:(CGPoint)point {
    CGFloat x = [self arenaDimensions].width/2 * point.x;
    CGFloat y = [self arenaDimensions].height/2 * point.y;
    return CGPointMake(x,y);
}
@end
