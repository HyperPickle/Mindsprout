import UIKit

/// The root UIKit view that assembles the tab bar with glass effects.
/// Uses UIGlassContainerEffect to enable morphing between the segmented control and FAB.
@available(iOS 26.0, *)
final class GlassTabBarView: UIView {
    let containerEffectView: UIVisualEffectView
    let segmentedGlassView: UIVisualEffectView
    let segmentedControl: TabBarSegmentedControl
    let fabGlassView: UIVisualEffectView
    let fabButton: UIButton

    private let spacing: CGFloat = Constants.fabSpacing
    private let contentPadding: CGFloat = Constants.contentPadding

    private(set) var tabCount: Int
    private var segmentedTrailingConstraint: NSLayoutConstraint?
    private(set) var action: FabBarAction
    private var fabTitleContentView: UIView?

    init(
        segmentedControl: TabBarSegmentedControl,
        tabCount: Int,
        action: FabBarAction
    ) {
        self.segmentedControl = segmentedControl
        self.tabCount = tabCount
        self.action = action

        // Create glass container effect for morphing
        let containerEffect = UIGlassContainerEffect()
        containerEffect.spacing = Constants.fabSpacing
        containerEffectView = UIVisualEffectView(effect: containerEffect)

        // Create segmented control glass effect
        let segmentedGlassEffect = UIGlassEffect()
        segmentedGlassEffect.isInteractive = true
        segmentedGlassView = UIVisualEffectView(effect: segmentedGlassEffect)

        // Create FAB button
        let fabGlassEffect = UIGlassEffect()
        fabGlassEffect.isInteractive = true
        fabGlassEffect.tintColor = action.tintColor
        fabGlassView = UIVisualEffectView(effect: fabGlassEffect)

        let button = UIButton(type: .custom)
        button.configuration = Self.makeButtonConfiguration(for: action)
        button.accessibilityLabel = action.accessibilityLabel
        button.accessibilityTraits = .button
        fabButton = button

        super.init(frame: .zero)

        // Ensure tint adjustment mode is automatic so views dim when sheets are presented
        tintAdjustmentMode = .automatic
        fabGlassView.tintAdjustmentMode = .automatic
        fabButton.tintAdjustmentMode = .automatic

        setupViews(action: action)
    }

    private func setupViews(action: FabBarAction) {
        // Add container effect view
        addSubview(containerEffectView)
        containerEffectView.translatesAutoresizingMaskIntoConstraints = false

        // Add segmented glass view to container's contentView
        containerEffectView.contentView.addSubview(segmentedGlassView)
        segmentedGlassView.translatesAutoresizingMaskIntoConstraints = false

        // Add segmented control to segmented glass view's contentView
        segmentedGlassView.contentView.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        // Add FAB glass view
        containerEffectView.contentView.addSubview(fabGlassView)
        fabGlassView.translatesAutoresizingMaskIntoConstraints = false

        fabGlassView.contentView.addSubview(fabButton)
        fabButton.translatesAutoresizingMaskIntoConstraints = false

        fabButton.addAction(UIAction { [weak self] _ in self?.action.action() }, for: .touchUpInside)

        installFabTitleContentView(for: action)

        // Extra bottom inset compensates for UISegmentedControl's internal padding,
        // visually centering the content within the glass container.
        let segmentedControlBottomInsetAdjustment: CGFloat = 1

        NSLayoutConstraint.activate([
            containerEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerEffectView.topAnchor.constraint(equalTo: topAnchor),
            containerEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            segmentedGlassView.leadingAnchor.constraint(equalTo: containerEffectView.contentView.leadingAnchor),
            segmentedGlassView.topAnchor.constraint(equalTo: containerEffectView.contentView.topAnchor),
            segmentedGlassView.bottomAnchor.constraint(equalTo: containerEffectView.contentView.bottomAnchor),

            segmentedControl.leadingAnchor.constraint(equalTo: segmentedGlassView.contentView.leadingAnchor, constant: contentPadding),
            segmentedControl.trailingAnchor.constraint(equalTo: segmentedGlassView.contentView.trailingAnchor, constant: -contentPadding),
            segmentedControl.topAnchor.constraint(equalTo: segmentedGlassView.contentView.topAnchor, constant: contentPadding),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentedGlassView.contentView.bottomAnchor, constant: -contentPadding - segmentedControlBottomInsetAdjustment),

            // FAB glass view
            fabGlassView.trailingAnchor.constraint(equalTo: containerEffectView.contentView.trailingAnchor),
            fabGlassView.topAnchor.constraint(equalTo: containerEffectView.contentView.topAnchor),
            fabGlassView.bottomAnchor.constraint(equalTo: containerEffectView.contentView.bottomAnchor),
            fabGlassView.widthAnchor.constraint(equalTo: fabGlassView.heightAnchor),

            // Fill the entire glass area so taps anywhere trigger the action
            fabButton.leadingAnchor.constraint(equalTo: fabGlassView.contentView.leadingAnchor),
            fabButton.trailingAnchor.constraint(equalTo: fabGlassView.contentView.trailingAnchor),
            fabButton.topAnchor.constraint(equalTo: fabGlassView.contentView.topAnchor),
            fabButton.bottomAnchor.constraint(equalTo: fabGlassView.contentView.bottomAnchor),
        ])

        // Set up the trailing constraint based on tab count
        segmentedTrailingConstraint = makeSegmentedTrailingConstraint()
        segmentedTrailingConstraint?.isActive = true
    }

    private static func makeButtonConfiguration(for action: FabBarAction) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        if action.title == nil {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: Constants.fabIconPointSize, weight: .medium)
            config.image = UIImage(systemName: action.systemImage, withConfiguration: symbolConfig)
            config.baseForegroundColor = action.iconTintColor
        }
        return config
    }

    private func installFabTitleContentView(for action: FabBarAction) {
        guard let title = action.title else { return }
        let contentView = TabItemContentView(title: title, symbolName: action.systemImage)
        contentView.tintColor = action.iconTintColor
        contentView.translatesAutoresizingMaskIntoConstraints = false
        fabGlassView.contentView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: fabGlassView.contentView.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: fabGlassView.contentView.centerYAnchor),
        ])
        fabTitleContentView = contentView
    }

    func updateAction(_ newAction: FabBarAction) {
        action = newAction

        fabTitleContentView?.removeFromSuperview()
        fabTitleContentView = nil

        fabButton.configuration = Self.makeButtonConfiguration(for: newAction)
        fabButton.accessibilityLabel = newAction.accessibilityLabel

        let newEffect = UIGlassEffect()
        newEffect.isInteractive = true
        newEffect.tintColor = newAction.tintColor
        fabGlassView.effect = newEffect

        installFabTitleContentView(for: newAction)
    }

    /// Creates the appropriate trailing constraint for the segmented glass view.
    /// For 3+ tabs, fills to the FAB. For fewer tabs, floats leading-aligned.
    private func makeSegmentedTrailingConstraint() -> NSLayoutConstraint {
        if tabCount >= 3 {
            segmentedGlassView.trailingAnchor.constraint(equalTo: fabGlassView.leadingAnchor, constant: -spacing)
        } else {
            segmentedGlassView.trailingAnchor.constraint(lessThanOrEqualTo: fabGlassView.leadingAnchor, constant: -spacing)
        }
    }

    /// Updates the tab count and swaps the trailing constraint to match.
    func updateTabCount(_ newCount: Int) {
        guard newCount != tabCount else { return }
        tabCount = newCount
        segmentedTrailingConstraint?.isActive = false
        segmentedTrailingConstraint = makeSegmentedTrailingConstraint()
        segmentedTrailingConstraint?.isActive = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Capsule shape for segmented control
        segmentedGlassView.cornerConfiguration = .capsule()

        // Circle shape for FAB button (capsule with equal width/height = circle)
        fabGlassView.cornerConfiguration = .capsule()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        // Update FAB glass effect tint when tintAdjustmentMode changes
        // Create a new effect since modifying existing effect's tintColor doesn't update visuals
        let newEffect = UIGlassEffect()
        newEffect.isInteractive = true
        newEffect.tintColor = action.tintColor
        fabGlassView.effect = newEffect
        if var config = fabButton.configuration {
            config.baseForegroundColor = action.iconTintColor
            fabButton.configuration = config
        }
        fabTitleContentView?.tintColor = action.iconTintColor
    }
}
