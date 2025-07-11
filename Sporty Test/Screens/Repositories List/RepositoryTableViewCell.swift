import UIKit

/// A cell displaying the basic information of a GitHub repository.
final class RepositoryTableViewCell: UITableViewCell {
    
    // MARK:
    private enum Spacing {
        static let small = 4.0
        static let medium = 8.0
    }
    
    // MARK: Public interface

    var name: String? {
        get { nameLabel.text }
        set { nameLabel.text = newValue }
    }
    
    var descriptionText: String? {
        get { descriptionLabel.text }
        set { descriptionLabel.text = newValue }
    }
    
    var starCountText: String? {
        get { starCountLabel.text }
        set { starCountLabel.text = newValue }
    }

    // MARK: – UI elements

    private let nameLabel: UILabel = {
        let label = UILabel()
        let base = UIFont.preferredFont(forTextStyle: .body)
        let bold = base.fontDescriptor.withSymbolicTraits(.traitBold)
        label.font = bold.flatMap { UIFont(descriptor: $0, size: 0) } ?? base
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let starImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .caption1))
        let image = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: config))
        image.tintColor = .systemYellow
        return image
    }()

    private let starCountLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
                                           weight: .regular)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var starInfoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [starImageView, starCountLabel])
        stack.axis = .horizontal
        stack.spacing = Spacing.small
        stack.alignment = .firstBaseline
        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stack
    }()

    private lazy var topRowStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, starInfoStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = Spacing.medium
        stack.alignment = .firstBaseline
        stack.distribution = .fill
        return stack
    }()

    // MARK: Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(topRowStack)
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            topRowStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            topRowStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            topRowStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: topRowStack.bottomAnchor, constant: Spacing.small),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            contentView.layoutMarginsGuide.bottomAnchor
                .constraint(equalTo: descriptionLabel.bottomAnchor, constant: Spacing.small),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// Convenience for reuse identifier
extension RepositoryTableViewCell {
    static let reuseID = "RepositoryCell"
}
