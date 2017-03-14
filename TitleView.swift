//
//  TitleView.swift
//  Newsboard
//
//

import UIKit

class TitleView: UIView {
    
    var currentPath = UIBezierPath()
    
    override func draw(_ rect: CGRect) {
        currentPath.stroke()
    }
    
    func drawPath(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            currentPath.lineWidth = 3.0
            UIColor.red.setStroke()
            let spot = recognizer.location(in: self)
            currentPath.move(to: spot)
        } else if recognizer.state == .changed {
            let translatedSpot = recognizer.location(in: self)
            currentPath.addLine(to: translatedSpot)
        } else if recognizer.state == .ended {
            setNeedsDisplay()
        }
    }
    
    var visualEffect: UIVisualEffectView?
    
    func blurImage(_ recognizer: UITapGestureRecognizer) {
        recognizer.numberOfTapsRequired = 2
        if recognizer.state == .ended {
            if visualEffect == nil {
                let blur = UIBlurEffect(style: .light)
                visualEffect = UIVisualEffectView(effect: blur)
                visualEffect?.frame = self.bounds
                self.addSubview(visualEffect!)
            }
        }
    }
    
    func unblurImage(_ recognizer: UITapGestureRecognizer) {
        recognizer.numberOfTapsRequired = 1
        if let effect = visualEffect {
            effect.removeFromSuperview()
            visualEffect = nil
        }
    }
    
}

