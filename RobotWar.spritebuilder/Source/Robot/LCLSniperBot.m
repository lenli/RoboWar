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
    RobotPositionStateMoving,
    RobotPositionStateBackingUpToWall,
    RobotPositionStateSniping
};

typedef NS_ENUM(NSInteger, EnemyPositionState) {
    EnemyPositionUnknown,
    EnemyPositionKnown
};

typedef NS_ENUM(NSInteger, RobotAimPosition) {
    RobotAimAngle45,
    RobotAimAngle90
};

@implementation LCLSniperBot {
    RobotPositionState _lastPositionState;
    RobotPositionState _currentPositionState;
    RobotAimPosition _currentAimAngle;
    NSMutableArray *_snipingPositions;
    NSInteger _myHitCount;
    NSInteger _shotsFired;
    CGFloat _lastShotTimeStamp;
    CGPoint _straightSnipingPoint;
    
    // Enemy Data
    EnemyPositionState _enemyPositionState;
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
    while (true) {
        if ([self timeSinceLastScan] > 2) {
            _enemyPositionState = EnemyPositionUnknown;
        }
        if (_enemyPositionState == EnemyPositionKnown) {
            [self aimAtPosition:_lastKnownPosition];
            [self fireAhead];
            [self moveAhead:10];
        }
        
        switch (_currentPositionState) {
            case RobotPositionStateDefault:
                [self shoot];
                _lastPositionState = RobotPositionStateDefault;
                [self getArenaData];
                _lastKnownPosition = _arenaCenter;
                [self createSniperPositions];
                [self aimAtPosition:_lastKnownPosition];
                _currentPositionState = RobotPositionStateBackingUpToWall;
                break;
            case RobotPositionStateBackingUpToWall:
                _lastPositionState = RobotPositionStateBackingUpToWall;
                [self moveBack:5];
                break;
            case RobotPositionStateMoving:
                [self moveAhead:10];
                if (_enemyPositionState == EnemyPositionKnown) {
                    [self aimAtPosition:_lastKnownPosition];
                }
                [self fireAhead];
                _currentPositionState = RobotPositionStateMoving;
                
                break;
            case RobotPositionStateSniping:
                
                break;
        }
    }
}

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

- (void)createSniperPositions {
    CGFloat xOffset = 50;
    CGFloat yOffset = 50;
    
    CGRect sniperPositionsRect = CGRectInset(_arenaRect, xOffset, yOffset);
    CGFloat minX = CGRectGetMinX(sniperPositionsRect);
    CGFloat minY = CGRectGetMinY(sniperPositionsRect);
    CGFloat maxX = CGRectGetMaxX(sniperPositionsRect);
    CGFloat maxY = CGRectGetMaxY(sniperPositionsRect);
    
    CGPoint bottomLeft = CGPointMake(minX, minY);
    CGPoint bottomRight = CGPointMake(maxX, minY);
    CGPoint topRight = CGPointMake(maxX, maxY);
    CGPoint topLeft = CGPointMake(minX, maxY);
    
    _snipingPositions = [NSMutableArray new];
    [_snipingPositions addObject:[NSValue valueWithCGPoint:bottomLeft]];
    [_snipingPositions addObject:[NSValue valueWithCGPoint:bottomRight]];
    [_snipingPositions addObject:[NSValue valueWithCGPoint:topRight]];
    [_snipingPositions addObject:[NSValue valueWithCGPoint:topLeft]];
}

- (CGPoint)closestSnipingPosition {
    CGFloat distanceToClosestSnipingPoint = _arenaWidth;
    CGPoint closestSnipingPoint = _arenaCenter;
    for (NSValue *pointValue in _snipingPositions) {
        CGPoint snipingPoint = [pointValue CGPointValue];
        CGFloat distanceToSnipingPoint = [self distanceBetweenPointA:self.position andPointB:snipingPoint];
        if (distanceToSnipingPoint < distanceToClosestSnipingPoint) {
            distanceToClosestSnipingPoint = distanceToSnipingPoint;
            closestSnipingPoint = snipingPoint;
        }
    }
    return closestSnipingPoint;
}


- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    if (_currentPositionState == RobotPositionStateBackingUpToWall) {
        [self turnRobotRight:90];
        if (_enemyPositionState == EnemyPositionKnown) {
            [self aimAtPosition:_lastKnownPosition];
        } else {
            [self aimAtPosition:_arenaCenter];
        }
        _currentPositionState = RobotPositionStateMoving;
    }
    switch (hitDirection) {
        case RobotWallHitDirectionFront:
            [self turnRobotLeft:90];
            if (_enemyPositionState == EnemyPositionUnknown) {
                [self aimAtPosition:_arenaCenter];
                _currentAimAngle = RobotAimAngle45;
            }
            break;
        case RobotWallHitDirectionRear:
            break;
        case RobotWallHitDirectionLeft:
            break;
        case RobotWallHitDirectionRight:
            
            break;
        default:
            break;
    }
}

- (void)gotHit {
    [self cancelActiveAction];
    _myHitCount++;
    _lastShotTimeStamp = [self currentTimestamp];
    if ((_myHitCount > _enemyHitCount && [self timeSinceLastShotTaken] < 3) || (_enemyPositionState == EnemyPositionUnknown)) {
        [self moveAhead:50];
        if (_enemyPositionState == EnemyPositionKnown) {
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
    _enemyPositionState = EnemyPositionKnown;
    
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
    _shotsFired++;
    if (_enemyPositionState == EnemyPositionKnown) {
        CGPoint guessPoint = CGPointMake(_lastKnownPosition.x -_enemySlope, _lastKnownPosition.y - _enemySlope);
        [self aimAtPosition:guessPoint];
    }
    
    CGFloat halfway = abs(self.headingDirection.x*_arenaWidth/2) + abs(self.headingDirection.y*_arenaHeight/2);
    if ([self distanceFromWall] < halfway && _shotsFired > 2 && _currentAimAngle == RobotAimAngle45) {
        [self aimAtPosition:_arenaCenter];
        _currentAimAngle = RobotAimAngle90;
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

#pragma mark - World Information

- (NSInteger)timeSinceLastScan {
    return [self currentTimestamp] - _lastKnownPositionTimestamp;
}

- (NSInteger)timeSinceLastShotTaken {
    return [self currentTimestamp] - _lastShotTimeStamp;
}


- (CGFloat)distanceFromWall {
    CGFloat wallX = (self.headingDirection.x * _arenaCenter.x) + _arenaCenter.x;
    CGFloat wallY = (self.headingDirection.y * _arenaCenter.y) + _arenaCenter.y;
    
    CGFloat distanceX = self.position.x - wallX;
    CGFloat distanceY = self.position.y - wallY;
    CGFloat distance = abs(self.headingDirection.x * distanceX) + abs(self.headingDirection.y * distanceY);
    return distance;
}

- (CGPoint)arenaPointFromDirection:(CGPoint)point {
    CGFloat x = [self arenaDimensions].width/2 * point.x;
    CGFloat y = [self arenaDimensions].height/2 * point.y;
    return CGPointMake(x,y);
}

- (CGFloat)distanceBetweenPointA:(CGPoint)pointA
                       andPointB:(CGPoint)pointB {
    CGFloat xDelta = powf((pointA.x - pointB.x),2);
    CGFloat yDelta = powf((pointA.y - pointB.y),2);
    CGFloat distance = sqrtf(xDelta + yDelta);
    return distance;
}

@end
