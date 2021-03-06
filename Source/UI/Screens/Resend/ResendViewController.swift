//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class ResendViewController: IdentityUIViewController {
    enum Action {
        case changeIdentifier
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var header: Heading! {
        didSet {
            self.header.text = self.viewModel.header
        }
    }
    @IBOutlet var code: NormalLabel! {
        didSet {
            self.code.font = self.theme.fonts.normal
            self.code.text = self.viewModel.subtext
        }
    }
    @IBOutlet var number: NormalLabel! {
        didSet {
            self.number.font = self.theme.fonts.normal
            self.number.text = self.viewModel.identifier.normalizedString
        }
    }
    @IBOutlet var edit: UIButton! {
        didSet {
            let string = NSAttributedString(string: self.viewModel.editText, attributes: self.theme.textAttributes.textButton)
            self.edit.setAttributedTitle(string, for: .normal)
        }
    }
    @IBOutlet var ok: PrimaryButton! {
        didSet {
            self.ok.setTitle(self.viewModel.proceed, for: .normal)
        }
    }
    @IBOutlet var stackBackground: UIView!

    let viewModel: ResendViewModel

    init(configuration: IdentityUIConfiguration, viewModel: ResendViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: NavigationSettings(), trackerViewID: .passwordlessResend)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.stackBackground.layer.cornerRadius = self.theme.geometry.cornerRadius
    }

    @IBAction func didClickContinue(_: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func didClickEdit(_: Any) {
        self.dismiss(animated: true)
        self.didRequestAction?(.changeIdentifier)
    }
}
