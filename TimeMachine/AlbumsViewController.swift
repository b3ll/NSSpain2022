//
//  ViewController.swift
//  TimeMachine
//
//  Created by Adam Bell on 9/4/22.
//

import Decomposed
import Motion
import UIKit

class AlbumsViewController: UIViewController, UIGestureRecognizerDelegate {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let photoViews: [PhotoView] = {
        [
            UIImage(named: "10-4"),
            UIImage(named: "10-6"),
            UIImage(named: "10-7"),
            UIImage(named: "10-9"),
            UIImage(named: "10-10"),
            UIImage(named: "11-0"),
            UIImage(named: "13-0"),
        ].compactMap { image in
            let photoView = PhotoView(image: image)
            photoView.layer.borderWidth = 1.0
            photoView.layer.borderColor = UIColor.white.cgColor
            photoView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
            photoView.layer.shadowColor = UIColor.black.cgColor
            photoView.layer.shadowRadius = 4.0
            photoView.layer.shadowOpacity = 0.4
            photoView.isUserInteractionEnabled = true
            photoView.enableBouncyBehavior = true

            return photoView
        }
    }()

    var positionAnimations = [PhotoView: SpringAnimation<CGPoint>]()
    var boundsAnimations = [PhotoView: SpringAnimation<CGRect>]()
    var initialPickupLocations = [PhotoView: CGPoint]()

    var presentationAnimations = [PhotoView: SpringAnimation<CGPoint>]()
    var dimmingViews = [PhotoView: UIView]()

    var gestureRecognizers = [UIPanGestureRecognizer]()

    var pickedUpPhoto: PhotoView?

    let titleLabel = UILabel(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Time Machine"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 34.0)
        view.addSubview(titleLabel)

        view.backgroundColor = .systemGray6

        photoViews.forEach { photoView in
            let pickupGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPickup(_:)))
            pickupGestureRecognizer.delegate = self
            gestureRecognizers.append(pickupGestureRecognizer)
            photoView.addGestureRecognizer(pickupGestureRecognizer)

            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPickup(_:)))
            photoView.addGestureRecognizer(tapGestureRecognizer)

            let positionAnimation = SpringAnimation<CGPoint>(initialValue: .zero, response: 0.5, dampingRatio: 0.9)
            positionAnimation.onValueChanged(disableActions: true) { newPosition in
                photoView.layer.position = newPosition
            }
            positionAnimations[photoView] = positionAnimation

            view.addSubview(photoView)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(x: 16.0, y: additionalSafeAreaInsets.top + 100.0)

        if pickedUpPhoto == nil, positionAnimations.values.allSatisfy({ $0.hasResolved() }) {
            photoViews.enumerated().forEach { (index, photoView) in
                let layoutInfo = collapsedBoundsAndPositionFor(photoView, at: index)
                photoView.layer.bounds = layoutInfo.bounds
                photoView.layer.position = layoutInfo.position
            }
        }
    }

    private func collapsedBoundsAndPositionFor(_ photoView: PhotoView, at index: Int? = nil) -> (bounds: CGRect, position: CGPoint) {
        let mappedIndex = index ?? photoViews.firstIndex(of: photoView)!
        let edgePadding = 16.0

        let photoPadding = 12.0
        let photoAspectRatio = 5.0 / 7.0
        let maxAcross = 2

        let bounds = view.bounds

        let photoWidth = (bounds.size.width - (Double(maxAcross - 1) * photoPadding) - (edgePadding * 2.0)) / Double(maxAcross)
        let photoHeight = photoWidth * photoAspectRatio

        let xIndex = mappedIndex % maxAcross
        let yIndex = Int(floor(Double(mappedIndex) / Double(maxAcross)))

        let photoFrame = CGRect(x: edgePadding + (Double(xIndex) * (photoWidth + photoPadding)), y: edgePadding + (Double(yIndex) * (photoHeight + photoPadding)) + titleLabel.frame.maxY + 16.0, width: photoWidth, height: photoHeight)

        let photoViewBounds = CGRect(origin: .zero, size: CGSize(width: photoWidth, height: photoHeight))
        let photoViewPosition = CGPoint(x: photoFrame.midX, y: photoFrame.midY)

        return (photoViewBounds, photoViewPosition)
    }

    // MARK: - Pickup Interaction

    @objc private func didPickup(_ gestureRecognizer: UIGestureRecognizer) {
        let photoView = gestureRecognizer.view as! PhotoView

        if let tapGestureRecognizer = gestureRecognizer as? UITapGestureRecognizer {
            if tapGestureRecognizer.state == .ended {
                pickUp(photoView)

                let pickupLocation = photoView.layer.position
                initialPickupLocations[photoView] = pickupLocation
                positionAnimations[photoView]?.stop()
                positionAnimations[photoView]?.updateValue(to: CGPoint(x: pickupLocation.x, y: pickupLocation.y), postValueChanged: true)

                letGo(photoView)

                open(photoView)
                return
            }
        }

        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: view)
            let velocity = panGestureRecognizer.velocity(in: view)

            switch panGestureRecognizer.state {
                case .began:
                    pickUp(photoView)
                    initialPickupLocations[photoView] = photoView.layer.position
                    positionAnimations[photoView]?.stop()

                case .changed:
                    if let initialPickupLocation = initialPickupLocations[photoView] {
                        positionAnimations[photoView]?.updateValue(to: CGPoint(x: initialPickupLocation.x + translation.x, y: initialPickupLocation.y + translation.y), postValueChanged: true)
                    }
                case .ended, .cancelled:
                    letGo(photoView)

                    if velocity.y < -450.0 {
                        open(photoView, velocity: velocity)
                    } else if velocity.y > 450.0 {
                        close(photoView, velocity: velocity)
                    } else {
                        if photoView.opened {
                            open(photoView, velocity: velocity)
                        } else {
                            close(photoView, velocity: velocity)
                        }
                    }
                default:
                    break
            }
        }
    }

    @objc private func pickUp(_ photoView: PhotoView) {
        self.pickedUpPhoto = photoView

        view.bringSubviewToFront(photoView)
    }

    @objc private func letGo(_ photoView: PhotoView) {
        self.pickedUpPhoto = nil
    }

    private func open(_ photoView: PhotoView, velocity: CGPoint? = nil) {
        self.pickedUpPhoto = photoView

        let dimmingView = dimmingViews[photoView] ?? {
            let dimmingView = UIView(frame: .zero)
            dimmingView.backgroundColor = .black.withAlphaComponent(0.8)
            dimmingView.layer.opacity = 0.0
            dimmingView.isUserInteractionEnabled = false
            dimmingViews[photoView] = dimmingView
            dimmingView.frame = view.bounds
            return dimmingView
        }()

        view.insertSubview(dimmingView, belowSubview: photoView)

        let boundsAnimation = boundsAnimations[photoView] ?? {
            let boundsAnimation = SpringAnimation<CGRect>(response: 0.4, dampingRatio: 0.8)
            boundsAnimation.updateValue(to: photoView.bounds)
            boundsAnimations[photoView] = boundsAnimation

            boundsAnimation.onValueChanged { [weak self] newBounds in
                photoView.bounds = newBounds
                dimmingView.alpha = self?.percentOpened(photoView, currentBounds: newBounds) ?? 0.0
            }

            return boundsAnimation
        }()

        boundsAnimation.toValue = expandedBounds(for: photoView)

        let positionAnimation = positionAnimations[photoView] ?? {
            let positionAnimation = SpringAnimation<CGPoint>(initialValue: .zero, response: 0.5, dampingRatio: 0.9)
            positionAnimation.onValueChanged(disableActions: true) { newPosition in
                photoView.layer.position = newPosition
            }
            positionAnimations[photoView] = positionAnimation
            return positionAnimation
        }()

        positionAnimation.toValue = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        if let velocity = velocity {
            positionAnimation.velocity = velocity
        }

        boundsAnimation.start()
        positionAnimation.start()

        photoView.opened = true
    }

    private func percentOpened(_ photoView: PhotoView, currentBounds: CGRect) -> CGFloat {
        let targetBounds = CGRect(origin: .zero, size: CGSize(width: view.bounds.size.width, height: view.bounds.size.width * (5.0 / 7.0)))
        let collapsedBounds = collapsedBoundsAndPositionFor(photoView).bounds

        let percent = (currentBounds.size.width - collapsedBounds.size.width) / (targetBounds.size.width - collapsedBounds.size.width)

        return percent
    }

    private func expandedBounds(for photoView: PhotoView) -> CGRect {
        return CGRect(origin: .zero, size: CGSize(width: view.bounds.size.width, height: view.bounds.size.width * (5.0 / 7.0)))
    }

    private func close(_ photoView: PhotoView, velocity: CGPoint? = nil) {
        guard let dimmingView = dimmingViews[photoView] else { return }

        dimmingView.removeFromSuperview()
        view.insertSubview(dimmingView, belowSubview: photoView)

        let boundsAnimation = boundsAnimations[photoView] ?? {
            let boundsAnimation = SpringAnimation<CGRect>(response: 0.4, dampingRatio: 0.8)
            boundsAnimation.updateValue(to: photoView.bounds)
            boundsAnimations[photoView] = boundsAnimation

            boundsAnimation.onValueChanged { [weak self] newBounds in
                photoView.bounds = newBounds
                dimmingView.alpha = self?.percentOpened(photoView, currentBounds: newBounds) ?? 0.0
            }

            return boundsAnimation
        }()

        let targetBounds = collapsedBoundsAndPositionFor(photoView, at: photoViews.firstIndex(of: photoView)!).bounds
        boundsAnimation.toValue = targetBounds

        let positionAnimation = positionAnimations[photoView]
        positionAnimation?.toValue = collapsedBoundsAndPositionFor(photoView, at: photoViews.firstIndex(of: photoView)!).position

        if let velocity = velocity {
            positionAnimation?.velocity = velocity
        }

        boundsAnimation.start()
        positionAnimation?.start()

        photoView.opened = false
    }

}

