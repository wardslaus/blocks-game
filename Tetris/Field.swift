//  Created by Andy on 04/03/2017.
//  Copyright © 2017 Andy. All rights reserved.

import Foundation

class Field: NSObject {
    override init() {
        super.init()

        if let customWidthString = ProcessInfo.processInfo.environment["FIELD_WIDTH"] {
            if let customWidth = Int(customWidthString) {
                self.width = customWidth
            }
        }

        self.currentFigure = Figure(shape: .Undefined, field: self)
        spawnFigure()
        readPileFromFile()
    }
    
    static let modelUpdateNotification = "dataModelDidUpdateNotification"
    
    private(set) var width = 10
    private(set) var height = 22
    
    private var stepInterval = 1.0
    
    private var timer: Timer? = nil
    
    func nextStep() {
        if timer != nil {
            timer!.invalidate()
        }
        timer = Timer.scheduledTimer(timeInterval: stepInterval, target:self, selector: #selector(Field.step), userInfo: nil, repeats: false)
        modelChanged()
    }
    
    func pause() {
        if timer != nil {
            timer!.invalidate()
        }
        modelChanged()
    }
    
    func inProgress() -> Bool {
        return timer != nil && timer!.isValid
    }
    
    func reset() {
        if inProgress() {
            timer!.invalidate()
        }
        spawnFigure()
        oldFigures = [:]
        readPileFromFile()
        fallingOldFigures = []
        gameOver = false
        nextStep()
        modelChanged()
    }
    
    func tryToSlide(_ direction: Figure.SlideDirection, steps: Int) {
        if currentFigure == nil {
            return
        }
        
        var moved = false
        for _ in 1...steps {
            if currentFigure.canSlide(direction, steps: 1) {
                moved = true
                currentFigure.slide(direction, steps: 1)
            }
        }
        
        if moved {
            modelChanged()
        }
    }
    
    func tryToDrop() {
        if currentFigure == nil {
            return
        }
        
        var moved = false
        
        while currentFigure.canMoveDown() {
            currentFigure.moveDown()
            moved = true
        }
        
        if moved {
            dumpCurrentFigureIntoThePile()
            nextStep()
            modelChanged()
        }
    }
    
    func rotateFigure() {
        if currentFigureCenter == nil {
            return
        }
        
        if currentFigure.canRotate(around: currentFigureCenter!) {
            currentFigure.rotate(around: currentFigureCenter!)
            modelChanged()
        }
    }
    
    @objc private func step() {
        if gameOver {
            return
        }

        if fallingOldFigures.isEmpty {
            if currentFigure == nil {
                removeFilledRows()
                if fallingOldFigures.isEmpty {
                    spawnFigure()
                }                
            } else {
                tryToMoveCurrentFigureDown()
                if currentFigure == nil {
                    removeFilledRows()
                }
            }
        } else {
            tryToMoveFallingFiguresDown()
        }
        
        nextStep()
    }
    
    private func tryToMoveCurrentFigureDown() {
        if currentFigure == nil {
            return
        }
        
        if currentFigure.canMoveDown() {
            currentFigure.moveDown()
        } else {
            dumpCurrentFigureIntoThePile()
        }
        
        modelChanged()
    }
    
    private func tryToMoveFallingFiguresDown() {
        for figure in fallingOldFigures {
            for block in figure.blocks {
                oldFigures.removeValue(forKey: block)
            }
            figure.moveDown()
            for block in figure.blocks {
                oldFigures[block] = figure
            }
        }
        fallingOldFigures = fallingOldFigures.filter { $0.canMoveDown() }
    }
    
    private func spawnFigure() {
        dumpCurrentFigureIntoThePile()
        
        let shapeIndex = arc4random_uniform(Figure.Shape.J.rawValue+1)
        let centerX = width / 2 - 1
        let centerY = 1
        if let shape = Figure.Shape(rawValue: shapeIndex) {
            var blocks = Array<Block>()

            switch shape
            {
            case .S:
                currentFigureCenter = Block(x: centerX, y: centerY)
                blocks = [currentFigureCenter!,
                          Block(x: centerX,      y: centerY-1),
                          Block(x: centerX+1,    y: centerY),
                          Block(x: centerX+1,    y: centerY+1)]
            case .ReverseS:
                currentFigureCenter = Block(x: centerX, y: centerY)
                blocks = [currentFigureCenter!,
                          Block(x: centerX+1,    y: centerY-1),
                          Block(x: centerX+1,    y: centerY),
                          Block(x: centerX,      y: centerY+1)]
            case .Beam:
                currentFigureCenter = Block(x: centerX, y: centerY)
                blocks = [currentFigureCenter!,
                          Block(x: centerX,      y: centerY-1),
                          Block(x: centerX,      y: centerY+1),
                          Block(x: centerX,      y: centerY+2)]
            case .Square:
                currentFigureCenter = nil
                blocks = [Block(x: centerX,      y: centerY),
                          Block(x: centerX+1,    y: centerY-1),
                          Block(x: centerX+1,    y: centerY),
                          Block(x: centerX,      y: centerY-1)]
            case .Tee:
                currentFigureCenter = Block(x: centerX, y: centerY)
                blocks = [currentFigureCenter!,
                          Block(x: centerX-1,    y: centerY),
                          Block(x: centerX,      y: centerY-1),
                          Block(x: centerX+1,    y: centerY)]
            case .L:
                currentFigureCenter = Block(x: centerX, y: centerY)
                blocks = [currentFigureCenter!,
                          Block(x: centerX,      y: centerY-1),
                          Block(x: centerX,      y: centerY+1),
                          Block(x: centerX+1,    y: centerY+1)]
            case .J:
                currentFigureCenter = Block(x: centerX, y: centerY)
                blocks = [currentFigureCenter!,
                          Block(x: centerX,      y: centerY-1),
                          Block(x: centerX,      y: centerY+1),
                          Block(x: centerX-1,    y: centerY+1)]
            case .Undefined:
                print("Trying to spawn undefined shape")
            }

            currentFigure = Figure(shape: shape, blocks: blocks, field: self)
        }
        
        for block in currentFigure.blocks {
            if oldFigures[block] != nil {
                gameOver = true
                currentFigure = nil
                break
            }
        }
        
        modelChanged()
    }
    
    private func removeFilledRows() {
        var numberOfRemovedRows = 0
        
        for row in (0..<height).reversed() {
            var figuresInCurrentRow = Array<Figure>()
            var blocksInCurrentRow = Array<Block>()

            for col in 0..<width {
                if let figure = oldFigures[Block(x: col, y: row)] {
                    for block in figure.blocks {
                        if block.x == col && block.y == row {
                            blocksInCurrentRow.append(block)
                        }
                    }
                }
            }
            
            for block in blocksInCurrentRow {
                var alreadyAdded = false
                for figure in figuresInCurrentRow {
                    if figure.blocks.contains(where: {$0 == block}) {
                        alreadyAdded = true
                        break
                    }
                }
                
                if !alreadyAdded {
                    figuresInCurrentRow.append(oldFigures[block]!)
                }
            }
            
            if blocksInCurrentRow.count == width {
                for figure in figuresInCurrentRow {
                    figure.removeBlocksInRow(row)
                    if figure.isBroken() {
                        let newFigure = figure.breakFigure()
                        for b in newFigure.blocks {
                            oldFigures[b] = newFigure
                        }
                    }
                }
                numberOfRemovedRows += 1
                
                for block in blocksInCurrentRow {
                    oldFigures.removeValue(forKey: block)
                }
                
            } else if numberOfRemovedRows > 0 {
                for block in blocksInCurrentRow {
                    let figure = oldFigures.removeValue(forKey: block)
                    block.y += numberOfRemovedRows
                    oldFigures[block] = figure
                }
            }
        }
        
        var checkedBlocks = Set<Block>()
        for j in (0...height-1).reversed() {
            for i in 0...width-1 {
                if let figure = oldFigures[Block(x: i, y: j)] {
                    let figureBlocks = Set(figure.blocks)
                    if !checkedBlocks.intersection(figureBlocks).isEmpty {
                        continue
                    }

                    if figure.isFloating() {
                        fallingOldFigures.append(figure)
                    }

                    checkedBlocks = checkedBlocks.union(figureBlocks)
                }
            }
        }
    }
    
    private func dumpCurrentFigureIntoThePile() {
        if currentFigure != nil {
            for b in currentFigure.blocks {
                oldFigures[b] = currentFigure
            }
            currentFigure = nil
            currentFigureCenter = nil
        }
    }

    private func modelChanged() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Field.modelUpdateNotification), object: nil)
    }

    private func readPileFromFile() {
        let pileFile = ProcessInfo.processInfo.environment["PILE_FILE"]
        if pileFile == nil {
            return
        }

        let location = NSString(string: pileFile!).expandingTildeInPath
        do {
            let fileContent = try String(contentsOfFile: location)

            var blocks = Dictionary<String, Array<Block>>()

            let lines = fileContent.components(separatedBy: "\n").reversed()
            var j = height-1
            for line in lines {
                var i = 0
                for char in line.characters {
                    if char != " " {
                        if blocks[String(char)] == nil {
                            blocks[String(char)] = Array<Block>()
                        }
                        let block = Block(x: i, y: j)
                        assert(block.x < width && 0 < block.y && block.y < height)
                        blocks[String(char)]!.append(block)
                    }
                    i += 1
                }
                j -= 1
            }

            for (_, arrayOfBlocks) in blocks {
                let shapeIndex = arc4random_uniform(Figure.Shape.J.rawValue+1)
                let shape = Figure.Shape(rawValue: shapeIndex)!

                let figure = Figure(shape: shape, blocks: arrayOfBlocks, field: self)
                for block in figure.blocks {
                    oldFigures[block] = figure
                }
            }
        }
        catch {
            print("Failed to read the pile")
        }
    }
    
    private(set) var currentFigure: Figure!
    private var currentFigureCenter: Block? = nil
    
    private(set) var oldFigures = Dictionary<Block, Figure>()
    private var fallingOldFigures = Array<Figure>()
    
    private(set) var gameOver = false
}
