//
//  mr3DAudioEngineDefine.swift
//  iACGEngine
//
//  Created by Martin.Ren on 16/2/6.
//  Copyright © 2016年 Martin.Ren. All rights reserved.
//

import Foundation

public enum MR3DAUDIO_ENGINE_ROOMTYPE
{
    case SmallRoom
    case MediumRoom
    case LargeRoom
    case MediumHall
    case LargeHall
    case Plate
    case MediumChamber
    case LargeChamber
    case Cathedral
    case LargeRoom2
    case MediumHall2
    case MediumHall3
    case LargeHall2
}

public enum MR3DAUDIO_ENGINE_SOURCE_STATUS
{
    case UNREADY
    case SUCCESS
    case PLAYING
    case STOPED
    case PAUSE
}

public struct mr3DAudioPosition {
    
    var x : Float
    var y : Float
    var z : Float
    
    public init (x : Float, y : Float, z :Float)
    {
        self.x = x
        self.y = y
        self.z = z
    }
}