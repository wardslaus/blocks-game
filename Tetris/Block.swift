//  Created by Andy on 03/03/2017.
//  Copyright © 2017 Andy. All rights reserved.

class Block : Hashable, CustomDebugStringConvertible {
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    var hashValue: Int {
        return x.hashValue & y.hashValue
    }
    
    var debugDescription: String {
        return "Block(\(x), \(y))"
    }
    
    static func == (left: Block, right: Block) -> Bool {
        return left.x == right.x && left.y == right.y
    }
    
    func adjacentTo(_ other: Block) -> Bool {
        return
            (x == other.x && abs(y - other.y) == 1) ||
            (y == other.y && abs(x - other.x) == 1)
    }
    
    var x: Int
    var y: Int
}
