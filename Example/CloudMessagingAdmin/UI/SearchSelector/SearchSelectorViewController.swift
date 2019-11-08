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

import UIKit

protocol SearchSelectorItem {
    var attributedTitle: NSAttributedString { get }
}

protocol SearchSelectorModel: AnyObject {
    associatedtype Item: SearchSelectorItem

    var items: [Item] { get }
    var selectedIndexes: Set<Int> { get set }

    func filterItems(searchQuery: String)
}

final class SearchSelectorTableViewCell: UITableViewCell {
    func configure(with item: SearchSelectorItem, selected: Bool) {
        textLabel?.attributedText = item.attributedTitle
        accessoryType = selected ? .checkmark : .none
    }
}

final class SearchSelectorViewController<T: SearchSelectorModel>: UITableViewController, UISearchResultsUpdating {
    var multiSelection = false

    private let model: T
    private let selectionChanged: ([T.Item]) -> Void

    init(model: T, selectionBlock: @escaping ([T.Item]) -> Void) {
        self.model = model
        selectionChanged = selectionBlock

        super.init(style: .grouped)
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
    override init(style: UITableView.Style) {
        fatalError("init(style:) has not been implemented")
    }

    @available(*, unavailable)
    init() {
        fatalError("init() has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0
        let cell = SearchSelectorTableViewCell.self
        tableView.register(cell, forCellReuseIdentifier: String(describing: cell))

        if multiSelection {
            let barButton = UIBarButtonItem(title: "",
                                            style: .plain,
                                            target: self,
                                            action: #selector(uncheckAllButtonAction))
            navigationItem.rightBarButtonItem = barButton
            updateSelectionButtonTitle()
        }

        // Search Controller

        definesPresentationContext = true

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        let searchBar = searchController.searchBar
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let selectedIndex = model.selectedIndexes.first {
            let indexPath = IndexPath(row: selectedIndex, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        }
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = String(describing: SearchSelectorTableViewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
            as? SearchSelectorTableViewCell else {
            fatalError("Invalid cell")
        }

        let index = indexPath.row
        let item = model.items[index]
        let selected = model.selectedIndexes.contains(index)
        cell.configure(with: item, selected: selected)

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let index = indexPath.row

        if multiSelection {
            if model.selectedIndexes.contains(index) {
                model.selectedIndexes.remove(index)
            }
            else {
                model.selectedIndexes.insert(index)
            }

            tableView.reloadRows(at: [indexPath], with: .none)
            updateSelectionButtonTitle()
        }
        else {
            model.selectedIndexes.removeAll()
            model.selectedIndexes.insert(index)
        }

        let selectedItems = model.selectedIndexes.map { model.items[$0] }
        selectionChanged(selectedItems)
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchQuery = searchController.searchBar.text ?? ""
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespaces)
        model.filterItems(searchQuery: trimmedQuery)

        tableView.reloadData()
    }

    // MARK: Actions

    @objc
    func uncheckAllButtonAction() {
        let selectedItems: [T.Item]
        if model.selectedIndexes.isEmpty {
            model.selectedIndexes = Set(0 ..< model.items.count)
            selectedItems = model.items
        }
        else {
            model.selectedIndexes.removeAll()
            selectedItems = []
        }

        updateSelectionButtonTitle()
        tableView.reloadData()

        selectionChanged(selectedItems)
    }

    // MARK: Private

    func updateSelectionButtonTitle() {
        let title: String
        if model.selectedIndexes.isEmpty {
            title = "Check All"
        }
        else {
            title = "Uncheck All"
        }
        navigationItem.rightBarButtonItem?.title = title
    }
}
