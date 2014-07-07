//
//  AwesomeBestRobot.m
//  RobotWar
//
//  Created by Chad Rutherford on 7/1/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "AwesomeBestRobot.h"


typedef NS_ENUM(NSInteger, TurretState) {
    AwesomeStateScanning,
    AwesomeStateFiring,
    AwesomeStateMoving
};

static const float GUN_ANGLE_TOLERANCE = 2.0f;

@implementation AwesomeBestRobot {
    TurretState _currentState;
    float _timeSinceLastEnemyHit;
    CGPoint _lastKnownPosition;
    CGPoint _lastKnownPositionTimestamp;
    BOOL _direction;
    CGFloat gunAngle;
    CGFloat timeIdle;
    CGRect myRect;
}

- (id)init {
    if (self = [super init]) {
        _currentState = AwesomeStateMoving;
    }
    
    return self;
}

#pragma mark running
- (void)run {
    while (true) {
        switch (_currentState) {
            case AwesomeStateScanning:
                CCLOG(@"AwesomeStateScanning");
                timeIdle = self.currentTimestamp - _timeSinceLastEnemyHit;
                if (timeIdle >= 1.f){
                    //                    CCLOG(@"idle for more than 1s, moving now");
                    _currentState = AwesomeStateMoving;
                    
                }
                //                [self turnGunRight:30];
                gunAngle = [self angleBetweenGunHeadingDirectionAndWorldPosition:_lastKnownPosition];
                if (gunAngle <= 0) {
                    [self turnGunLeft:abs(gunAngle)];
                }else{
                    [self turnGunRight:abs(gunAngle)];
                }
                break;
            case AwesomeStateFiring:
                CCLOG(@"AwesomeStateFiring");
                timeIdle = self.currentTimestamp - _timeSinceLastEnemyHit;
                if (timeIdle > 1.f) {
                    // if haven't hit enemy in 1 seconds, then cancel and return to scanning
                    //                    CCLOG(@"idle for more than 1s, scanning now");
                    [self cancelActiveAction];
                    _currentState = AwesomeStateScanning;
                } else {
                    [self shoot];
                }
                break;
            case AwesomeStateMoving:
                if (_direction) {
                    [self moveAhead:10];
                } else{
                    [self moveBack:10];
                }
                break;
        }
    }
}

- (void)gotHit {
    [super gotHit];
    //    CCLOG(@"got hit and am now moving out of the way");
    //    CCLOG(@"%ld",_currentState);
    /*
     CGFloat gunAngle = [self angleBetweenGunHeadingDirectionAndWorldPosition:_lastKnownPosition];
     if (gunAngle >= 0) {
     [self turnGunLeft:abs(gunAngle)];
     }else{
     [self turnGunRight:abs(gunAngle)];
     }
     */
    if (_direction) {
        [self moveAhead:200];
        //        CCLOG(@"movingForward");
    }else{
        [self moveBack:200];
        //        CCLOG(@"movingBack");
    }
    
    [self shoot];
    _currentState = AwesomeStateMoving;
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    [self cancelActiveAction];
    
    switch (hitDirection) {
        case RobotWallHitDirectionFront:
            [self moveBack:200];
            //            CCLOG(@"changed direction front wall hit");
            _direction = NO;
            break;
        case RobotWallHitDirectionRear:
            [self moveAhead:200];
            //            CCLOG(@"changed direction back wall hit");
            _direction = YES;
            break;
        default:
            break;
    }
}

- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    // Calculate the angle between the turret and the enemy
    float angleBetweenTurretAndEnemy = [self angleBetweenGunHeadingDirectionAndWorldPosition:position];
    //    float AngleBetweenTurretAndEnemy = [self angleBetweenHeadingDirectionAndWorldPosition:position];
    
    
    //    CCLOG(@"Enemy Position: (%f, %f)", position.x, position.y);
    //    CCLOG(@"Enemy Spotted at Angle: %f", AngleBetweenTurretAndEnemy);
    //    CCLOG(@"Our position", );
    
    if (angleBetweenTurretAndEnemy > GUN_ANGLE_TOLERANCE) {
        [self cancelActiveAction];
        [self turnGunRight:abs(angleBetweenTurretAndEnemy)];
    }
    else if (angleBetweenTurretAndEnemy < -GUN_ANGLE_TOLERANCE) {
        [self cancelActiveAction];
        [self turnGunLeft:abs(angleBetweenTurretAndEnemy)];
    }
    //    [self moveBack:20];
    _timeSinceLastEnemyHit = self.currentTimestamp;
    _currentState = AwesomeStateFiring;
    _lastKnownPosition = position;
}


@end