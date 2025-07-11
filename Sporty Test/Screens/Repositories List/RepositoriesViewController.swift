import Combine
import GitHubAPI
import MockLiveServer
import UIKit

/// Lists the public repositories of the “swiftlang” organization.
final class RepositoriesViewController: UIViewController {
    // MARK: - Constants

    private enum Constants {
        static let organisation = "swiftlang"
    }

    // MARK: - Properties

    private let gitHubAPI: GitHubAPI
    private let mockLiveServer: MockLiveServer
    private var repositories: [GitHubMinimalRepository] = []

    // MARK: - View

    private let contentView = RepositoriesView()

    // MARK: - Life cycle

    init(gitHubAPI: GitHubAPI, mockLiveServer: MockLiveServer) {
        self.gitHubAPI = gitHubAPI
        self.mockLiveServer = mockLiveServer
        super.init(nibName: nil, bundle: nil)
        title = Constants.organisation
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = contentView
    }

    override func viewWillAppear(_: Bool) {
        contentView.layoutSubviews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureRefresh()
        Task { await loadRepositories() }
    }

    // MARK: - Setup

    private func configureTableView() {
        contentView.tableView.dataSource = self
        contentView.tableView.delegate = self
    }

    private func configureRefresh() {
        // Task E: Pull-to-refresh
        // Since the project's iOS target is +15.0, we can use UIAction instead of a @objc private method
        contentView.refreshControl.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                Task { await self.loadRepositories() }
            },
            for: .valueChanged
        )
    }

    // MARK: - Networking

    private func loadRepositories() async {
        do {
            repositories = try await gitHubAPI.repositoriesForOrganisation(Constants.organisation)
            await MainActor.run {
                /// Name label height needs to be improved on first view load
                contentView.tableView.reloadData()
                contentView.tableView.layoutIfNeeded()
            }
        } catch {
            print("Error loading repositories:", error)
        }
        await MainActor.run { contentView.refreshControl.endRefreshing() }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension RepositoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int { 1 }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        repositories.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
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

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let repo = repositories[indexPath.row]
        let vc = RepositoryViewController(minimalRepository: repo, gitHubAPI: gitHubAPI)
        show(vc, sender: self)
    }
}
