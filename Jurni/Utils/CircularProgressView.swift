//
//  CircularProgressView.swift
//  Jurni
//
//  Created by Devrath Rathee on 31/01/23.
//

import UIKit

class CircularProgressView: UIView {

    var progressLayer = CAShapeLayer()
    var remainingLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        createCircularPath()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        createCircularPath()
    }
    
    var progressColor = UIColor.white{
        didSet{
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var remainingColor = UIColor.white{
        didSet{
            remainingLayer.strokeColor = remainingColor.cgColor
        }
    }
    
    func createCircularPath(){
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = self.frame.size.width/2
        let circlePath = UIBezierPath(arcCenter: CGPoint(x:frame.size.width/2, y:frame.size.height/2), radius: (frame.size.width - 1.5)/2, startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        
        remainingLayer.path = circlePath.cgPath
        remainingLayer.fillColor = UIColor.clear.cgColor
        remainingLayer.strokeColor = remainingColor.cgColor
        remainingLayer.lineWidth = 20.0
        remainingLayer.strokeEnd = 1.0
        layer.addSublayer(remainingLayer)
        
        progressLayer.path = circlePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = 20.0
        progressLayer.strokeEnd = 0.0
        layer.addSublayer(progressLayer)
        
    }
    
    func setProgressWithAnimation(duration:TimeInterval, value:Float){
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = 0
        animation.toValue = value
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        progressLayer.strokeEnd = CGFloat(value)
        progressLayer.add(animation, forKey: "animateprogress")
    }


}
