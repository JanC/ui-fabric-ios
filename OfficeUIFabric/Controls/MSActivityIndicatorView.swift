//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

// MARK: MSActivityIndicatorViewSize

/**
 * `MSActivityIndicatorViewSize` defines the side size of the loader and the thickness of the loader stroke.
 */
@objc public enum MSActivityIndicatorViewSize: Int, CaseIterable {
    case xSmall
    case small
    case medium
    case large
    case xLarge

    public var sideSize: CGFloat {
        switch self {
        case .xSmall:
            return 12
        case .small:
            return 17
        case .medium:
            return 26
        case .large:
            return 35
        case .xLarge:
            return 40
        }
    }

    var strokeThickness: MSActivityIndicatorStrokeThickness {
        switch self {
        case .xSmall:
            return .small
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .xLarge:
            return .xLarge
        }
    }
}

// MARK: - MSActivityIndicatorStrokeThickness

enum MSActivityIndicatorStrokeThickness: CGFloat {
    case small = 1
    case medium = 2
    case large = 3
    case xLarge = 4
}

// MARK: - MSActivityIndicatorView

/**
 * `MSActivityIndicatorView` is meant to be used as a drop-in replacement of `UIActivityIndicatorView`. Its API strictly matches `UIActivityIndicatorView` API. The only exception is the replacement of `UIActivityIndicatorViewStyle` with `MSActivityIndicatorViewSize` that doesn't include any color definition.
 */
@objcMembers
open class MSActivityIndicatorView: UIView {
    public static func sizeThatFits(size: MSActivityIndicatorViewSize) -> CGSize {
        return CGSize(width: size.sideSize, height: size.sideSize)
    }

    private struct Constants {
        static let rotationAnimationDuration: TimeInterval = 0.7
        static let rotationAnimationKey: String = "rotationAnimation"
    }

    open var size: MSActivityIndicatorViewSize {
        get {
            return MSActivityIndicatorViewSize.allCases.first { $0.sideSize == self.sideSize } ?? .medium
        }
        set {
            if size != newValue {
                updateView(sideSize: newValue.sideSize, strokeThickness: newValue.strokeThickness.rawValue)
            }
        }
    }
    open var hidesWhenStopped: Bool = true
    open var color: UIColor = MSColors.ActivityIndicator.foreground {
        didSet {
            setupLoaderLayer()
        }
    }
    var angles: (startAngle: CGFloat, endAngle: CGFloat) = (CGFloat(3.0 * CGFloat.pi / 2.0), CGFloat.pi) {
        didSet {
            setupLoaderLayer()
        }
    }
    // Don't modify this directly. Instead, call `startAnimating` and `stopAnimating`
    @objc(isAnimating) public private(set) var isAnimating: Bool = false

    private var loaderLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.contentsScale = UIScreen.main.scale
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .bevel
        return shapeLayer
    }()
    private let loaderRotationAnimation: CABasicAnimation = {
        let loaderRotationAnimation = CABasicAnimation(keyPath: "transform.rotation")

        loaderRotationAnimation.fromValue = NSNumber(value: 0.0 as Double)
        loaderRotationAnimation.toValue = NSNumber(value: 2 * Double.pi)

        loaderRotationAnimation.duration = Constants.rotationAnimationDuration
        loaderRotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        loaderRotationAnimation.isRemovedOnCompletion = false
        loaderRotationAnimation.repeatCount = .infinity
        loaderRotationAnimation.fillMode = .forwards
        loaderRotationAnimation.autoreverses = false

        return loaderRotationAnimation
    }()
    private var sideSize: CGFloat = 0
    private var strokeThickness: CGFloat = 0

    public convenience init(size: MSActivityIndicatorViewSize) {
        self.init(sideSize: size.sideSize, strokeThickness: size.strokeThickness.rawValue)
    }

    public init(sideSize: CGFloat, strokeThickness: CGFloat) {
        super.init(frame: .zero)
        layer.addSublayer(loaderLayer)
        isHidden = true
        updateView(sideSize: sideSize, strokeThickness: strokeThickness)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func startAnimating() {
        if isAnimating {
            return
        }
        isAnimating = true

        isHidden = false
        loaderLayer.add(loaderRotationAnimation, forKey: Constants.rotationAnimationKey)
    }

    open func stopAnimating() {
        if !isAnimating {
            return
        }
        isAnimating = false

        loaderLayer.removeAnimation(forKey: Constants.rotationAnimationKey)

        if hidesWhenStopped {
            isHidden = true
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        loaderLayer.position = CGPoint(x: width / 2, y: height / 2)
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: sideSize, height: sideSize)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: sideSize, height: sideSize)
    }

    open override func sizeToFit() {
        frame.size = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }

    private func setupLoaderLayer() {
        let strokeRadius = (sideSize - strokeThickness) / 2.0
        let loaderPath = UIBezierPath(arcCenter: CGPoint(x: sideSize / 2.0, y: sideSize / 2.0), radius: strokeRadius, startAngle: angles.startAngle, endAngle: angles.endAngle, clockwise: true)

        loaderLayer.frame = CGRect(x: 0.0, y: 0.0, width: sideSize, height: sideSize)
        loaderLayer.strokeColor = color.cgColor
        loaderLayer.lineWidth = strokeThickness
        loaderLayer.path = loaderPath.cgPath

        setNeedsLayout()
    }

    private func updateView(sideSize: CGFloat, strokeThickness: CGFloat) {
        self.sideSize = sideSize
        self.strokeThickness = strokeThickness
        setupLoaderLayer()
        sizeToFit()
        invalidateIntrinsicContentSize()
    }
}
