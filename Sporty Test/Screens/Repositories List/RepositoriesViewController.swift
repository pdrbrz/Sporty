import Combine
import GitHubAPI
import MockLiveServer
import SwiftUI
import UIKit

/// A view controller that displays a list of GitHub repositories for the "swiftlang" organization.
final class RepositoriesViewController: UITableViewController {
    // MARK: - Constants

    private enum Constants {
        static let cellIdentifier = "RepositoryCell"
    }

    // MARK: - Properties

    private let gitHubAPI: GitHubAPI
    private let mockLiveServer: MockLiveServer
    private var repositories: [GitHubMinimalRepository] = []

    // MARK: - Life cycle

    init(gitHubAPI: GitHubAPI, mockLiveServer: MockLiveServer) {
        self.gitHubAPI = gitHubAPI
        self.mockLiveServer = mockLiveServer
        super.init(style: .insetGrouped)
        title = "swiftlang"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(RepositoryTableViewCell.self,
                           forCellReuseIdentifier: "RepositoryCell")

        // Task E: Pull-to-refresh
        // Since the project's iOS target is +15.0, we can use UIAction instead of a @objc private method
        refreshControl = UIRefreshControl()
        refreshControl?.addAction(UIAction { _ in
            Task { await self.loadRepositories() }
        }, for: .valueChanged)

        Task { await loadRepositories() }
    }

    // MARK: - Data loading

    private func loadRepositories() async {
        do {
            repositories = try await gitHubAPI.repositoriesForOrganisation("swiftlang")
            tableView.reloadData()
        } catch {
            print("Error loading repositories:", error)
        }
        await MainActor.run { self.refreshControl?.endRefreshing() }
    }
}

// MARK: - Extensions

// MARK: Table View

extension RepositoriesViewController {
    override func numberOfSections(in _: UITableView) -> Int { 1 }

    override func tableView(
        _: UITableView,
        numberOfRowsInSection _: Int
    ) -> Int {
        repositories.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell
    {
        let repo = repositories[indexPath.row]
        // Replacing cell force-cast with a safe empty cell in case of failure
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RepositoryTableViewCell.reuseID,
            for: indexPath
        ) as? RepositoryTableViewCell else {
            assertionFailure("Failed to dequeue RepositoryTableViewCell")
            return UITableViewCell()
        }

        cell.name = repo.name
        cell.descriptionText = repo.description
        cell.starCountText = repo.stargazersCount.formatted()
        return cell
    }

    override func tableView(
        _: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let repo = repositories[indexPath.row]
        let vc = RepositoryViewController(
            minimalRepository: repo,
            gitHubAPI: gitHubAPI
        )
        show(vc, sender: self)
    }
}
