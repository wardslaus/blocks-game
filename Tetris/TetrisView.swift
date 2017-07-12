//  Created by Andy on 23/02/2017.
//  Copyright © 2017 Andy. All rights reserved.

import UIKit

@IBDesignable
class TetrisView: UIView {
    var blockSize: CGFloat {
        if fieldWidth == 0 || fieldHeight == 0 {
            return 0
        } else {
            return floor(0.98 * min(bounds.width / CGFloat(fieldWidth), bounds.height / CGFloat(fieldHeight)) - 2*margin)
        }
    }
    private var margin: CGFloat = 1.0
    
    @IBInspectable var mainColor: UIColor = UIColor(white: 0.3, alpha: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var gridColor: UIColor = UIColor.gray {
        didSet {
            setNeedsDisplay()
        }
    }
        
    var fieldHeight = 20
    var fieldWidth = 12
    
    var takenPositions: Dictionary<Block, UIColor> = [Block(x:4, y:5): UIColor.red, Block(x:5, y:5): UIColor.red, Block(x:6, y:5): UIColor.red, Block(x:6, y:6): UIColor.red] {
        didSet {
            setNeedsDisplay()
        }
    }

    private var borderColors = Dictionary<UIColor, UIColor>()
    
    private func drawGrid() {
        gridColor.setStroke()
        
        let originX = (bounds.width - CGFloat(fieldWidth) * (blockSize + 2*margin))/2
        let originY = (bounds.height - CGFloat(fieldHeight) * (blockSize + 2*margin))/2
        
        let maxX = originX + CGFloat(fieldWidth) * (blockSize + 2*margin)
        let maxY = originY + CGFloat(fieldHeight) * (blockSize + 2*margin)
        
        for i in 0...fieldWidth {
            let line = UIBezierPath()
            line.lineWidth = margin*2
            let x = originX + CGFloat(i) * (blockSize + 2*margin)
            line.move(to: CGPoint(x: x, y: originY))
            line.addLine(to: CGPoint(x: x, y: maxY))
            line.stroke()
        }
        for i in 0...fieldHeight {
            let line = UIBezierPath()
            line.lineWidth = margin*2
            let y = originY + CGFloat(i) * (blockSize + 2*margin)
            line.move(to: CGPoint(x: originX, y: y))
            line.addLine(to: CGPoint(x: maxX, y: y))
            line.stroke()
        }
    }
    
    private func drawBlock(positionX: Int, positionY: Int, color: UIColor) {
        let originX = (bounds.width - CGFloat(fieldWidth) * (blockSize + 2*margin))/2
        let originY = (bounds.height - CGFloat(fieldHeight) * (blockSize + 2*margin))/2
        
        let x = originX + bounds.minX + CGFloat(positionX) * (blockSize + 2*margin)
        let y = originY + bounds.minY + CGFloat(positionY) * (blockSize + 2*margin)
        
        let outer = CGRect(x: x, y: y, width: blockSize + margin*2, height: blockSize + margin*2)
        let outerBlock = UIBezierPath(rect: outer)
        color.setFill()
        outerBlock.fill()

        var borderColor = borderColors[color]
        if borderColor == nil {
            var hue = CGFloat()
            var saturation = CGFloat()
            var brightness = CGFloat()
            var alpha = CGFloat()

            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            brightness *= 0.95

            borderColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)

            borderColors[color] = borderColor
        }

        borderColor!.setStroke()

        let b = UIBezierPath()
        b.move(to: CGPoint(x: outer.minX, y: outer.maxY-0.5))
        b.addLine(to: CGPoint(x: outer.maxX - 0.5, y: outer.maxY - 0.5))
        b.addLine(to: CGPoint(x: outer.maxX - 0.5, y: outer.minY))
        b.stroke()
    }

    override func draw(_ rect: CGRect) {
        drawGrid()
        
        for (block, color) in takenPositions {
            drawBlock(positionX: block.x, positionY: block.y, color: color)
        }
    }
}
