import UIKit

/// Simple container view for the repositories screen.
final class RepositoriesView: UIView {
    // MARK: Constants

    private enum Constants {
        static let rowHeight: CGFloat = UITableView.automaticDimension
    }

    // MARK: Subviews

    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private(set) lazy var refreshControl = UIRefreshControl()

    // MARK: Init

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Private helpers

    private func configureView() {
        backgroundColor = .systemBackground

        tableView.rowHeight = Constants.rowHeight
        tableView.register(RepositoryTableViewCell.self,
                           forCellReuseIdentifier: RepositoryTableViewCell.reuseID)
        tableView.refreshControl = refreshControl

        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
