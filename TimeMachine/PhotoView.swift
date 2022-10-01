//
//  PhotoView.swift
//  TimeMachine
//
//  Created by Adam Bell on 9/9/22.
//

import Decomposed
import Motion
import UIKit

class PhotoView: UIImageView {

    let scaleAnimation: SpringAnimation<CGPoint>

    public var enableBouncyBehavior: Bool = false

    public var opened: Bool = false

    override init(image: UIImage?) {
        self.scaleAnimation = SpringAnimation<CGPoint>(initialValue: CGPoint(x: 1.0, y: 1.0), response: 0.3, dampingRatio: 0.8)
        super.init(image: image)

        scaleAnimation.onValueChanged(disableActions: true) { [weak self] newScale in
            self?.layer.scale = newScale
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard !opened, enableBouncyBehavior else { return }

        scaleAnimation.toValue = CGPoint(x: 0.8, y: 0.8)
        scaleAnimation.velocity = CGPoint(x: -8.0, y: -8.0)
        scaleAnimation.start()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard !opened, enableBouncyBehavior else { return }

        scaleAnimation.toValue = CGPoint(x: 0.8, y: 0.8)
        scaleAnimation.start()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        guard !opened || !layer.scale.x.approximatelyEqual(to: 1.0), enableBouncyBehavior else { return }

        scaleAnimation.toValue = CGPoint(x: 1.0, y: 1.0)
        scaleAnimation.start()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard !opened || !layer.scale.x.approximatelyEqual(to: 1.0), enableBouncyBehavior else { return }

        scaleAnimation.toValue = CGPoint(x: 1.0, y: 1.0)
        scaleAnimation.start()
    }

}
