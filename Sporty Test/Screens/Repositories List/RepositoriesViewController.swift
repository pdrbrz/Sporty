import Combine
import GitHubAPI
import MockLiveServer
import UIKit

final class RepositoriesViewController: UIViewController {
    // MARK: Constants

    private enum Constants { static let organisation = "swiftlang" }

    // MARK: Stored state

    private let contentView = RepositoriesView()
    private let gitHubAPI: GitHubAPI
    private let mockLiveServer: MockLiveServer

    @MainActor private var liveStarCounts: [Int: Int] = [:]
    @MainActor private var liveStarSubscriptions: [Int: AnyCancellable] = [:]
    @MainActor private var repositories: [GitHubMinimalRepository] = []

    // MARK: Init

    init(gitHubAPI: GitHubAPI, mockLiveServer: MockLiveServer) {
        self.gitHubAPI = gitHubAPI
        self.mockLiveServer = mockLiveServer
        super.init(nibName: nil, bundle: nil)
        title = Constants.organisation
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: View life-cycle

    override func loadView() { view = contentView }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureRefresh()
        Task { await loadRepositories() }
    }

    deinit {
        liveStarSubscriptions.values.forEach { $0.cancel() }
    }

    // MARK: Setup

    private func configureTableView() {
        contentView.tableView.dataSource = self
        contentView.tableView.delegate = self
    }

    private func configureRefresh() {
        // Task E: Pull-to-refresh
        // Since the project's iOS target is +15.0, we can use UIAction instead of a @objc private method
        contentView.refreshControl.addAction(
            UIAction { [weak self] _ in
                Task { await self?.loadRepositories() }
            },
            for: .valueChanged
        )
    }

    // MARK: Networking

    private func loadRepositories() async {
        do {
            let fetched = try await gitHubAPI.repositoriesForOrganisation(Constants.organisation)

            await MainActor.run {
                repositories = fetched
                contentView.tableView.reloadData()
                contentView.tableView.layoutIfNeeded()
            }

            await subscribeToLiveStars()
        } catch {
            print("Error loading repositories:", error)
        }

        await MainActor.run { contentView.refreshControl.endRefreshing() }
    }

    // MARK: Live-star feed

    /// Re-subscribes every repo to `MockLiveServer`.
    /// Task G: Real time updates for star counting using MockLiveServer
    /// Used AI Assistant to navigate me through Combine
    @MainActor
    private func subscribeToLiveStars() async {
        liveStarSubscriptions.values.forEach { $0.cancel() }
        liveStarSubscriptions.removeAll()
        liveStarCounts.removeAll()

        for repo in repositories {
            do {
                // Call to actor-isolated method ⇒ needs `await`.
                let cancellable = try await mockLiveServer.subscribeToRepo(
                    repoId: repo.id,
                    currentStars: repo.stargazersCount
                ) { [weak self] newStars in
                    guard let self else { return }

                    // Hop to the main actor for state and UI changes.
                    Task { @MainActor in
                        self.liveStarCounts[repo.id] = newStars

                        if let row = self.repositories.firstIndex(where: { $0.id == repo.id }),
                           let cell = self.contentView.tableView
                           .cellForRow(at: IndexPath(row: row, section: 0))
                           as? RepositoryTableViewCell
                        {
                            cell.starCountText = newStars.formatted()
                        }
                    }
                }

                liveStarSubscriptions[repo.id] = cancellable
            } catch {
                print("Could not subscribe to repo \(repo.id):", error)
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension RepositoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int { 1 }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        repositories.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RepositoryTableViewCell.reuseID,
            for: indexPath
        ) as? RepositoryTableViewCell else {
            assertionFailure("Failed to dequeue RepositoryTableViewCell")
            return UITableViewCell()
        }

        let repo = repositories[indexPath.row]
        let stars = liveStarCounts[repo.id] ?? repo.stargazersCount

        cell.name = repo.name
        cell.descriptionText = repo.description
        cell.starCountText = stars.formatted()

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let repo = repositories[indexPath.row]
        let viewController = RepositoryViewController(minimalRepository: repo,
                                          gitHubAPI: gitHubAPI)
        show(viewController, sender: self)
    }
}
