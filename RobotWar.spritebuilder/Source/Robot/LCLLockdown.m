//
//  LCLLockdown.m
//  RobotWar
//
//  Created by Leonard Li on 7/7/14.
//  Copyright (c) 2014 MakeGamesWithUs. All rights reserved.
//

#import "LCLLockdown.h"

@implementation LCLLockdown {
    int actionIndex;
    
    // My Robot Data
    NSInteger _myHitCount;
    NSInteger _shotsFired;
    CGFloat _lastShotTimeStamp;
    CGPoint _straightSnipingPoint;
    
    // Enemy Data
    NSInteger _enemyHitCount;
    CGFloat _enemySlope;
    CGPoint _lastKnownPosition;
    CGPoint _previousKnownPosition;
    CGFloat _lastKnownPositionTimestamp;
    CGFloat _previousKnownPositionTimestamp;
    
    // Arena Data
    CGFloat _robotWidth;
    CGFloat _robotHeight;
    CGFloat _arenaWidth;
    CGFloat _arenaHeight;
    CGPoint _arenaCenter;
    CGRect _arenaRect;
}

- (void)run {
    actionIndex = 0;
    while (true) {
        if ([self timeSinceLastScan] > 2) {
            self.enemyState = EnemyPositionUnknown;
        }
        
        if (self.enemyState == EnemyPositionKnown) {
            [self performSnipeAction];
        }
        
        while (self.myState == RobotStateSearching) {
            [self performSearchAction];
        }
        
        while (self.myState == RobotStateDefault) {
            [self performNextDefaultAction];
            [self moveBack:5];
        }
    }
}

- (void)performSearchAction {
    switch (actionIndex%5) {
        case 0:
            if ([self timeSinceLastScan] > 2) {
                self.enemyState = EnemyPositionUnknown;
            }
            break;
        case 1:
            if (self.enemyState == EnemyPositionKnown) {
                [self performSnipeAction];
            }
            break;
        case 2:
            [self moveAhead:10];
            break;
        case 3:
            if (self.enemyState == EnemyPositionKnown) {
                [self aimAtPosition:_lastKnownPosition];
            }
            break;
        case 4:
            [self fireAhead];
            break;
    }
    actionIndex++;
}

- (void)performSnipeAction {
    switch (actionIndex%2) {
        case 0:
            [self aimAtPosition:_lastKnownPosition];
            break;
        case 1:
            [self fireAhead];
            break;
    }
    actionIndex++;
}

- (void)performNextDefaultAction {
    [self getArenaData];
    _lastKnownPosition = _arenaCenter;
    
    [self shoot];
    [self aimAtPosition:_lastKnownPosition];
    
    switch (actionIndex%1) {
        case 0:
            if ([self distanceFromWall] > _arenaWidth/2) {
                [self moveBack:(_arenaWidth -[self distanceFromWall])];
            } else {
                [self moveAhead:[self distanceFromWall]];
            }
            break;
    }
    actionIndex++;
}


#pragma mark - Robot Actions

- (void)fireAhead {
    _shotsFired++;
    if (self.enemyState == EnemyPositionKnown) {
        CGPoint guessPoint = CGPointMake(_lastKnownPosition.x -_enemySlope, _lastKnownPosition.y - _enemySlope);
        [self aimAtPosition:guessPoint];
    }
    
    CGFloat halfway = abs(self.headingDirection.x*_arenaWidth/2) + abs(self.headingDirection.y*_arenaHeight/2);
    if ([self distanceFromWall] < halfway && _shotsFired > 2 && self.myAimState == RobotAimState45) {
        CGFloat x = abs([self headingDirection].x * [self position].x) +
        abs(abs([self headingDirection].x)-1)*_arenaCenter.x;
        CGFloat y = abs([self headingDirection].y * [self position].y) +
        abs(abs([self headingDirection].y)-1)*_arenaCenter.y;
        [self aimAtPosition:CGPointMake(x, y)];
        self.myAimState = RobotAimState90;
    }
    
    [self shoot];
}

- (void)aimAtPosition:(CGPoint)position {
    CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:position];
    if (angle >= 0) {
        [self turnGunRight:abs(angle)];
    } else {
        [self turnGunLeft:abs(angle)];
    }
}

#pragma mark - Robot Override Methods

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    if (self.myState == RobotStateDefault) {
        [self turnRobotRight:90];
        if (self.enemyState == EnemyPositionKnown) {
            [self aimAtPosition:_lastKnownPosition];
        } else {
            [self aimAtPosition:_arenaCenter];
        }
        self.myState = RobotStateSearching;
    }
    
    switch (hitDirection) {
        case RobotWallHitDirectionFront:
            [self turnRobotLeft:90];
            if (self.enemyState == EnemyPositionUnknown) {
                [self aimAtPosition:_arenaCenter];
                self.myAimState = RobotAimState45;
            }
            break;
        default:
            if (angle >= 0) {
                [self turnRobotLeft:abs(angle)];
            } else {
                [self turnRobotRight:abs(angle)];
                
            }
            break;
    }
}

- (void)gotHit {
    [self cancelActiveAction];
    _myHitCount++;
    _lastShotTimeStamp = [self currentTimestamp];
    if ((_myHitCount > _enemyHitCount && [self timeSinceLastShotTaken] < 3) || (self.enemyState == EnemyPositionUnknown)) {
        [self moveAhead:50];
        if (self.enemyState == EnemyPositionKnown) {
            [self aimAtPosition:_lastKnownPosition];
        } else {
            [self aimAtPosition:_arenaCenter];
        }
    }
}


- (void)bulletHitEnemy:(Bullet *)bullet {
    _shotsFired = 0;
    _enemyHitCount++;
    [self shoot];
}


- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    _lastKnownPosition = position;
    _previousKnownPosition = _lastKnownPosition;
    _lastKnownPositionTimestamp = self.currentTimestamp;
    self.enemyState = EnemyPositionKnown;
    
    if (_previousKnownPosition.x && _previousKnownPosition.y) {
        if (_previousKnownPosition.x != _lastKnownPosition.x) {
            _enemySlope = (_previousKnownPosition.y - _lastKnownPosition.y) / (_previousKnownPosition.x - _lastKnownPosition.x);
        } else {
            _enemySlope = 0;
        }
    }
}

- (void)setMyState:(RobotState)myState {
    _myState = myState;
    actionIndex = 0;
}

#pragma mark - Robot Helper Methods

- (void)getArenaData {
    while (_robotWidth == 0) {
        _robotWidth = self.robotBoundingBox.size.width;
    }
    while (_robotHeight == 0) {
        _robotHeight = self.robotBoundingBox.size.height;
    }
    while (_arenaWidth == 0) {
        _arenaWidth = self.arenaDimensions.width;
    }
    while (_arenaHeight == 0) {
        _arenaHeight = self.arenaDimensions.height;
    }
    while (_arenaCenter.x == 0 && _arenaCenter.y == 0) {
        _arenaCenter.x = _arenaWidth / 2;
        _arenaCenter.y = _arenaHeight / 2;
    }
    while (_arenaRect.size.width == 0 && _arenaRect.size.height == 0) {
        CGFloat width = [self arenaDimensions].width;
        CGFloat height = [self arenaDimensions].height;
        _arenaRect = CGRectMake(0, 0, width, height);
    }

    if (EnemyPositionUnknown) {
        _lastKnownPosition = _arenaCenter;
    }
}

- (NSInteger)timeSinceLastScan {
    return [self currentTimestamp] - _lastKnownPositionTimestamp;
}

- (NSInteger)timeSinceLastShotTaken {
    return [self currentTimestamp] - _lastShotTimeStamp;
}

- (CGFloat)distanceFromWall {
    CGFloat wallX = (self.headingDirection.x * _arenaCenter.x) + _arenaCenter.x;
    CGFloat wallY = (self.headingDirection.y * _arenaCenter.y) + _arenaCenter.y;
    
    CGFloat distanceX = [self position].x - wallX;
    CGFloat distanceY = [self position].y - wallY;
    CGFloat distance = abs(self.headingDirection.x * distanceX) + abs(self.headingDirection.y * distanceY);
    return distance;
}

- (BOOL)enemyNotMoving {
    return (_lastKnownPosition.x == _previousKnownPosition.x &&
            _lastKnownPosition.y == _previousKnownPosition.y);
}

- (CGFloat)distanceBetweenPointA:(CGPoint)pointA
                       andPointB:(CGPoint)pointB {
    CGFloat xDelta = powf((pointA.x - pointB.x),2);
    CGFloat yDelta = powf((pointA.y - pointB.y),2);
    CGFloat distance = sqrtf(xDelta + yDelta);
    return distance;
}

@end
