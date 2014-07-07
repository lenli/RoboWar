//
//  GeniusRobot.m
//  RobotWar
//
//  Created by Melanie H. on 7/3/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GeniusRobot.h"

typedef NS_ENUM(NSInteger, RobotState) {
    RobotStateDefault,
    RobotStateTurnaround,
    RobotStateFiring,
    RobotStateSearching
};

CGFloat angle; //how to angle your robot's gun
CGFloat direction; //which direction robot faces

@implementation GeniusRobot {
    RobotState _currentRobotState;
    CGPoint _lastKnownPosition;
    CGFloat _lastKnownPositionTimestamp;
}

- (void)run {
    while (true) {
        if (_currentRobotState == RobotStateFiring) {
            
            if ((self.currentTimestamp - _lastKnownPositionTimestamp) > 1.f) {
                _currentRobotState = RobotStateSearching;
            } else {
                angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:_lastKnownPosition];
                if (angle >= 0) {
                    [self turnGunRight:abs(angle)];
                } else {
                    [self turnGunLeft:abs(angle)];
                }
                [self shoot];
            }
        }
        
        if (_currentRobotState == RobotStateSearching) {
            //[self angleBetweenGunHeadingDirectionAndWorldPosition:_lastKnownPosition];
            NSInteger sweep = 5;
            if (direction == 1) { //hit back
                if (angle > 270 || angle < 90) {
                    angle = 180;
                }
                if (90 < angle < 180) {
                    [self turnGunRight:angle+sweep];
                    sweep +=5;
                    [self shoot];
                }
                else if (180 < angle < 270) {
                    [self turnGunLeft:angle-sweep];
                    sweep += 5;
                    [self shoot];
                }
                
            }
            else if (direction == 0) { //hit front
                if (angle < 270 || angle > 90) {
                    angle = 360;
                }
                if (270 < angle < 360) {
                    [self turnGunLeft:angle-sweep];
                    sweep +=5;
                    [self shoot];
                }
                else if (360 < angle < 90) {
                    [self turnGunLeft:angle+sweep];
                    sweep +=5;
                    [self shoot];
                }
            }
            /*if (angle >= 0) {
             
             } else {
             [self turnGunLeft:angle-sweep++];
             [self shoot];
             }*/
        }
        
        if (_currentRobotState == RobotStateDefault) {
            [self moveBack:100];
        }
    }
}

- (void)bulletHitEnemy:(Bullet *)bullet {
    [self shoot];
    // There are a couple of neat things you could do in this handler
}

- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    if (_currentRobotState != RobotStateFiring) {
        [self cancelActiveAction];
    }
    
    _lastKnownPosition = position;
    _lastKnownPositionTimestamp = self.currentTimestamp;
    _currentRobotState = RobotStateFiring;
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    [self cancelActiveAction];
    
    if (RobotWallHitDirectionFront) {
        _currentRobotState = RobotStateSearching;
        angle = 0;
        direction = 0;
    }
    else if (RobotWallHitDirectionRear) {
        _currentRobotState = RobotStateSearching;
        angle = 180;
        direction = 1;
    }
    /* if (_currentRobotState != RobotStateTurnaround) {
     [self cancelActiveAction];
     
     RobotState previousState = _currentRobotState;
     _currentRobotState = RobotStateTurnaround;
     
     // always turn to head straight away from the wall
     if (angle >= 0) {
     [self turnRobotLeft:abs(angle)];
     } else {
     [self turnRobotRight:abs(angle)];
     
     }
     
     [self moveAhead:20];
     
     _currentRobotState = previousState;
     }*/
}

@end