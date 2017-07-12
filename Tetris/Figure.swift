//  Created by Andy on 08/03/2017.
//  Copyright © 2017 Andy. All rights reserved.

import Foundation

class Figure : CustomDebugStringConvertible
{
    enum Shape: UInt32 {
        case S = 0
        case ReverseS
        case Beam
        case Square
        case Tee
        case L
        case J

        case Undefined = 100
    }

    init(shape: Shape, blocks: Array<Block> = Array<Block>(), field: Field) {
        self.shape = shape
        self.blocks = blocks
        self.field = field
    }

    enum SlideDirection
    {
        case Left
        case Right
        case Down
    }
    
    func canSlide(_ direction: SlideDirection, steps: Int) -> Bool {
        for block in blocks {
            let block = Block(x: block.x, y: block.y)
            switch direction
            {
            case .Left:     block.x -= steps
            case .Right:    block.x += steps
            case .Down:     block.y += steps
            }
            if !canMoveTo(block) {
                return false
            }
        }
        return true
    }
    
    func slide(_ direction: SlideDirection, steps: Int) {
        
        var xSteps = 0, ySteps = 0
        switch direction
        {
        case .Left:     xSteps -= steps
        case .Right:    xSteps += steps
        case .Down:     ySteps += steps
        }
        blocks.forEach { $0.x += xSteps; $0.y += ySteps }
    }
    
    func canMoveDown() -> Bool {
        for block in blocks {
            let newBlock = Block(x: block.x, y: block.y + 1)
            if !canMoveTo(newBlock) {
                return false
            }
        }
        return true
    }
    
    func moveDown() {
        blocks.forEach { $0.y += 1 }
    }
    
    func canRotate(around center: Block) -> Bool {
        for block in blocks {            
            if block == center {
                continue
            }
            
            let xDifference = center.x - block.x
            let yDifference = center.y - block.y
            
            let newBlock = Block(x: center.x + yDifference, y: center.y - xDifference)
            
            if !canMoveTo(newBlock) {
                return false
            }
        }
        
        return true
    }
    
    func rotate(around center: Block) {
        for block in blocks {
            if block == center {
                continue
            }
            
            let xDifference = center.x - block.x
            let yDifference = center.y - block.y
            
            block.x = center.x + yDifference
            block.y = center.y - xDifference
        }
    }
    
    private func canMoveTo(_ block: Block) -> Bool {
        if block.x < 0 || block.x >= field.width || block.y < 0 || block.y >= field.height {
            return false
        }
        
        if let figure = field.oldFigures[block] {
            if figure !== self {
                return false
            }
        }
        
        return true
    }
        
    func removeBlocksInRow(_ row: Int) {
        blocks = blocks.filter { $0.y != row }
    }
    
    func isBroken() -> Bool {
        let n = blocks.count
        if n <= 1 {
            return false
        }
        
        var numberOfConnections = 0
        for i in 1...(n-1) {
            for j in (i+1)...n {
                let b1 = blocks[i-1]
                let b2 = blocks[j-1]
                if b1.adjacentTo(b2) {
                    numberOfConnections += 1
                }
            }
        }
        return numberOfConnections == 0
    }
    
    func breakFigure() -> Figure {
        let newFigure = Figure(shape: self.shape, blocks: [blocks.first!], field: field)
        blocks.removeFirst()
        
        for index in stride(from: blocks.count - 1, through: 0, by: -1) {
            if newFigure.blocks.first!.adjacentTo(blocks[index]) {
                newFigure.blocks.append(blocks[index])
            }
        }
        
        return newFigure
    }
    
    func isFloating() -> Bool {
        for block in blocks {
            if block.y == (field.height-1) {
                return false
            }
            let figureBelow = field.oldFigures[Block(x: block.x, y: block.y + 1)]
            if figureBelow != nil && figureBelow !== self && !figureBelow!.isFloating() {
                return false
            }
        }
        
        return true
    }
    
    var debugDescription: String {
        return "Figure(\(blocks))"
    }
    
    let shape: Shape

    private(set) var blocks: Array<Block>
    
    private unowned var field: Field
}
