
import UIKit

class SwiftyRecordButton: SwiftyCamButton {
    
    private var outerCircle: UIView!
    private var circleAnimation: CAShapeLayer!
    private var innerCircle: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        drawButton()
    }
    
    private func drawButton() {
        self.backgroundColor = UIColor.clear
        outerCircle = UIView(frame: self.frame)
        outerCircle.layer.backgroundColor = UIColor.clear.cgColor
        outerCircle.layer.borderWidth = 6.0
        outerCircle.layer.borderColor = UIColor.white.cgColor
        outerCircle.layer.bounds = self.bounds
        outerCircle.layer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        outerCircle.layer.cornerRadius = self.frame.size.width / 2
        outerCircle.clipsToBounds = true
        self.addSubview(outerCircle)
    }
    public func animateCircle(duration: TimeInterval) {
        // We want to animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        // Set the animation duration appropriately
        animation.duration = duration
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue = 0
        animation.toValue = 1
        
        // Do a linear animation (i.e. the speed of the animation stays the same)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        // Set the circleLayer's strokeEnd property to 1.0 now so that it's the
        // right value when the animation ends.
        circleAnimation.strokeEnd = 1.0
        
        // Do the actual animation
        circleAnimation.add(animation, forKey: "animateCircle")
    }
    
    public func growButton(duration: TimeInterval) {
        innerCircle = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        innerCircle.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        innerCircle.backgroundColor = UIColor.red
        innerCircle.layer.cornerRadius = innerCircle.frame.size.width / 2
        innerCircle.clipsToBounds = true
        self.addSubview(innerCircle)

        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseOut, animations: {
            self.innerCircle.transform = CGAffineTransform(scaleX: 62.4, y: 62.4)
            self.outerCircle.transform = CGAffineTransform(scaleX: 1.352, y: 1.352)
            self.outerCircle.layer.borderWidth = (6 / 1.352)
    
        }, completion: nil)
        
        // Circle Animation for Recording Button
        // The path should be the entire circle.
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: outerCircle.layer.position.x, y: outerCircle.layer.position.y), radius: ( (outerCircle.layer.cornerRadius - 3.0) * 1.38), startAngle: CGFloat(Double.pi * 1.5), endAngle: CGFloat(Double.pi * 3.5), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        circleAnimation = CAShapeLayer()
        circleAnimation.path = circlePath.cgPath
        circleAnimation.fillColor = UIColor.clear.cgColor
        circleAnimation.strokeColor = UIColor.red.cgColor
        circleAnimation.lineWidth = 6.0;
        
        // Don't draw the circle initially
        circleAnimation.strokeEnd = 0.0
        
        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleAnimation)
    }
    
//    let pausedTime : CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
//    layer.speed = 0.0
//    layer.timeOffset = pausedTime
    
    public func shrinkButton() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            if(self.circleAnimation != nil){
                self.circleAnimation.removeFromSuperlayer()
                self.circleAnimation = nil;
            }
            self.innerCircle?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.outerCircle.transform  = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.outerCircle.layer.borderWidth = 6.0
            
        }, completion: { (success) in
            if((self.innerCircle) != nil){
                self.innerCircle.removeFromSuperview()
                self.innerCircle = nil
            }
        })
    }
}
