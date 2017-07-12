//  Created by Andy on 23/02/2017.
//  Copyright © 2017 Andy. All rights reserved.

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tetris: TetrisView! 
    
    @IBOutlet weak var pauseButton: UIButton!
    
    var field = Field()
    
    var gameOverView: UIView? = nil

    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!

    func figureColor(_ figure: Figure) -> UIColor {
        switch(figure.shape)
        {
        case .Beam:
            return UIColor(hue: CGFloat(0.50), saturation: CGFloat(0.38), brightness: CGFloat(0.95), alpha: CGFloat(1.0))
        case .J:
            return UIColor(hue: CGFloat(0.57), saturation: CGFloat(0.54), brightness: CGFloat(1.0), alpha: CGFloat(1.0))
        case .L:
            return UIColor(hue: CGFloat(0.07), saturation: CGFloat(0.54), brightness: CGFloat(1.0), alpha: CGFloat(1.0))
        case .S:
            return UIColor(hue: CGFloat(0.32), saturation: CGFloat(0.40), brightness: CGFloat(0.95), alpha: CGFloat(1.0))
        case .ReverseS:
            return UIColor(hue: CGFloat(0.00), saturation: CGFloat(0.54), brightness: CGFloat(1.0), alpha: CGFloat(1.0))
        case .Square:
            return UIColor(hue: CGFloat(0.17), saturation: CGFloat(0.50), brightness: CGFloat(0.95), alpha: CGFloat(1.0))
        case .Tee:
            return UIColor(hue: CGFloat(0.78), saturation: CGFloat(0.40), brightness: CGFloat(1.0), alpha: CGFloat(1.0))
        case .Undefined:
            return UIColor.white
        }
    }

    func updateUI() {
        tetris.fieldWidth = field.width
        tetris.fieldHeight = field.height
        tetris.takenPositions.removeAll()
        
        tetris.takenPositions.removeAll()
        if let currentFigure = field.currentFigure {
            for block in currentFigure.blocks {
                tetris.takenPositions[block] = figureColor(currentFigure)
            }
        }
        for (block, figure) in field.oldFigures {
            tetris.takenPositions[block] = figureColor(figure)
        }
        
        pauseButton.setTitle(field.inProgress() ? "Pause" : "Play", for: .normal)
        
        if field.gameOver && gameOverView == nil {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
            
            gameOverView = UIVisualEffectView(effect: blurEffect)
            gameOverView!.frame = self.view.bounds
            gameOverView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            gameOverView!.alpha = 0.9
            self.view.addSubview(gameOverView!)
            
            let label = UILabel()
            label.text = "GAME OVER"
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 35)
            label.frame = gameOverView!.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            gameOverView!.addSubview(label)
            
            let button = UIButton()
            button.setTitle("Start again", for: .normal)
            button.setTitleColor(UIColor.blue, for: .normal)
            button.sizeToFit()
            button.addTarget(self, action: #selector(reset), for: .touchUpInside)
            
            gameOverView!.addSubview(button)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            button.translatesAutoresizingMaskIntoConstraints = false
            
            label.centerXAnchor.constraint(equalTo: gameOverView!.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: gameOverView!.centerYAnchor).isActive = true
            
            button.topAnchor.constraint(equalTo: label.layoutMarginsGuide.bottomAnchor, constant: 100.0).isActive = true
            button.centerXAnchor.constraint(equalTo: gameOverView!.centerXAnchor).isActive = true
        } else if !field.gameOver && gameOverView != nil {
            gameOverView!.removeFromSuperview()
            gameOverView = nil
        }
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateUI), name: NSNotification.Name(rawValue: Field.modelUpdateNotification), object: nil)
        field.nextStep()
    }
    
    @IBAction func slideFigure(_ sender: UIPanGestureRecognizer) {
        if field.inProgress() {
            switch sender.state {
            case .ended:
                let horizontalVelocity = sender.velocity(in: tetris).x
                let verticalVelocity = sender.velocity(in: tetris).y
                let swipeVelocity = CGFloat(1000.0)
                if verticalVelocity > swipeVelocity && abs(horizontalVelocity) < swipeVelocity {
                    field.tryToDrop()
                }
            case .changed:
                var translation = sender.translation(in: tetris)
                
                let coefficient = CGFloat(0.6)
                
                let xSteps = Int(translation.x / tetris.blockSize / coefficient)
                let ySteps = Int(translation.y / tetris.blockSize / coefficient)

                if xSteps != 0 && abs(xSteps) > abs(ySteps) {
                    field.tryToSlide(xSteps > 0 ? .Right : .Left, steps: abs(xSteps))
                    translation = CGPoint.zero
                    sender.setTranslation(translation, in: tetris)
                } else {
                    if ySteps > 0 {
                        field.tryToSlide(.Down, steps: ySteps)
                        translation = CGPoint.zero
                    } else if ySteps < 0 {
                        translation = CGPoint.zero
                    }
                }
                
                sender.setTranslation(translation, in: tetris)
            default:
                break
            }
        }
    }
    
    @IBAction func rotateFigure(_ sender: Any) {
        if field.inProgress() {
            field.rotateFigure()
        }
    }
    
    @IBAction func reset(_ sender: Any) {
        field.reset()
    }
    
    @IBAction func togglePause() {
        if field.inProgress() {
            field.pause()
        } else {
            field.nextStep()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

