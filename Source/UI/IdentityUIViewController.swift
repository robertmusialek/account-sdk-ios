//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

private class IdentityUIBarButtonItem: UIBarButtonItem {
    private var actionHandler: (() -> Void)?

    convenience init(title: String?, style: UIBarButtonItemStyle, action: (() -> Void)?) {
        self.init(title: title, style: style, target: nil, action: nil)
        self.target = self
        self.action = #selector(self.barButtonItemPressed(sender:))
        self.actionHandler = action
    }

    @objc func barButtonItemPressed(sender _: UIBarButtonItem) {
        self.actionHandler?()
    }
}

struct NavigationSettings {
    typealias Action = () -> Void

    let cancel: Action?
    let navigateBack: Action?

    init(cancel: Action? = nil, back: Action? = nil) {
        self.cancel = cancel
        self.navigateBack = back
    }
}

class IdentityUIViewController: UIViewController {
    class var nibName: String? {
        return String(describing: self)
    }

    let configuration: IdentityUIConfiguration
    let navigationSettings: NavigationSettings

    var theme: IdentityUITheme {
        return self.configuration.theme
    }

    @IBOutlet var scrollView: UIScrollView!
    var viewToEnsureVisibilityOfAfterKeyboardAppearance: UIView?

    private var leftAlignNavigationTitle = false

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, trackerViewID: TrackingEvent.View) {
        self.configuration = configuration
        self.trackerViewID = trackerViewID
        self.navigationSettings = navigationSettings
        let typeSelf = type(of: self)
        super.init(nibName: typeSelf.nibName, bundle: Bundle(for: typeSelf))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var navigationTitle: String {
        return ""
    }

    let trackerViewID: TrackingEvent.View

    private func applyThemeToView(_ view: UIView) {
        (view as? Themeable)?.applyTheme(theme: self.theme)
        for subview in view.subviews {
            self.applyThemeToView(subview)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.applyThemeToView(self.view)

        var leftBarButtonItems: [UIBarButtonItem] = []

        if let backAction = self.navigationSettings.navigateBack {
            let backBarButtonItem = IdentityUIBarButtonItem(
                title: nil,
                style: .plain,
                action: backAction
            )
            backBarButtonItem.image = self.theme.icons.navigateBack
            backBarButtonItem.tintColor = self.theme.colors.iconTint

            leftBarButtonItems.append(backBarButtonItem)
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }

        if self.leftAlignNavigationTitle {
            let titleLabel = UILabel()
            titleLabel.text = self.navigationTitle
            titleLabel.font = self.configuration.theme.fonts.title
            titleLabel.sizeToFit()
            let titleBarButtonItem = UIBarButtonItem(customView: titleLabel)
            leftBarButtonItems.append(titleBarButtonItem)
            self.title = nil
        } else {
            self.title = self.navigationTitle
        }
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItems = leftBarButtonItems

        if let cancelAction = self.navigationSettings.cancel {
            let barButtonItem = IdentityUIBarButtonItem(
                title: nil,
                style: .plain,
                action: cancelAction
            )
            barButtonItem.image = self.theme.icons.cancelNavigation
            barButtonItem.tintColor = self.theme.colors.iconTint
            self.navigationItem.rightBarButtonItem = barButtonItem
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.configuration.tracker?.view(self.trackerViewID)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardDidShow),
            name: NSNotification.Name.UIKeyboardDidShow,
            object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }

    @objc private func dismissKeyboard() {
        self.view.endEditing(false)
    }

    @objc private func keyboardDidShow(notification: NSNotification) {
        guard let view = self.viewToEnsureVisibilityOfAfterKeyboardAppearance else {
            return
        }

        guard let scrollView = scrollView else {
            assertionFailure(
                "Attempt to set viewToEnsureVisibilityOfAfterKeyboardAppearance without a scroll view: "
                    + "did you forget to set the scrollView outlet?"
            )
            return
        }

        guard let endFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let keyboardMinY = self.view.convert(endFrame, from: nil).minY
        let bottomPadding: CGFloat = 8
        let viewMaxY = self.view.convert(view.frame, from: view.superview).maxY + bottomPadding
        let delta = keyboardMinY - viewMaxY

        if delta > 0 {
            return
        }

        var contentOffset = scrollView.contentOffset
        contentOffset.y -= delta
        scrollView.setContentOffset(contentOffset, animated: true)
    }

    func startLoading() {
        self.view.isUserInteractionEnabled = false
    }

    func endLoading() {
        self.view.isUserInteractionEnabled = true
    }

    @discardableResult func showInlineError(_: ClientError) -> Bool {
        return false
    }
}
