//
//  BouncyButtonsViewController.swift
//  TimeMachine
//
//  Created by Adam Bell on 9/10/22.
//

import Motion
import UIKit

class BouncyLabel: UILabel {

    lazy private var bouncyAnimation = {
        let bouncyAnimation = SpringAnimation<CGPoint>(initialValue: CGPoint(x: 1.0, y: 1.0), response: 0.3, dampingRatio: 0.8)
        bouncyAnimation.onValueChanged(disableActions: true) { [weak self] newScale in
            self?.layer.scale = newScale
            self?.alpha = newScale.x
        }
        return bouncyAnimation
    }()

    public var hasBouncyBehavior: Bool = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if hasBouncyBehavior {
            bouncyAnimation.velocity = CGPoint(x: -5.0, y: -5.0)
            bouncyAnimation.toValue = CGPoint(x: 0.8, y: 0.8)
            bouncyAnimation.start()
        } else {
            self.alpha = 0.6
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        if hasBouncyBehavior {
            bounceBack()
        } else {
            self.alpha = 1.0
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if hasBouncyBehavior {
            bounceBack()
        } else {
            self.alpha = 1.0
        }
    }

    private func bounceBack() {
        bouncyAnimation.velocity = CGPoint(x: 15.0, y: 15.0)
        bouncyAnimation.toValue = CGPoint(x: 1.0, y: 1.0)
        bouncyAnimation.start()
    }

}

class BouncyButtonsViewController: UIViewController {

    lazy private var buttonStackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.spacing = 18.0
        stackView.distribution = .equalCentering
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(buttonStackView)

        let button1 = BouncyLabel(frame: .zero)
        button1.text = "Button"
        button1.textColor = .systemRed
        button1.isUserInteractionEnabled = true
        button1.hasBouncyBehavior = true

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(openButton1))
        button1.addGestureRecognizer(tap1)

        buttonStackView.addArrangedSubview(button1)

        let button2 = BouncyLabel(frame: .zero)
        button2.text = "Button"
        button2.textColor = .systemYellow
        button2.isUserInteractionEnabled = true
        button2.hasBouncyBehavior = true

        let tap2 = UITapGestureRecognizer(target: self, action: #selector(openButton2))
        button2.addGestureRecognizer(tap2)

        buttonStackView.addArrangedSubview(button2)

        let button3 = BouncyLabel(frame: .zero)
        button3.text = "Button"
        button3.textColor = .systemGreen
        button3.isUserInteractionEnabled = true
        button3.hasBouncyBehavior = true

        let tap3 = UITapGestureRecognizer(target: self, action: #selector(openButton3))
        button3.addGestureRecognizer(tap3)

        buttonStackView.addArrangedSubview(button3)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        buttonStackView.frame = CGRectInset(view.bounds, 80.0, 200.0)
    }
    
    @objc func openButton1() {

    }

    @objc func openButton2() {

    }

    @objc func openButton3() {

    }

}
