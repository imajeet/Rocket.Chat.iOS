//
//  NewPasswordTableViewController.swift
//  Rocket.Chat
//
//  Created by Filipe Alvarenga on 07/03/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import UIKit

class NewPasswordTableViewController: UITableViewController {

    @IBOutlet weak var newPassword: UITextField! {
        didSet {
            newPassword.placeholder = viewModel.passwordPlaceholder
        }
    }

    @IBOutlet weak var passwordConfirmation: UITextField! {
        didSet {
            passwordConfirmation.placeholder = viewModel.passwordConfirmationPlaceholder
        }
    }

    @IBOutlet weak var saveButton: UIBarButtonItem! {
        didSet {
            saveButton.title = viewModel.saveButtonTitle
        }
    }

    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.startAnimating()
        return activityIndicator
    }()

    let viewModel = NewPasswordViewModel()
    let api = API.current()
    var user: User!

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = viewModel.title
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        newPassword.becomeFirstResponder()
    }

    // MARK: Actions

    @IBAction func savePassword(sender: UIBarButtonItem!) {
        view.endEditing(true)

        guard let userId = user.identifier else { return }

        guard
            let newPassword = newPassword.text,
            let passwordConfirmation = passwordConfirmation.text,
            !newPassword.isEmpty,
            !passwordConfirmation.isEmpty
        else {
            Alert(key: "alert.password_empty_fields").present()
            return
        }

        guard newPassword == passwordConfirmation else {
            Alert(key: "alert.password_mismatch_error").present()
            return
        }

        DispatchQueue.main.async {
            self.navigationItem.hidesBackButton = true
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
        }

        let stopLoading = {
            DispatchQueue.main.async { [weak self] in
                self?.navigationItem.hidesBackButton = false
                self?.navigationItem.rightBarButtonItem = sender
            }
        }

        let updatePasswordRequest = UpdateUserRequest(userId: userId, password: newPassword)
        api?.fetch(updatePasswordRequest, succeeded: { [weak self] result in
            stopLoading()

            if let errorMessage = result.errorMessage {
                Alert(key: "alert.update_password_error").withMessage(errorMessage).present()
            } else {
                DispatchQueue.main.async {
                    self?.alert(title: "", message: "Password changed (MBProgressHUD placeholder)", handler: { _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                }
            }
        }, errored: { _ in
            stopLoading()
            Alert(key: "alert.update_password_error").present()
        })
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return viewModel.passwordSectionTitle
        default:
            return ""
        }
    }
}