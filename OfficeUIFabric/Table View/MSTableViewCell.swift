//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

// MARK: MSTableViewCellAccessoryType

@objc public enum MSTableViewCellAccessoryType: Int {
    case none
    case disclosureIndicator
    case detailButton
    case checkmark

    private struct Constants {
        static let horizontalSpacing: CGFloat = 16
        static let height: CGFloat = 44
    }

    var icon: UIImage? {
        let icon: UIImage?
        switch self {
        case .none:
            icon = nil
        case .disclosureIndicator:
            icon = UIImage.staticImageNamed(OfficeUIFabricFramework.usesFluentIcons ? "chevron-right-20x20" : "disclosure")?.imageFlippedForRightToLeftLayoutDirection()
        case .detailButton:
            icon = UIImage.staticImageNamed(OfficeUIFabricFramework.usesFluentIcons ? "more-24x24" : "details")
        case .checkmark:
            icon = UIImage.staticImageNamed(OfficeUIFabricFramework.usesFluentIcons ? "checkmark-24x24" : "checkmark-blue-20x20")
        }
        return icon?.withRenderingMode(.alwaysTemplate)
    }

    var iconColor: UIColor? {
        switch self {
        case .none:
            return nil
        case .disclosureIndicator:
            return MSColors.Table.Cell.accessoryDisclosureIndicator
        case .detailButton:
            return MSColors.Table.Cell.accessoryDetailButton
        case .checkmark:
            return MSColors.Table.Cell.accessoryCheckmark
        }
    }

    var size: CGSize {
        if self == .none {
            return .zero
        }
        // Horizontal spacing includes 16pt spacing from content to icon and 16pt spacing from icon to trailing edge of cell
        let horizontalSpacing: CGFloat = Constants.horizontalSpacing * 2
        let iconWidth: CGFloat = icon?.size.width ?? 0
        return CGSize(width: horizontalSpacing + iconWidth, height: Constants.height)
    }
}

// MARK: - MSTableViewCell

/**
 `MSTableViewCell` is used to present a cell with one, two, or three lines of text with an optional custom view and an accessory.

 The `title` is displayed as the first line of text with the `subtitle` as the second line and the `footer` the third line.

 If a `subtitle` and `footer` are not provided the cell will be configured as a "small" size cell showing only the `title` line of text and a smaller custom view.

 If a `subtitle` is provided and a `footer` is not provided the cell will display two lines of text and will leave space for the `title` if it is not provided.

 If a `footer` is provided the cell will display three lines of text and will leave space for the `subtitle` and `title` if they are not provided.

 If a `customView` is not provided the `customView` will be hidden and the displayed text will take up the empty space left by the hidden `customView`.

 Specify `accessoryType` on setup to show either a disclosure indicator or a `detailButton`. The `detailButton` will display a button with an ellipsis icon which can be configured by passing in a closure to the cell's `onAccessoryTapped` property or by implementing UITableViewDelegate's `accessoryButtonTappedForRowWith` method.

 NOTE: This cell implements its own custom separator. Make sure to remove the UITableViewCell built-in separator by setting `separatorStyle = .none` on your table view. To remove the cell's custom separator set `bottomSeparatorType` to `.none`.
 */
open class MSTableViewCell: UITableViewCell {
    @objc(MSTableViewCellCustomViewSize)
    public enum CustomViewSize: Int {
        case `default`
        case zero
        case small
        case medium

        var size: CGSize {
            switch self {
            case .zero:
                return .zero
            case .small:
                return OfficeUIFabricFramework.usesFluentIcons ? CGSize(width: 24, height: 24) : CGSize(width: 25, height: 25)
            case .medium, .default:
                return CGSize(width: 40, height: 40)
            }
        }
        var trailingMargin: CGFloat {
            switch self {
            case .zero:
                return 0
            case .small:
                return 16
            case .medium, .default:
                return 12
            }
        }

        fileprivate func validateLayoutTypeForHeightCalculation(_ layoutType: inout LayoutType) {
            if self == .medium && layoutType == .oneLine {
                layoutType = .twoLines
            }
        }
    }

    @objc(MSTableViewCellSeparatorType)
    public enum SeparatorType: Int {
        case none
        case inset
        case full
    }

    fileprivate enum LayoutType {
        case oneLine
        case twoLines
        case threeLines

        var customViewSize: CustomViewSize { return self == .oneLine ? .small : .medium }

        var subtitleTextStyle: MSTextStyle {
            switch self {
            case .oneLine, .twoLines:
                return TextStyles.subtitleTwoLines
            case .threeLines:
                return TextStyles.subtitleThreeLines
            }
        }

        var labelVerticalMargin: CGFloat {
            switch self {
            case .oneLine, .threeLines:
                return labelVerticalMarginForOneAndThreeLines
            case .twoLines:
                return labelVerticalMarginForTwoLines
            }
        }
    }

    struct TextStyles {
        static let title: MSTextStyle = .body
        static let subtitleTwoLines: MSTextStyle = .footnote
        static let subtitleThreeLines: MSTextStyle = .subhead
        static let footer: MSTextStyle = .footnote
    }

    private struct Constants {
        static let horizontalSpacing: CGFloat = 16

        static let paddingLeading: CGFloat = horizontalSpacing
        static let paddingTrailing: CGFloat = horizontalSpacing

        static let labelAccessoryViewMarginLeading: CGFloat = 8
        static let labelAccessoryViewMarginTrailing: CGFloat = 8

        static let customAccessoryViewMarginLeading: CGFloat = 8

        static let labelVerticalMarginForOneAndThreeLines: CGFloat = 11
        static let labelVerticalMarginForTwoLines: CGFloat = 12
        static let labelVerticalSpacing: CGFloat = 0

        static let minHeight: CGFloat = 44

        static let selectionImageMarginTrailing: CGFloat = horizontalSpacing
        static let selectionImageOff = UIImage.staticImageNamed("selection-off")?.withRenderingMode(.alwaysTemplate)
        static let selectionImageOn = UIImage.staticImageNamed("selection-on")?.withRenderingMode(.alwaysTemplate)
        static let selectionImageSize = CGSize(width: 24, height: 24)
        static let selectionModeAnimationDuration: TimeInterval = 0.2

        static let enabledAlpha: CGFloat = 1
        static let disabledAlpha: CGFloat = 0.35
    }

    /**
     The height for the cell based on the text provided. Useful when `numberOfLines` of `title`, `subtitle`, `footer` is 1.

     `smallHeight` - Height for the cell when only the `title` is provided in a single line of text.
     `mediumHeight` - Height for the cell when only the `title` and `subtitle` are provided in 2 lines of text.
     `largeHeight` - Height for the cell when the `title`, `subtitle`, and `footer` are provided in 3 lines of text.
     */
    @objc public static var smallHeight: CGFloat { return height(title: "", customViewSize: .small) }
    @objc public static var mediumHeight: CGFloat { return height(title: "", subtitle: " ") }
    @objc public static var largeHeight: CGFloat { return height(title: "", subtitle: " ", footer: " ") }

    @objc public static var identifier: String { return String(describing: self) }

    /// A constant representing the number of lines for a label in which no change will be made when the `preferredContentSizeCategory` returns a size greater than `.large`.
    @objc public static let defaultNumberOfLinesForLargerDynamicType: Int = -1

    /// The vertical margins for cells with one or three lines of text
    class var labelVerticalMarginForOneAndThreeLines: CGFloat { return Constants.labelVerticalMarginForOneAndThreeLines }
    /// The vertical margins for cells with two lines of text
    class var labelVerticalMarginForTwoLines: CGFloat { return Constants.labelVerticalMarginForTwoLines }

    private static var separatorLeadingInsetForSmallCustomView: CGFloat {
        return Constants.paddingLeading + CustomViewSize.small.size.width + CustomViewSize.small.trailingMargin
    }
    private static var separatorLeadingInsetForMediumCustomView: CGFloat {
        return Constants.paddingLeading + CustomViewSize.medium.size.width + CustomViewSize.medium.trailingMargin
    }
    private static var separatorLeadingInsetForNoCustomView: CGFloat {
        return Constants.paddingLeading
    }

    /// The height of the cell based on the height of its content.
    ///
    /// - Parameters:
    ///   - title: The title string
    ///   - subtitle: The subtitle string
    ///   - footer: The footer string
    ///   - titleLeadingAccessoryView: The accessory view on the leading edge of the title
    ///   - titleTrailingAccessoryView: The accessory view on the trailing edge of the title
    ///   - subtitleLeadingAccessoryView: The accessory view on the leading edge of the subtitle
    ///   - subtitleTrailingAccessoryView: The accessory view on the trailing edge of the subtitle
    ///   - footerLeadingAccessoryView: The accessory view on the leading edge of the footer
    ///   - footerTrailingAccessoryView: The accessory view on the trailing edge of the footer
    ///   - customViewSize: The custom view size for the cell based on `MSTableViewCell.CustomViewSize`
    ///   - customAccessoryView: The custom accessory view that appears near the trailing edge of the cell
    ///   - accessoryType: The `MSTableViewCellAccessoryType` that the cell should display
    ///   - titleNumberOfLines: The number of lines that the title should display
    ///   - subtitleNumberOfLines: The number of lines that the subtitle should display
    ///   - footerNumberOfLines: The number of lines that the footer should display
    ///   - customAccessoryViewExtendsToEdge: Boolean defining whether custom accessory view is extended to the trailing edge of the cell or not (ignored when accessory type is not `.none`)
    ///   - containerWidth: The width of the cell's super view (e.g. the table view's width)
    ///   - isInSelectionMode: Boolean describing if the cell is in multi-selection mode which shows/hides a checkmark image on the leading edge
    /// - Returns: a value representing the calculated height of the cell
    @objc public class func height(title: String, subtitle: String = "", footer: String = "", titleLeadingAccessoryView: UIView? = nil, titleTrailingAccessoryView: UIView? = nil, subtitleLeadingAccessoryView: UIView? = nil, subtitleTrailingAccessoryView: UIView? = nil, footerLeadingAccessoryView: UIView? = nil, footerTrailingAccessoryView: UIView? = nil, customViewSize: CustomViewSize = .default, customAccessoryView: UIView? = nil, accessoryType: MSTableViewCellAccessoryType = .none, titleNumberOfLines: Int = 1, subtitleNumberOfLines: Int = 1, footerNumberOfLines: Int = 1, customAccessoryViewExtendsToEdge: Bool = false, containerWidth: CGFloat = .greatestFiniteMagnitude, isInSelectionMode: Bool = false) -> CGFloat {
        var layoutType = self.layoutType(subtitle: subtitle, footer: footer, subtitleLeadingAccessoryView: subtitleLeadingAccessoryView, subtitleTrailingAccessoryView: subtitleTrailingAccessoryView, footerLeadingAccessoryView: footerLeadingAccessoryView, footerTrailingAccessoryView: footerTrailingAccessoryView)
        customViewSize.validateLayoutTypeForHeightCalculation(&layoutType)
        let customViewSize = self.customViewSize(from: customViewSize, layoutType: layoutType)

        let textAreaLeadingOffset = self.textAreaLeadingOffset(customViewSize: customViewSize, isInSelectionMode: isInSelectionMode)
        let textAreaTrailingOffset = self.textAreaTrailingOffset(customAccessoryView: customAccessoryView, customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge, accessoryType: accessoryType)
        let textAreaWidth = containerWidth - (textAreaLeadingOffset + textAreaTrailingOffset)

        var textAreaHeight = labelSize(text: title, font: TextStyles.title.font, numberOfLines: titleNumberOfLines, textAreaWidth: textAreaWidth, leadingAccessoryView: titleLeadingAccessoryView, trailingAccessoryView: titleTrailingAccessoryView).height
        if layoutType == .twoLines || layoutType == .threeLines {
            textAreaHeight += labelSize(text: subtitle, font: layoutType.subtitleTextStyle.font, numberOfLines: subtitleNumberOfLines, textAreaWidth: textAreaWidth, leadingAccessoryView: subtitleLeadingAccessoryView, trailingAccessoryView: subtitleTrailingAccessoryView).height
            textAreaHeight += Constants.labelVerticalSpacing

            if layoutType == .threeLines {
                textAreaHeight += labelSize(text: footer, font: TextStyles.footer.font, numberOfLines: footerNumberOfLines, textAreaWidth: textAreaWidth, leadingAccessoryView: footerLeadingAccessoryView, trailingAccessoryView: footerTrailingAccessoryView).height
                textAreaHeight += Constants.labelVerticalSpacing
            }
        }

        let labelVerticalMargin = layoutType == .twoLines ? labelVerticalMarginForTwoLines : labelVerticalMarginForOneAndThreeLines

        return max(labelVerticalMargin * 2 + textAreaHeight, Constants.minHeight)
    }

    /// The preferred width of the cell based on the width of its content.
    ///
    /// - Parameters:
    ///   - title: The title string
    ///   - subtitle: The subtitle string
    ///   - footer: The footer string
    ///   - titleLeadingAccessoryView: The accessory view on the leading edge of the title
    ///   - titleTrailingAccessoryView: The accessory view on the trailing edge of the title
    ///   - subtitleLeadingAccessoryView: The accessory view on the leading edge of the subtitle
    ///   - subtitleTrailingAccessoryView: The accessory view on the trailing edge of the subtitle
    ///   - footerLeadingAccessoryView: The accessory view on the leading edge of the footer
    ///   - footerTrailingAccessoryView: The accessory view on the trailing edge of the footer
    ///   - customViewSize: The custom view size for the cell based on `MSTableViewCell.CustomViewSize`
    ///   - customAccessoryView: The custom accessory view that appears near the trailing edge of the cell
    ///   - accessoryType: The `MSTableViewCellAccessoryType` that the cell should display
    ///   - customAccessoryViewExtendsToEdge: Boolean defining whether custom accessory view is extended to the trailing edge of the cell or not (ignored when accessory type is not `.none`)
    ///   - isInSelectionMode: Boolean describing if the cell is in multi-selection mode which shows/hides a checkmark image on the leading edge
    /// - Returns: a value representing the preferred width of the cell
    @objc public class func preferredWidth(title: String, subtitle: String = "", footer: String = "", titleLeadingAccessoryView: UIView? = nil, titleTrailingAccessoryView: UIView? = nil, subtitleLeadingAccessoryView: UIView? = nil, subtitleTrailingAccessoryView: UIView? = nil, footerLeadingAccessoryView: UIView? = nil, footerTrailingAccessoryView: UIView? = nil, customViewSize: CustomViewSize = .default, customAccessoryView: UIView? = nil, accessoryType: MSTableViewCellAccessoryType = .none, customAccessoryViewExtendsToEdge: Bool = false, isInSelectionMode: Bool = false) -> CGFloat {
        let layoutType = self.layoutType(subtitle: subtitle, footer: footer, subtitleLeadingAccessoryView: subtitleLeadingAccessoryView, subtitleTrailingAccessoryView: subtitleTrailingAccessoryView, footerLeadingAccessoryView: footerLeadingAccessoryView, footerTrailingAccessoryView: footerTrailingAccessoryView)
        let customViewSize = self.customViewSize(from: customViewSize, layoutType: layoutType)

        var textAreaWidth = labelPreferredWidth(text: title, font: TextStyles.title.font, leadingAccessoryView: titleLeadingAccessoryView, trailingAccessoryView: titleTrailingAccessoryView)
        if layoutType == .twoLines || layoutType == .threeLines {
            let subtitleWidth = labelPreferredWidth(text: subtitle, font: layoutType.subtitleTextStyle.font, leadingAccessoryView: subtitleLeadingAccessoryView, trailingAccessoryView: subtitleTrailingAccessoryView)
            textAreaWidth = max(textAreaWidth, subtitleWidth)

            if layoutType == .threeLines {
                let footerWidth = labelPreferredWidth(text: footer, font: TextStyles.footer.font, leadingAccessoryView: footerLeadingAccessoryView, trailingAccessoryView: footerTrailingAccessoryView)
                textAreaWidth = max(textAreaWidth, footerWidth)
            }
        }

        return textAreaLeadingOffset(customViewSize: customViewSize, isInSelectionMode: isInSelectionMode) +
            textAreaWidth +
            textAreaTrailingOffset(customAccessoryView: customAccessoryView, customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge, accessoryType: accessoryType)
    }

    private static func labelSize(text: String, font: UIFont, numberOfLines: Int, textAreaWidth: CGFloat, leadingAccessoryView: UIView?, trailingAccessoryView: UIView?) -> CGSize {
        let leadingAccessoryViewWidth = labelAccessoryViewSize(for: leadingAccessoryView).width
        let leadingAccessoryAreaWidth = labelLeadingAccessoryAreaWidth(viewWidth: leadingAccessoryViewWidth)

        let trailingAccessoryViewWidth = labelAccessoryViewSize(for: trailingAccessoryView).width
        let trailingAccessoryAreaWidth = labelTrailingAccessoryAreaWidth(viewWidth: trailingAccessoryViewWidth, text: text)

        let availableWidth = textAreaWidth - (leadingAccessoryAreaWidth + trailingAccessoryAreaWidth)
        return text.preferredSize(for: font, width: availableWidth, numberOfLines: numberOfLines)
    }

    private static func labelPreferredWidth(text: String, font: UIFont, leadingAccessoryView: UIView?, trailingAccessoryView: UIView?) -> CGFloat {
        var labelWidth = text.preferredSize(for: font).width
        labelWidth += labelLeadingAccessoryAreaWidth(viewWidth: leadingAccessoryView?.width ?? 0) + labelTrailingAccessoryAreaWidth(viewWidth: trailingAccessoryView?.width ?? 0, text: text)
        return labelWidth
    }

    private static func layoutType(subtitle: String, footer: String, subtitleLeadingAccessoryView: UIView?, subtitleTrailingAccessoryView: UIView?, footerLeadingAccessoryView: UIView?, footerTrailingAccessoryView: UIView?) -> LayoutType {
        if footer == "" && footerLeadingAccessoryView == nil && footerTrailingAccessoryView == nil {
            if subtitle == "" && subtitleLeadingAccessoryView == nil && subtitleTrailingAccessoryView == nil {
                return .oneLine
            }
            return .twoLines
        } else {
            return .threeLines
        }
    }

    private static func selectionModeAreaWidth(isInSelectionMode: Bool) -> CGFloat {
        return isInSelectionMode ? Constants.selectionImageSize.width + Constants.selectionImageMarginTrailing : 0
    }

    private static func customViewSize(from size: CustomViewSize, layoutType: LayoutType) -> CustomViewSize {
        return size == .default ? layoutType.customViewSize : size
    }

    private static func customViewLeadingOffset(isInSelectionMode: Bool) -> CGFloat {
        return Constants.paddingLeading + selectionModeAreaWidth(isInSelectionMode: isInSelectionMode)
    }

    private static func textAreaLeadingOffset(customViewSize: CustomViewSize, isInSelectionMode: Bool) -> CGFloat {
        var textAreaLeadingOffset = customViewLeadingOffset(isInSelectionMode: isInSelectionMode)
        if customViewSize != .zero {
            textAreaLeadingOffset += customViewSize.size.width + customViewSize.trailingMargin
        }
        return textAreaLeadingOffset
    }

    private static func textAreaTrailingOffset(customAccessoryView: UIView?, customAccessoryViewExtendsToEdge: Bool, accessoryType: MSTableViewCellAccessoryType) -> CGFloat {
        let customAccessoryViewAreaWidth: CGFloat
        if let customAccessoryView = customAccessoryView {
            customAccessoryViewAreaWidth = customAccessoryView.width + Constants.customAccessoryViewMarginLeading
        } else {
            customAccessoryViewAreaWidth = 0
        }
        return customAccessoryViewAreaWidth + MSTableViewCell.customAccessoryViewTrailingOffset(customAccessoryView: customAccessoryView, customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge, accessoryType: accessoryType)
    }

    private static func customAccessoryViewTrailingOffset(customAccessoryView: UIView?, customAccessoryViewExtendsToEdge: Bool, accessoryType: MSTableViewCellAccessoryType) -> CGFloat {
         if accessoryType != .none {
            return accessoryType.size.width
        }
        if customAccessoryView != nil && customAccessoryViewExtendsToEdge {
            return 0
        }
        return Constants.paddingTrailing
    }

    private static func labelTrailingAccessoryMarginLeading(text: String) -> CGFloat {
        return text == "" ? 0 : Constants.labelAccessoryViewMarginLeading
    }

    private static func labelLeadingAccessoryAreaWidth(viewWidth: CGFloat) -> CGFloat {
        return viewWidth != 0 ? viewWidth + Constants.labelAccessoryViewMarginTrailing : 0
    }

    private static func labelTrailingAccessoryAreaWidth(viewWidth: CGFloat, text: String) -> CGFloat {
        return viewWidth != 0 ? labelTrailingAccessoryMarginLeading(text: text) + viewWidth : 0
    }

    private static func labelAccessoryViewSize(for accessoryView: UIView?) -> CGSize {
        return accessoryView?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize) ?? .zero
    }

    /// Text that appears as the first line of text
    @objc public var title: String { return titleLabel.text ?? "" }
    /// Text that appears as the second line of text
    @objc public var subtitle: String { return subtitleLabel.text ?? "" }
    /// Text that appears as the third line of text
    @objc public var footer: String { return footerLabel.text ?? "" }

    /// The maximum number of lines to be shown for `title`
    @objc open var titleNumberOfLines: Int {
        get {
            if titleNumberOfLinesForLargerDynamicType != MSTableViewCell.defaultNumberOfLinesForLargerDynamicType && preferredContentSizeIsLargerThanDefault {
                return titleNumberOfLinesForLargerDynamicType
            }
            return _titleNumberOfLines
        }
        set {
            _titleNumberOfLines = newValue
            updateTitleNumberOfLines()
        }
    }
    private var _titleNumberOfLines: Int = 1

    /// The maximum number of lines to be shown for `subtitle`
    @objc open var subtitleNumberOfLines: Int {
        get {
            if subtitleNumberOfLinesForLargerDynamicType != MSTableViewCell.defaultNumberOfLinesForLargerDynamicType && preferredContentSizeIsLargerThanDefault {
                return subtitleNumberOfLinesForLargerDynamicType
            }
            return _subtitleNumberOfLines
        }
        set {
            _subtitleNumberOfLines = newValue
            updateSubtitleNumberOfLines()
        }
    }
    private var _subtitleNumberOfLines: Int = 1

    /// The maximum number of lines to be shown for `footer`
    @objc open var footerNumberOfLines: Int {
        get {
            if footerNumberOfLinesForLargerDynamicType != MSTableViewCell.defaultNumberOfLinesForLargerDynamicType && preferredContentSizeIsLargerThanDefault {
                return footerNumberOfLinesForLargerDynamicType
            }
            return _footerNumberOfLines
        }
        set {
            _footerNumberOfLines = newValue
            updateFooterNumberOfLines()
        }
    }
    private var _footerNumberOfLines: Int = 1

    /// The number of lines to show for the `title` if `preferredContentSizeCategory` is set to a size greater than `.large`. The default value indicates that no change will be made to the `title` and `titleNumberOfLines` will be used for all content sizes.
    @objc open var titleNumberOfLinesForLargerDynamicType: Int = defaultNumberOfLinesForLargerDynamicType {
        didSet {
            updateTitleNumberOfLines()
        }
    }
    /// The number of lines to show for the `subtitle` if `preferredContentSizeCategory` is set to a size greater than `.large`. The default value indicates that no change will be made to the `subtitle` and `subtitleNumberOfLines` will be used for all content sizes.
    @objc open var subtitleNumberOfLinesForLargerDynamicType: Int = defaultNumberOfLinesForLargerDynamicType {
        didSet {
            updateSubtitleNumberOfLines()
        }
    }
    /// The number of lines to show for the `footer` if `preferredContentSizeCategory` is set to a size greater than `.large`. The default value indicates that no change will be made to the `footer` and `footerNumberOfLines` will be used for all content sizes.
    @objc open var footerNumberOfLinesForLargerDynamicType: Int = defaultNumberOfLinesForLargerDynamicType {
        didSet {
            updateFooterNumberOfLines()
        }
    }

    /// Updates the lineBreakMode of the `title`
    @objc open var titleLineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet {
            titleLabel.lineBreakMode = titleLineBreakMode
        }
    }
    /// Updates the lineBreakMode of the `subtitle`
    @objc open var subtitleLineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet {
            subtitleLabel.lineBreakMode = subtitleLineBreakMode
        }
    }
    /// Updates the lineBreakMode of the `footer`
    @objc open var footerLineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet {
            footerLabel.lineBreakMode = footerLineBreakMode
        }
    }

    /// The accessory view on the leading edge of the title
    @objc open var titleLeadingAccessoryView: UIView? {
        didSet {
            updateLabelAccessoryView(oldValue: oldValue, newValue: titleLeadingAccessoryView, size: &titleLeadingAccessoryViewSize)
        }
    }

    /// The accessory view on the trailing edge of the title
    @objc open var titleTrailingAccessoryView: UIView? {
        didSet {
            updateLabelAccessoryView(oldValue: oldValue, newValue: titleTrailingAccessoryView, size: &titleTrailingAccessoryViewSize)
        }
    }

    /// The accessory view on the leading edge of the subtitle
    @objc open var subtitleLeadingAccessoryView: UIView? {
        didSet {
            updateLabelAccessoryView(oldValue: oldValue, newValue: subtitleLeadingAccessoryView, size: &subtitleLeadingAccessoryViewSize)
        }
    }

    /// The accessory view on the trailing edge of the subtitle
    @objc open var subtitleTrailingAccessoryView: UIView? {
        didSet {
            updateLabelAccessoryView(oldValue: oldValue, newValue: subtitleTrailingAccessoryView, size: &subtitleTrailingAccessoryViewSize)
        }
    }

    /// The accessory view on the leading edge of the footer
    @objc open var footerLeadingAccessoryView: UIView? {
        didSet {
            updateLabelAccessoryView(oldValue: oldValue, newValue: footerLeadingAccessoryView, size: &footerLeadingAccessoryViewSize)
        }
    }

    /// The accessory view on the trailing edge of the footer
    @objc open var footerTrailingAccessoryView: UIView? {
        didSet {
            updateLabelAccessoryView(oldValue: oldValue, newValue: footerTrailingAccessoryView, size: &footerTrailingAccessoryViewSize)
        }
    }

    /// Override to set a specific `CustomViewSize` on the `customView`
    @objc open var customViewSize: CustomViewSize {
        get {
            if customView == nil {
                return .zero
            }
            return _customViewSize == .default ? layoutType.customViewSize : _customViewSize
        }
        set {
            if _customViewSize == newValue {
                return
            }
            _customViewSize = newValue
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    private var _customViewSize: CustomViewSize = .default

    @objc open private(set) var customAccessoryView: UIView? = nil {
        didSet {
            oldValue?.removeFromSuperview()
            if let customAccessoryView = customAccessoryView {
                contentView.addSubview(customAccessoryView)
            }
        }
    }

    /// Extends custom accessory view to the trailing edge of the cell. Ignored when accessory type is not `.none` since in this case the built-in accessory is placed at the edge of the cell preventing custom accessory view from extending.
    @objc open var customAccessoryViewExtendsToEdge: Bool = false {
        didSet {
            if customAccessoryViewExtendsToEdge == oldValue {
                return
            }
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }

    /// Style describing whether or not the cell's top separator should be visible and how wide it should extend
    @objc open var topSeparatorType: SeparatorType = .none {
        didSet {
            if topSeparatorType != oldValue {
                updateSeparator(topSeparator, with: topSeparatorType)
            }
        }
    }
    /// Style describing whether or not the cell's bottom separator should be visible and how wide it should extend
    @objc open var bottomSeparatorType: SeparatorType = .inset {
        didSet {
            if bottomSeparatorType != oldValue {
                updateSeparator(bottomSeparator, with: bottomSeparatorType)
            }
        }
    }

    /// When `isEnabled` is `false`, disables ability for a user to interact with a cell and dims cell's contents
    @objc open var isEnabled: Bool = true {
        didSet {
            contentView.alpha = isEnabled ? Constants.enabledAlpha : Constants.disabledAlpha
            isUserInteractionEnabled = isEnabled
            initAccessoryTypeView()
            updateAccessibility()
        }
    }

    /// Enables / disables multi-selection mode by showing / hiding a checkmark selection indicator on the leading edge
    @objc open var isInSelectionMode: Bool {
        get { return _isInSelectionMode }
        set { setIsInSelectionMode(newValue, animated: false) }
    }
    private var _isInSelectionMode: Bool = false

    /// `onAccessoryTapped` is called when `detailButton` accessory view is tapped
    @objc open var onAccessoryTapped: (() -> Void)?

    open override var intrinsicContentSize: CGSize {
        return CGSize(
            width: type(of: self).preferredWidth(
                title: titleLabel.text ?? "",
                subtitle: subtitleLabel.text ?? "",
                footer: footerLabel.text ?? "",
                titleLeadingAccessoryView: titleLeadingAccessoryView,
                titleTrailingAccessoryView: titleTrailingAccessoryView,
                subtitleLeadingAccessoryView: subtitleLeadingAccessoryView,
                subtitleTrailingAccessoryView: subtitleTrailingAccessoryView,
                footerLeadingAccessoryView: footerLeadingAccessoryView,
                footerTrailingAccessoryView: footerTrailingAccessoryView,
                customViewSize: customViewSize,
                customAccessoryView: customAccessoryView,
                accessoryType: _accessoryType,
                customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge,
                isInSelectionMode: isInSelectionMode
            ),
            height: type(of: self).height(
                title: titleLabel.text ?? "",
                subtitle: subtitleLabel.text ?? "",
                footer: footerLabel.text ?? "",
                titleLeadingAccessoryView: titleLeadingAccessoryView,
                titleTrailingAccessoryView: titleTrailingAccessoryView,
                subtitleLeadingAccessoryView: subtitleLeadingAccessoryView,
                subtitleTrailingAccessoryView: subtitleTrailingAccessoryView,
                footerLeadingAccessoryView: footerLeadingAccessoryView,
                footerTrailingAccessoryView: footerTrailingAccessoryView,
                customViewSize: customViewSize,
                customAccessoryView: customAccessoryView,
                accessoryType: _accessoryType,
                titleNumberOfLines: titleNumberOfLines,
                subtitleNumberOfLines: subtitleNumberOfLines,
                footerNumberOfLines: footerNumberOfLines,
                customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge,
                containerWidth: .infinity,
                isInSelectionMode: isInSelectionMode
            )
        )
    }

    open override var bounds: CGRect {
        didSet {
            if bounds.width != oldValue.width {
                invalidateIntrinsicContentSize()
            }
        }
    }
    open override var frame: CGRect {
        didSet {
            if frame.width != oldValue.width {
                invalidateIntrinsicContentSize()
            }
        }
    }

    open override var accessibilityHint: String? {
        get {
            if isInSelectionMode && isEnabled {
                return "Accessibility.MultiSelect.Hint".localized
            }
            return super.accessibilityHint
        }
        set {
            super.accessibilityHint = newValue
        }
    }

    // swiftlint:disable identifier_name
    var _accessoryType: MSTableViewCellAccessoryType = .none {
        didSet {
            if _accessoryType == oldValue {
                return
            }
            accessoryTypeView = _accessoryType == .none ? nil : MSTableViewCellAccessoryView(type: _accessoryType)
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    // swiftlint:enable identifier_name

    private var layoutType: LayoutType = .oneLine {
        didSet {
            subtitleLabel.isHidden = layoutType == .oneLine
            footerLabel.isHidden = layoutType != .threeLines

            subtitleLabel.style = layoutType.subtitleTextStyle

            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }

    private var preferredContentSizeIsLargerThanDefault: Bool {
        switch traitCollection.preferredContentSizeCategory {
        case .unspecified, .extraSmall, .small, .medium, .large:
            return false
        default:
            return true
        }
    }

    private var textAreaWidth: CGFloat {
        let textAreaLeadingOffset = MSTableViewCell.textAreaLeadingOffset(customViewSize: customViewSize, isInSelectionMode: isInSelectionMode)
        let textAreaTrailingOffset = MSTableViewCell.textAreaTrailingOffset(customAccessoryView: customAccessoryView, customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge, accessoryType: _accessoryType)
        return contentView.width - (textAreaLeadingOffset + textAreaTrailingOffset)
    }

    private(set) var customView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let customView = customView {
                contentView.addSubview(customView)
                customView.accessibilityElementsHidden = true
            }
        }
    }

    let titleLabel: MSLabel = {
        let label = MSLabel(style: TextStyles.title)
        label.textColor = MSColors.Table.Cell.title
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    let subtitleLabel: MSLabel = {
        let label = MSLabel(style: TextStyles.subtitleTwoLines)
        label.textColor = MSColors.Table.Cell.subtitle
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()

    let footerLabel: MSLabel = {
        let label = MSLabel(style: TextStyles.footer)
        label.textColor = MSColors.Table.Cell.footer
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()

    private func updateLabelAccessoryView(oldValue: UIView?, newValue: UIView?, size: inout CGSize) {
        if newValue == oldValue {
            return
        }
        oldValue?.removeFromSuperview()
        if let newValue = newValue {
            contentView.addSubview(newValue)
        }
        size = MSTableViewCell.labelAccessoryViewSize(for: newValue)
        updateLayoutType()
    }

    private var titleLeadingAccessoryViewSize: CGSize = .zero
    private var titleTrailingAccessoryViewSize: CGSize = .zero
    private var subtitleLeadingAccessoryViewSize: CGSize = .zero
    private var subtitleTrailingAccessoryViewSize: CGSize = .zero
    private var footerLeadingAccessoryViewSize: CGSize = .zero
    private var footerTrailingAccessoryViewSize: CGSize = .zero

    private var accessoryTypeView: MSTableViewCellAccessoryView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let accessoryTypeView = accessoryTypeView {
                contentView.addSubview(accessoryTypeView)
                initAccessoryTypeView()
            }
        }
    }

    private var selectionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        return imageView
    }()

    private let topSeparator = MSSeparator(style: .default, orientation: .horizontal)
    private let bottomSeparator = MSSeparator(style: .default, orientation: .horizontal)

    private var superTableView: UITableView? {
        return findSuperview(of: UITableView.self) as? UITableView
    }

    @objc public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        initialize()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    open func initialize() {
        textLabel?.text = ""

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(footerLabel)
        contentView.addSubview(selectionImageView)
        addSubview(topSeparator)
        addSubview(bottomSeparator)

        setupBackgroundColors()

        hideSystemSeparator()
        updateSeparator(topSeparator, with: topSeparatorType)
        updateSeparator(bottomSeparator, with: bottomSeparatorType)

        updateAccessibility()

        NotificationCenter.default.addObserver(self, selector: #selector(handleContentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    /// Sets up the cell with text, a custom view, a custom accessory view, and an accessory type
    ///
    /// - Parameters:
    ///   - title: Text that appears as the first line of text
    ///   - subtitle: Text that appears as the second line of text
    ///   - footer: Text that appears as the third line of text
    ///   - customView: The custom view that appears near the leading edge next to the text
    ///   - customAccessoryView: The view acting as an accessory view that appears on the trailing edge, next to the accessory type if provided
    ///   - accessoryType: The type of accessory that appears on the trailing edge: a disclosure indicator or a details button with an ellipsis icon
    @objc open func setup(title: String, subtitle: String = "", footer: String = "", customView: UIView? = nil, customAccessoryView: UIView? = nil, accessoryType: MSTableViewCellAccessoryType = .none) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        footerLabel.text = footer
        self.customView = customView
        self.customAccessoryView = customAccessoryView
        _accessoryType = accessoryType

        updateLayoutType()

        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    /// Allows to change the accessory type without doing a full `setup`.
    @objc open func changeAccessoryType(to accessoryType: MSTableViewCellAccessoryType) {
        _accessoryType = accessoryType
    }

    /// Sets the multi-selection state of the cell, optionally animating the transition between states.
    ///
    /// - Parameters:
    ///   - isInSelectionMode: true to set the cell as in selection mode, false to set it as not in selection mode. The default is false.
    ///   - animated: true to animate the transition in / out of selection mode, false to make the transition immediate.
    @objc open func setIsInSelectionMode(_ isInSelectionMode: Bool, animated: Bool) {
        if _isInSelectionMode == isInSelectionMode {
            return
        }

        _isInSelectionMode = isInSelectionMode

        if !isInSelectionMode {
            selectionImageView.isHidden = true
            isSelected = false
        }

        let completion = { (_: Bool) in
            if self.isInSelectionMode {
                self.updateSelectionImageView()
                self.selectionImageView.isHidden = false
            }
        }

        setNeedsLayout()
        invalidateIntrinsicContentSize()

        if animated {
            UIView.animate(withDuration: Constants.selectionModeAnimationDuration, delay: 0, options: [.layoutSubviews], animations: layoutIfNeeded, completion: completion)
        } else {
            completion(true)
        }

        initAccessoryTypeView()

        selectionStyle = isInSelectionMode ? .none : .default
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        layoutContentSubviews()
        contentView.flipSubviewsForRTL()

        layoutSeparator(topSeparator, with: topSeparatorType, at: 0)
        layoutSeparator(bottomSeparator, with: bottomSeparatorType, at: height - bottomSeparator.height)
    }

    open func layoutContentSubviews() {
        if isInSelectionMode {
            let selectionImageViewYOffset = UIScreen.main.roundToDevicePixels((contentView.height - Constants.selectionImageSize.height) / 2)
            selectionImageView.frame = CGRect(
                origin: CGPoint(x: Constants.paddingLeading, y: selectionImageViewYOffset),
                size: Constants.selectionImageSize
            )
        }

        if let customView = customView {
            let customViewYOffset = UIScreen.main.roundToDevicePixels((contentView.height - customViewSize.size.height) / 2)
            let customViewXOffset = MSTableViewCell.customViewLeadingOffset(isInSelectionMode: isInSelectionMode)
            customView.frame = CGRect(
                origin: CGPoint(x: customViewXOffset, y: customViewYOffset),
                size: customViewSize.size
            )
        }

        let titleText = titleLabel.text ?? ""
        let titleSize = titleText.preferredSize(for: titleLabel.font, width: textAreaWidth, numberOfLines: titleNumberOfLines)
        let titleLineHeight = titleLabel.font.deviceLineHeightWithLeading
        let titleCenteredTopMargin = UIScreen.main.roundToDevicePixels((contentView.height - titleLineHeight) / 2)
        let titleTopOffset = layoutType != .oneLine || titleSize.height > titleLineHeight ? layoutType.labelVerticalMargin : titleCenteredTopMargin
        layoutLabelViews(
            label: titleLabel,
            numberOfLines: titleNumberOfLines,
            topOffset: titleTopOffset,
            leadingAccessoryView: titleLeadingAccessoryView,
            leadingAccessoryViewSize: titleLeadingAccessoryViewSize,
            trailingAccessoryView: titleTrailingAccessoryView,
            trailingAccessoryViewSize: titleTrailingAccessoryViewSize
        )

        if layoutType == .twoLines || layoutType == .threeLines {
            layoutLabelViews(
                label: subtitleLabel,
                numberOfLines: subtitleNumberOfLines,
                topOffset: titleLabel.bottom + Constants.labelVerticalSpacing,
                leadingAccessoryView: subtitleLeadingAccessoryView,
                leadingAccessoryViewSize: subtitleLeadingAccessoryViewSize,
                trailingAccessoryView: subtitleTrailingAccessoryView,
                trailingAccessoryViewSize: subtitleTrailingAccessoryViewSize
            )

            if layoutType == .threeLines {
                layoutLabelViews(
                    label: footerLabel,
                    numberOfLines: footerNumberOfLines,
                    topOffset: subtitleLabel.bottom + Constants.labelVerticalSpacing,
                    leadingAccessoryView: footerLeadingAccessoryView,
                    leadingAccessoryViewSize: footerLeadingAccessoryViewSize,
                    trailingAccessoryView: footerTrailingAccessoryView,
                    trailingAccessoryViewSize: footerTrailingAccessoryViewSize
                )
            }
        }

        if let customAccessoryView = customAccessoryView {
            let textAreaTrailingOffset = MSTableViewCell.textAreaTrailingOffset(customAccessoryView: customAccessoryView, customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge, accessoryType: _accessoryType)
            let xOffset = contentView.width - textAreaTrailingOffset + Constants.customAccessoryViewMarginLeading
            let yOffset = UIScreen.main.roundToDevicePixels((contentView.height - customAccessoryView.height) / 2)
            customAccessoryView.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: customAccessoryView.frame.size)
        }

        if let accessoryTypeView = accessoryTypeView {
            let xOffset = contentView.width - MSTableViewCell.customAccessoryViewTrailingOffset(customAccessoryView: customAccessoryView, customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge, accessoryType: _accessoryType)
            let yOffset = UIScreen.main.roundToDevicePixels((contentView.height - _accessoryType.size.height) / 2)
            accessoryTypeView.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: _accessoryType.size)
        }
    }

    private func layoutLabelViews(label: UILabel, numberOfLines: Int, topOffset: CGFloat, leadingAccessoryView: UIView?, leadingAccessoryViewSize: CGSize, trailingAccessoryView: UIView?, trailingAccessoryViewSize: CGSize) {
        let textAreaLeadingOffset = MSTableViewCell.textAreaLeadingOffset(customViewSize: customViewSize, isInSelectionMode: isInSelectionMode)

        let text = label.text ?? ""
        let size = text.preferredSize(for: label.font, width: textAreaWidth, numberOfLines: numberOfLines)

        if let leadingAccessoryView = leadingAccessoryView {
            let yOffset = UIScreen.main.roundToDevicePixels(topOffset + (size.height - leadingAccessoryViewSize.height) / 2)
            leadingAccessoryView.frame = CGRect(
                x: textAreaLeadingOffset,
                y: yOffset,
                width: leadingAccessoryViewSize.width,
                height: leadingAccessoryViewSize.height
            )
        }

        let leadingAccessoryAreaWidth = MSTableViewCell.labelLeadingAccessoryAreaWidth(viewWidth: leadingAccessoryViewSize.width)
        let labelSize = MSTableViewCell.labelSize(text: text, font: label.font, numberOfLines: numberOfLines, textAreaWidth: textAreaWidth, leadingAccessoryView: leadingAccessoryView, trailingAccessoryView: trailingAccessoryView)
        label.frame = CGRect(
            x: textAreaLeadingOffset + leadingAccessoryAreaWidth,
            y: topOffset,
            width: labelSize.width,
            height: labelSize.height
        )

        if let trailingAccessoryView = trailingAccessoryView {
            let yOffset = UIScreen.main.roundToDevicePixels(topOffset + (labelSize.height - trailingAccessoryViewSize.height) / 2)
            let availableWidth = textAreaWidth - labelSize.width - leadingAccessoryAreaWidth
            let leadingMargin = MSTableViewCell.labelTrailingAccessoryMarginLeading(text: text)
            trailingAccessoryView.frame = CGRect(
                x: label.frame.maxX + leadingMargin,
                y: yOffset,
                width: availableWidth - leadingMargin,
                height: trailingAccessoryViewSize.height
            )
        }
    }

    private func layoutSeparator(_ separator: MSSeparator, with type: SeparatorType, at verticalOffset: CGFloat) {
        separator.frame = CGRect(
            x: separatorLeadingInset(for: type),
            y: verticalOffset,
            width: width - separatorLeadingInset(for: type),
            height: separator.height
        )
        separator.flipForRTL()
    }

    func separatorLeadingInset(for type: SeparatorType) -> CGFloat {
        guard type == .inset else {
            return 0
        }
        let baseOffset = safeAreaInsets.left + MSTableViewCell.selectionModeAreaWidth(isInSelectionMode: isInSelectionMode)
        switch customViewSize {
        case .zero:
            return baseOffset + MSTableViewCell.separatorLeadingInsetForNoCustomView
        case .small:
            return baseOffset + MSTableViewCell.separatorLeadingInsetForSmallCustomView
        case .medium, .default:
            return baseOffset + MSTableViewCell.separatorLeadingInsetForMediumCustomView
        }
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxWidth = size.width != 0 ? size.width : .infinity
        return CGSize(
            width: min(
                type(of: self).preferredWidth(
                    title: titleLabel.text ?? "",
                    subtitle: subtitleLabel.text ?? "",
                    footer: footerLabel.text ?? "",
                    titleLeadingAccessoryView: titleLeadingAccessoryView,
                    titleTrailingAccessoryView: titleTrailingAccessoryView,
                    subtitleLeadingAccessoryView: subtitleLeadingAccessoryView,
                    subtitleTrailingAccessoryView: subtitleTrailingAccessoryView,
                    footerLeadingAccessoryView: footerLeadingAccessoryView,
                    footerTrailingAccessoryView: footerTrailingAccessoryView,
                    customViewSize: customViewSize,
                    customAccessoryView: customAccessoryView,
                    accessoryType: _accessoryType,
                    customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge,
                    isInSelectionMode: isInSelectionMode
                ),
                maxWidth
            ),
            height: type(of: self).height(
                title: titleLabel.text ?? "",
                subtitle: subtitleLabel.text ?? "",
                footer: footerLabel.text ?? "",
                titleLeadingAccessoryView: titleLeadingAccessoryView,
                titleTrailingAccessoryView: titleTrailingAccessoryView,
                subtitleLeadingAccessoryView: subtitleLeadingAccessoryView,
                subtitleTrailingAccessoryView: subtitleTrailingAccessoryView,
                footerLeadingAccessoryView: footerLeadingAccessoryView,
                footerTrailingAccessoryView: footerTrailingAccessoryView,
                customViewSize: customViewSize,
                customAccessoryView: customAccessoryView,
                accessoryType: _accessoryType,
                titleNumberOfLines: titleNumberOfLines,
                subtitleNumberOfLines: subtitleNumberOfLines,
                footerNumberOfLines: footerNumberOfLines,
                customAccessoryViewExtendsToEdge: customAccessoryViewExtendsToEdge,
                containerWidth: maxWidth,
                isInSelectionMode: isInSelectionMode
            )
        )
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // If using cell within a superview other than UITableView override setSelected()
        if superTableView == nil && !isInSelectionMode {
            setSelected(true, animated: false)
        }
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let oldIsSelected = isSelected
        super.touchesCancelled(touches, with: event)
        // If using cell within a superview other than UITableView override setSelected()
        if superTableView == nil {
            if isInSelectionMode {
                // Cell unselects itself in super.touchesCancelled which is not what we want in multi-selection mode - restore selection back
                setSelected(oldIsSelected, animated: false)
            } else {
                setSelected(false, animated: true)
            }
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if superTableView == nil && _isInSelectionMode {
            setSelected(!isSelected, animated: true)
        }

        selectionDidChange()

        // If using cell within a superview other than UITableView override setSelected()
        if superTableView == nil && !isInSelectionMode {
            setSelected(false, animated: true)
        }
    }

    open func selectionDidChange() { }

    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateSelectionImageView()
    }

    private func updateLayoutType() {
        layoutType = MSTableViewCell.layoutType(
            subtitle: subtitleLabel.text ?? "",
            footer: footerLabel.text ?? "",
            subtitleLeadingAccessoryView: subtitleLeadingAccessoryView,
            subtitleTrailingAccessoryView: subtitleTrailingAccessoryView,
            footerLeadingAccessoryView: footerLeadingAccessoryView,
            footerTrailingAccessoryView: footerTrailingAccessoryView
        )
    }

    private func updateTitleNumberOfLines() {
        titleLabel.numberOfLines = titleNumberOfLines
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    private func updateSubtitleNumberOfLines() {
        subtitleLabel.numberOfLines = subtitleNumberOfLines
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    private func updateFooterNumberOfLines() {
        footerLabel.numberOfLines = footerNumberOfLines
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    @objc private func handleDetailButtonTapped() {
        onAccessoryTapped?()
        if let tableView = superTableView, let indexPath = tableView.indexPath(for: self) {
            tableView.delegate?.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
        }
    }

    private func initAccessoryTypeView() {
        guard let accessoryTypeView = accessoryTypeView else {
            return
        }

        if accessoryTypeView.type == .detailButton {
            accessoryTypeView.isUserInteractionEnabled = isEnabled && !isInSelectionMode
            accessoryTypeView.onTapped = handleDetailButtonTapped
        }
    }

    private func setupBackgroundColors() {
        backgroundColor = MSColors.Table.Cell.background

        let selectedStateBackgroundView = UIView()
        selectedStateBackgroundView.backgroundColor = MSColors.Table.Cell.backgroundSelected
        selectedBackgroundView = selectedStateBackgroundView
    }

    private func updateAccessibility() {
        if isEnabled {
            accessibilityTraits.remove(.notEnabled)
        } else {
            accessibilityTraits.insert(.notEnabled)
        }
    }

    private func updateSelectionImageView() {
        selectionImageView.image = isSelected ? Constants.selectionImageOn : Constants.selectionImageOff
        selectionImageView.tintColor = isSelected ? MSColors.Table.Cell.selectionIndicatorOn : MSColors.Table.Cell.selectionIndicatorOff
    }

    private func updateSeparator(_ separator: MSSeparator, with type: SeparatorType) {
        separator.isHidden = type == .none
        setNeedsLayout()
    }

    @objc private func handleContentSizeCategoryDidChange() {
        updateTitleNumberOfLines()
        updateSubtitleNumberOfLines()
        updateFooterNumberOfLines()

        titleLeadingAccessoryViewSize = MSTableViewCell.labelAccessoryViewSize(for: titleLeadingAccessoryView)
        titleTrailingAccessoryViewSize = MSTableViewCell.labelAccessoryViewSize(for: titleTrailingAccessoryView)
        subtitleLeadingAccessoryViewSize = MSTableViewCell.labelAccessoryViewSize(for: subtitleLeadingAccessoryView)
        subtitleTrailingAccessoryViewSize = MSTableViewCell.labelAccessoryViewSize(for: subtitleTrailingAccessoryView)
        footerLeadingAccessoryViewSize = MSTableViewCell.labelAccessoryViewSize(for: footerLeadingAccessoryView)
        footerTrailingAccessoryViewSize = MSTableViewCell.labelAccessoryViewSize(for: footerTrailingAccessoryView)

        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
}

// MARK: - MSTableViewCellAccessoryView

private class MSTableViewCellAccessoryView: UIView {
    override var accessibilityElementsHidden: Bool { get { return !isUserInteractionEnabled } set { } }
    override var intrinsicContentSize: CGSize { return type.size }

    let type: MSTableViewCellAccessoryType

    /// `onTapped` is called when `detailButton` is tapped
    var onTapped: (() -> Void)?

    init(type: MSTableViewCellAccessoryType) {
        self.type = type
        super.init(frame: .zero)

        switch type {
        case .none:
            break
        case .disclosureIndicator, .checkmark:
            addIconView(type: type)
        case .detailButton:
            let button = UIButton(type: .custom)
            button.setImage(type.icon, for: .normal)
            button.frame.size = type.size
            button.contentMode = .center
            button.tintColor = type.iconColor
            button.accessibilityLabel = "Accessibility.TableViewCell.MoreActions.Label".localized
            button.accessibilityHint = "Accessibility.TableViewCell.MoreActions.Hint".localized
            button.addTarget(self, action: #selector(handleOnAccessoryTapped), for: .touchUpInside)

            addSubview(button)
            button.fitIntoSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return type.size
    }

    private func addIconView(type: MSTableViewCellAccessoryType) {
        let iconView = UIImageView(image: type.icon)
        iconView.frame.size = type.size
        iconView.contentMode = .center
        iconView.tintColor = type.iconColor
        addSubview(iconView)
        iconView.fitIntoSuperview()
    }

    @objc private func handleOnAccessoryTapped() {
        onTapped?()
    }
}
