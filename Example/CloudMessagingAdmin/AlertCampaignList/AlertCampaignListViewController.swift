//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Dash Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CloudInAppMessaging
import CloudKit
import UIKit

final class AlertCampaignListViewController: UITableViewController {
    private let model: AlertCampaignListModel

    init(service: AlertCampaignCloudKitService) {
        model = AlertCampaignListModel(service: service)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }

    @available(*, unavailable)
    init() {
        fatalError("init() has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Alert Campaigns"

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(refreshAction(_:)),
                                 for: .valueChanged)
        self.refreshControl = refreshControl

        let debugItem = UIBarButtonItem(title: "Debug",
                                        style: .plain,
                                        target: self,
                                        action: #selector(debugButtonAction(_:)))
        navigationItem.leftBarButtonItem = debugItem

        let addItem = UIBarButtonItem(barButtonSystemItem: .add,
                                      target: self,
                                      action: #selector(addButtonAction(_:)))
        navigationItem.rightBarButtonItem = addItem

        let cell = AlertCampaignTableViewCell.self
        let cellID = String(describing: cell)
        tableView.register(cell, forCellReuseIdentifier: cellID)

        update()
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.alerts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = String(describing: AlertCampaignTableViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)

        let alertCampaign = model.alerts[indexPath.row]
        cell.textLabel?.text = alertCampaign.identifier
        cell.detailTextLabel?.text = "\(alertCampaign.title ?? "<Empty>"), " +
            "\(alertCampaign.message ?? "<Empty>")"
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertCampaign = model.alerts[indexPath.row]
            model.delete(alertCampaign) { [weak self] errors in
                guard let self = self else { return }
                self.displayErrorsIfNeeded(errors)

                if errors.isEmpty {
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let alertCampaign = model.alerts[indexPath.row]
        showAlertCampaignEditor(alertCampaign: alertCampaign)
    }

    // MARK: Actions

    @objc
    private func refreshAction(_ sender: Any) {
        update(forced: true)
    }

    @objc
    private func debugButtonAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let createTestAction = UIAlertAction(title: "Create Test Alert Campaign", style: .default) { _ in
            self.model.createTestAlertCampaign()

            // wait for update from server
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.update()
            }
        }
        alert.addAction(createTestAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    @objc
    private func addButtonAction(_ sender: Any) {
        showAlertCampaignEditor(alertCampaign: nil)
    }

    // MARK: Private

    private func update(forced: Bool = false) {
        if !forced && !model.canUpdate {
            return
        }

        refreshControl?.beginRefreshing()

        model.update { [weak self] errors in
            self?.refreshControl?.endRefreshing()
            self?.tableView.reloadData()

            self?.displayErrorsIfNeeded(errors)
        }
    }

    private func showAlertCampaignEditor(alertCampaign: CLMAlertCampaign?) {
        let controller = AlertCampaignViewController(alertCampaign: alertCampaign,
                                                     service: model.service)
        controller.delegate = self
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }
}

extension AlertCampaignListViewController: AlertCampaignViewControllerDelegate {
    func alertCampaignViewController(didCancel controller: AlertCampaignViewController) {
        dismiss(animated: true)
    }

    func alertCampaignViewController(_ controller: AlertCampaignViewController,
                                     didFinishWith alertCampaign: CLMAlertCampaign) {
        dismiss(animated: true)

        // wait for update from server
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.update()
        }
    }
}
