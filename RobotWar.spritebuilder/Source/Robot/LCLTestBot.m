//
//  LCLTestBot.m
//  RobotWar
//
//  Created by Leonard Li on 7/4/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "LCLTestBot.h"

typedef NS_ENUM(NSInteger, RobotPositionState) {
    RobotPositionStateDefault,
    RobotPositionStateCharge,
    RobotPositionStateShowdown
};

typedef NS_ENUM(NSInteger, EnemyPositionState) {
    EnemyPositionUnknown,
    EnemyPositionKnown
};

@implementation LCLTestBot {
    RobotPositionState _lastPositionState;
    RobotPositionState _currentPositionState;
    NSInteger _myHitCount;
    NSInteger _shotsFired;
    NSInteger _shotsTaken;
    CGFloat _lastShotTimeStamp;
    
    // Enemy Data
    EnemyPositionState _enemyPositionState;
    NSInteger _enemyHitCount;
    CGFloat _enemySlope;
    CGPoint _lastKnownPosition;
    CGPoint _previousKnownPosition;
    CGFloat _lastKnownPositionTimestamp;
    CGFloat _previousKnownPositionTimestamp;
}

- (void)run {
    while (true) {
        if ([self timeSinceLastScan] > 2) {
            _enemyPositionState = EnemyPositionUnknown;
        }
        if (_myHitCount < _enemyHitCount && [self enemyNotMoving]) {
            _lastPositionState = RobotPositionStateShowdown;
        }
        switch (_currentPositionState) {
            case RobotPositionStateDefault:
                _lastPositionState = RobotPositionStateDefault;
                NSLog(@"%f,%f", self.headingDirection.x, self.headingDirection.y);
                NSLog(@"Position: %f, %f - Distance From Wall: %f", [self position].x, [self position].y, [self distanceFromWall]);
                NSUInteger randomDistance = arc4random_uniform(10) + 1;
                _lastKnownPosition = [self arenaCenterPoint];
                [self moveAhead:randomDistance];
                [self aimAtPosition:[self arenaCenterPoint]];
                _currentPositionState = RobotPositionStateCharge;
                break;
            case RobotPositionStateCharge:
                //                NSLog(@"RobotPositionStateCharge");
                _lastPositionState = RobotPositionStateCharge;
                [self moveAhead:5];
                if (_enemyPositionState == EnemyPositionKnown) {
                    [self fireAhead];
                } else {
                    if ([self distanceFromWall] < 100 && _shotsFired > 2 && _shotsTaken < 3) {
                        [self turnRobotRight:180];
                        [self aimAtPosition:[self arenaCenterPoint]];
                    }
                    [self shoot];
                    if (self.headingDirection.x > 0) {
                        _lastKnownPosition.x = (NSInteger)(_lastKnownPosition.x + (self.headingDirection.x * 45)) % (NSInteger)[self arenaDimensions].width;
                    } else {
                        _lastKnownPosition.x = (NSInteger)(_lastKnownPosition.x - (self.headingDirection.x * 45)) % (NSInteger)[self arenaDimensions].width;
                    }
                    
                    [self aimAtPosition:_lastKnownPosition];
                }
                _currentPositionState = RobotPositionStateCharge;
                break;
            case RobotPositionStateShowdown:
                NSLog(@"RobotPositionStateShowdown");
                _lastPositionState = RobotPositionStateShowdown;
                if (_enemyPositionState == EnemyPositionKnown) {
                    [self showdown];
                } else {
                    _currentPositionState = RobotPositionStateCharge;
                }
                break;
        }
    }
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    if (_enemyPositionState == EnemyPositionKnown) {
        [self moveBack:([self arenaDimensions].width - 100)];
    } else {
        [self moveBack:10];
        [self turnRobotRight:180];
        [self aimAtPosition:[self arenaCenterPoint]];
    }
}

- (void)gotHit {
    _lastShotTimeStamp = [self currentTimestamp];
    _myHitCount++;
    _shotsTaken++;
    if ((_myHitCount > _enemyHitCount && [self timeSinceLastShotTaken] < 3) || (_enemyPositionState == EnemyPositionUnknown)) {
        _shotsTaken = 0;
        if ([self distanceFromWall] < 50) {
            [self moveBack:([self arenaDimensions].width - 100)];
            [self aimAtPosition:[self arenaCenterPoint]];
        }
        else {
            [self moveAhead:50];
            if (_enemyPositionState == EnemyPositionKnown) {
                [self aimAtPosition:_lastKnownPosition];
            }
        }
    }
}

- (void)bulletHitEnemy:(Bullet *)bullet {
    _shotsFired = 0;
    _shotsTaken = 0;
    _enemyHitCount++;
    [self shoot];
}

- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    NSLog(@"%f,%f", position.x, position.y);
    _enemyPositionState = EnemyPositionKnown;
    _lastKnownPosition = position;
    _previousKnownPosition = _lastKnownPosition;
    _lastKnownPositionTimestamp = [self currentTimestamp];
    _previousKnownPositionTimestamp = _lastKnownPositionTimestamp;
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

- (CGPoint)arenaCenterPoint {
    CGFloat x = [self arenaDimensions].width / 2;
    CGFloat y = [self arenaDimensions].height / 2;
    return CGPointMake(x, y);
}

- (NSInteger)timeSinceLastScan {
    return [self currentTimestamp] - _lastKnownPositionTimestamp;
}


- (NSInteger)timeSinceLastShotTaken {
    return [self currentTimestamp] - _lastShotTimeStamp;
}

- (CGFloat)distanceFromWall {
    CGFloat wallX = (self.headingDirection.x * [self arenaCenterPoint].x) + [self arenaCenterPoint].x;
    CGFloat distance = abs([self position].x - wallX);
    return distance;
}

@end
