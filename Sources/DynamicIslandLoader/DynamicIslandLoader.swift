import UIKit

public class DynamicIslandLoader: UIView, CAAnimationDelegate {
    public var colors: [UIColor] = [.red, .blue]
    public var currentColorIndex = 0
    public var animateColorsChange = false
    
    private let mainLayer: CAShapeLayer = CAShapeLayer()
    private let secondarylLayer: CAShapeLayer = CAShapeLayer()
    private var isAnimating = false
    fileprivate var restoreAnimation = false
    fileprivate var addedToWindow = false
    fileprivate var dissmissTriggered = false
    
    public init() {
        super.init(frame: .zero)
        self.registerForAppEvents()
    }
    
    func addToWindow() {
        if let window = UIApplication.shared.connectedScenes
            .flatMap({ ($0 as? UIWindowScene)?.windows ?? [] })
            .last(where: { $0.isKeyWindow }), isAvailable {
                addLoader(toContext: window)
                addedToWindow = true
            }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        guard !isAnimating else { return }
        if !addedToWindow {
            self.addToWindow()
        }
        isAnimating = true
        resetProgressIndicator()
        
        updateVisibility(isHidden: false)
        mainLayer.add(mainLayerMovingAnimation, forKey: nil)
        secondarylLayer.add(secondarylLayerMovingAnimation, forKey: nil)
       
        if animateColorsChange {
            animateColorChange()
        }
    }
    
    public func hide() {
        guard !dissmissTriggered else { return }
        dissmissTriggered = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            self.updateVisibility(isHidden: true)
            self.resetProgressIndicator()
            
            self.isAnimating = false
            self.restoreAnimation = false
            self.dissmissTriggered = false
        }
    }
    
    private func addLoader(toContext context: UIWindow) {
        initLoaderLayers()
        context.addSubview(self)
        context.bringSubviewToFront(self)
    }
    
    private func initLoaderLayers() {
        let size = CGSize(width: 126.0, height: 37.33)
        let origin = CGPoint(x: UIScreen.main.bounds.midX - size.width / 2, y: 11)
        let rect = CGRect(origin: origin, size: CGSize(width: 126.0, height: 37.33))
        let cornerRadius = size.width / 2
        let dynamicIslandPath = UIBezierPath(roundedRect: rect,
                                             byRoundingCorners: [.allCorners],
                                             cornerRadii: CGSize(width: cornerRadius,
                                                                 height: cornerRadius))
        mainLayer.path = dynamicIslandPath.cgPath
        secondarylLayer.path = dynamicIslandPath.cgPath
        
        if #available(iOS 16.0, *) {
            mainLayer.cornerCurve = .continuous
        }
        mainLayer.lineCap = .round
        mainLayer.fillRule = .evenOdd
        mainLayer.strokeColor = UIColor.red.cgColor
        mainLayer.strokeStart = 0
        mainLayer.strokeEnd = 1
        mainLayer.lineWidth = 5
        
        if #available(iOS 16.0, *) {
            secondarylLayer.cornerCurve = .continuous
        }
        secondarylLayer.lineCap = .round
        secondarylLayer.fillRule = .evenOdd
        secondarylLayer.strokeColor = UIColor.red.cgColor
        secondarylLayer.strokeStart = 0
        secondarylLayer.strokeEnd = 0
        secondarylLayer.lineWidth = 5
        secondarylLayer.fillColor = UIColor.clear.cgColor
        
        layer.addSublayer(mainLayer)
        layer.addSublayer(secondarylLayer)
    }
    
    private func updateVisibility(isHidden: Bool) {
        mainLayer.isHidden = isHidden
        secondarylLayer.isHidden = isHidden
    }
    
    private func resetProgressIndicator() {
        mainLayer.removeAllAnimations()
        secondarylLayer.removeAllAnimations()
        mainLayer.strokeStart = 0
        mainLayer.strokeEnd = 1
        secondarylLayer.strokeStart = 0
        secondarylLayer.strokeEnd = 0
        currentColorIndex = 0
    }
}

extension DynamicIslandLoader {
    public var isAvailable: Bool {
        if #unavailable(iOS 16) {
            return false
        }
        
        #if targetEnvironment(simulator)
            let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        #endif
        
        let hasIsland = identifier == "iPhone15,2" || identifier == "iPhone15,3" ||
                        identifier == "iPhone15,4" || identifier == "iPhone15,5" ||
                        identifier == "iPhone16,1" || identifier == "iPhone16,2"
        return hasIsland
    }
}

extension DynamicIslandLoader {
    fileprivate var mainLayerMovingAnimation: CAAnimationGroup {
        let animationStart = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.strokeStart))
        animationStart.values = [0, 0, 0.75]
        animationStart.keyTimes = [0, 0.25, 1]
        animationStart.duration = 2
        
        let animationEnd = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
        animationEnd.values = [0, 0.25, 1]
        animationEnd.keyTimes = [0, 0.25, 1]
        animationEnd.duration = 2
        
        let group = CAAnimationGroup()
        group.duration = 2
        group.repeatCount = .infinity
        group.animations = [animationStart, animationEnd]
        return group
    }
    
    fileprivate var secondarylLayerMovingAnimation: CAAnimationGroup {
        let animationStart = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeStart))
        animationStart.fromValue = 0.75
        animationStart.toValue = 1
        animationStart.duration = 0.5
        
        let animationEnd = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
        animationEnd.fromValue = 1
        animationEnd.toValue = 1
        animationEnd.duration = 0.5
        
        let group = CAAnimationGroup()
        group.duration = 2
        group.repeatCount = .infinity
        group.animations = [animationStart, animationEnd]
        return group
    }
}

extension DynamicIslandLoader {
    func animateColorChange() {
        let currentIndex = currentColorIndex
        let currentColor = colors[currentIndex]
        
        currentColorIndex += 1
        if currentColorIndex == colors.count {
            currentColorIndex = 0
        }
        
        let nextColorIndex = currentColorIndex
        let nextColor = colors[nextColorIndex]
        animateColorChange(from: currentColor, to: nextColor, layer: mainLayer, setDelegate: true)
        animateColorChange(from: currentColor, to: nextColor, layer: secondarylLayer)
    }
    
    func animateColorChange(from: UIColor, to: UIColor, layer: CAShapeLayer, setDelegate: Bool = false) {
        let animColor = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeColor))
        animColor.fromValue = from.cgColor
        animColor.toValue = to.cgColor
        animColor.duration = 1
        animColor.repeatCount = 1
        
        if setDelegate {
            animColor.delegate = self
            animColor.setValue(true, forKey: "colorChange")
        }

        layer.strokeColor = to.cgColor
        layer.add(animColor, forKey: nil)
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim.value(forKey: "colorChange") != nil && isAnimating {
            animateColorChange()
        }
    }
}

extension DynamicIslandLoader {
    fileprivate func registerForAppEvents() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground),
                                       name: UIApplication.willResignActiveNotification,
                                       object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
    }
    
    @objc func appMovedToBackground() {
        isAnimating = false
        updateVisibility(isHidden: true)
        resetProgressIndicator()
        
        restoreAnimation = true
    }
    
    @objc func appMovedToForeground() {
        guard restoreAnimation else { return }
        show()
    }
}
