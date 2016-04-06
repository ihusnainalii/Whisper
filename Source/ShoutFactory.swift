import UIKit

let shout = ShoutView()

public func Shout(announcement: Announcement, to: UIViewController, completion: (() -> ())? = {}) {
    shout.craft(announcement, to: to, completion: completion)
}

public class ShoutView: UIView {
    
    public struct Dimensions {
        public static let indicatorHeight: CGFloat = 6
        public static let indicatorWidth: CGFloat = 54
        public static let imageSize: CGFloat = 44
        public static var height: CGFloat = UIApplication.sharedApplication().statusBarHidden ? 70 : 80
        public static var textOffset: CGFloat? = nil
    }
    
    public private(set) lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorList.Shout.background
        view.alpha = 0.98
        view.clipsToBounds = true
        
        return view
    }()
    
    public private(set) lazy var gestureContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.userInteractionEnabled = true
        
        return view
    }()
    
    public private(set) lazy var indicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorList.Shout.dragIndicator
        view.layer.cornerRadius = Dimensions.indicatorHeight / 2
        view.userInteractionEnabled = true
        
        return view
    }()
    
    public private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = Dimensions.imageSize / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .ScaleAspectFill
        
        return imageView
    }()
    
    public private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontList.Shout.title
        label.textColor = ColorList.Shout.title
        label.numberOfLines = 1
        
        return label
    }()
    
    public private(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontList.Shout.subtitle
        label.textColor = ColorList.Shout.subtitle
        label.numberOfLines = 2
        
        return label
    }()
    
    public private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(ShoutView.handleTapGestureRecognizer))
        
        return gesture
        }()
    
    public private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(ShoutView.handlePanGestureRecognizer))
        
        return gesture
        }()
    
    public private(set) var announcement: Announcement?
    public private(set) var displayTimer = NSTimer()
    public private(set) var panGestureActive = false
    public private(set) var shouldSilent = false
    public private(set) var completion: (() -> ())?
    private var imageViewWidthConstraint: NSLayoutConstraint?
    private var imageViewToTitleLabelConstraint: NSLayoutConstraint?
    
    // MARK: - Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let offset: CGFloat = UIApplication.sharedApplication().statusBarHidden ? 2.5 : 5
        
        addSubview(backgroundView)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[bg]|", options: [], metrics: nil, views: ["bg": backgroundView]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[bg]|", options: [], metrics: nil, views: ["bg": backgroundView]))
        
        backgroundView.addSubview(indicatorView)
        backgroundView.addConstraint(NSLayoutConstraint(item: indicatorView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: backgroundView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[iv]-4-|", options: [], metrics: nil, views: ["iv": indicatorView]))
        backgroundView.addConstraint(NSLayoutConstraint(item: indicatorView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: Dimensions.indicatorHeight))
        backgroundView.addConstraint(NSLayoutConstraint(item: indicatorView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: Dimensions.indicatorWidth))
        
        backgroundView.addSubview(imageView)
        backgroundView.addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: backgroundView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 20))
        backgroundView.addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: backgroundView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: offset))
        let widthConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: Dimensions.imageSize)
        imageViewWidthConstraint = widthConstraint
        backgroundView.addConstraint(widthConstraint)
        backgroundView.addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: Dimensions.imageSize))
        
        backgroundView.addSubview(titleLabel)
        let inBetweenConstraint = NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: imageView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: Dimensions.textOffset ?? 8)
        imageViewToTitleLabelConstraint = inBetweenConstraint
        backgroundView.addConstraint(inBetweenConstraint)
        backgroundView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: backgroundView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: -20))
        backgroundView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: imageView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
        
        backgroundView.addSubview(subtitleLabel)
        backgroundView.addConstraint(NSLayoutConstraint(item: subtitleLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: titleLabel, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        backgroundView.addConstraint(NSLayoutConstraint(item: subtitleLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: titleLabel, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        backgroundView.addConstraint(NSLayoutConstraint(item: subtitleLabel, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: titleLabel, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        backgroundView.addConstraint(NSLayoutConstraint(item: subtitleLabel, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.LessThanOrEqual, toItem: imageView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        
        backgroundView.addSubview(gestureContainer)
        backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[gc(20)]|", options: [], metrics: nil, views: ["gc": gestureContainer]))
        backgroundView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[gc]|", options: [], metrics: nil, views: ["gc": gestureContainer]))
        
        clipsToBounds = false
        userInteractionEnabled = true
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOffset = CGSize(width: 0, height: 0.5)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 0.5
        
        addGestureRecognizer(tapGestureRecognizer)
        gestureContainer.addGestureRecognizer(panGestureRecognizer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ShoutView.orientationDidChange), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    // MARK: - Configuration
    
    public func craft(announcement: Announcement, to: UIViewController, completion: (() -> ())?) {
        Dimensions.height = UIApplication.sharedApplication().statusBarHidden ? 70 : 80
        
        panGestureActive = false
        shouldSilent = false
        configureView(announcement)
        shout(to: to)
        
        self.completion = completion
    }
    
    public func configureView(announcement: Announcement) {
        self.announcement = announcement
        imageView.image = announcement.image
        titleLabel.text = announcement.title
        subtitleLabel.text = announcement.subtitle
        
        displayTimer.invalidate()
        displayTimer = NSTimer.scheduledTimerWithTimeInterval(announcement.duration, target: self, selector: #selector(ShoutView.displayTimerDidFire), userInfo: nil, repeats: false)
        
        setupFrames()
    }
    
    public func shout(to controller: UIViewController) {
        let width = UIScreen.mainScreen().bounds.width
        if let controller = controller.navigationController {
            controller.view.addSubview(self)
        }
        else {
            controller.view.addSubview(self)
        }
        
        frame = CGRect(x: 0, y: -Dimensions.height, width: width, height: Dimensions.height)
        let newFrame = CGRect(x: 0, y: 0, width: width, height: Dimensions.height)
        
        UIView.animateWithDuration(0.35, animations: {
            self.frame = newFrame
        })
    }
    
    // MARK: - Setup
    
    public func setupFrames() {
        if imageView.image == nil {
            var offset: CGFloat = 0
            if let textOffset = Dimensions.textOffset {
                offset = textOffset
            }
            imageViewWidthConstraint?.constant = 0
            imageViewToTitleLabelConstraint?.constant = offset
        }
        else {
            imageViewWidthConstraint?.constant = Dimensions.imageSize
            imageViewToTitleLabelConstraint?.constant = Dimensions.textOffset ?? 8
        }
    }
    
    // MARK: - Actions
    
    public func silent() {
        let newFrame = CGRect(x: 0, y: -Dimensions.height, width: frame.width, height: frame.height)
        
        UIView.animateWithDuration(0.35, animations: {
            self.frame = newFrame
            }, completion: { _ in
                self.completion?()
                self.displayTimer.invalidate()
                self.removeFromSuperview()
        })
    }
    
    // MARK: - Timer methods
    
    public func displayTimerDidFire() {
        shouldSilent = true
        
        if panGestureActive { return }
        silent()
    }
    
    // MARK: - Gesture methods
    
    @objc private func handleTapGestureRecognizer() {
        guard let announcement = announcement else { return }
        announcement.action?()
        silent()
    }
    
    @objc private func handlePanGestureRecognizer() {
        let translation = panGestureRecognizer.translationInView(self)
        
        if panGestureRecognizer.state == .Changed || panGestureRecognizer.state == .Began {
            panGestureActive = true
            if translation.y >= 12 {
                frame.origin.y = 0
                frame.size.height = Dimensions.height + 12 + (translation.y) / 25
            }
            else if translation.y <= 0 {
                frame.size.height = Dimensions.height
                frame.origin.y = translation.y
            }
            else {
                frame.origin.y = 0
                frame.size.height = Dimensions.height + translation.y
            }
        }
        else {
            panGestureActive = false
            if translation.y < -5 || shouldSilent {
                UIView.animateWithDuration(0.2, animations: {
                    self.frame.origin.y = -Dimensions.height
                    self.frame.size.height = Dimensions.height
                    }, completion: { _ in
                        if translation.y < -5 {
                            self.completion?()
                            self.removeFromSuperview()
                        }
                    }
                )
            }
            else {
                UIView.animateWithDuration(0.2, animations: {
                    self.frame.size.height = Dimensions.height
                    }, completion: { _ in
                        if translation.y < -5 {
                            self.completion?()
                            self.removeFromSuperview()
                        }
                    }
                )
            }
        }
    }
    
    
    // MARK: - Handling screen orientation
    
    func orientationDidChange() {
        setupFrames()
    }
}
