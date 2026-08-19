import Foundation

enum LegalDocuments {
    static let lastUpdated = "August 19, 2026"
    static let appName = "Stash Quest"
    static let contactEmail = "support@bradleyvirtual.com"

    private static let repoBase = "https://github.com/ronb12/StashQuest/blob/master"

    static let privacyPolicyURL = URL(string: "\(repoBase)/PRIVACY.md")!
    static let termsOfServiceURL = URL(string: "\(repoBase)/TERMS.md")!
    static let supportURL = URL(string: "\(repoBase)/SUPPORT.md")!

    static let privacyPolicySections: [(title: String, body: String)] = [
        (
            "Overview",
            """
            Stash Quest is a family savings app. You log real-money skips and stashes on your device. We built it so your family's data stays on your iPhone or iPad — not on our servers.
            """
        ),
        (
            "Information we collect",
            """
            Stash Quest does not require an account and does not send your savings data to Bradley Virtual Solutions or any third-party analytics service.

            Data you enter in the app — family names, profile names, savings logs, challenge progress, and reminder preferences — is stored locally on your device using Apple's on-device storage (SwiftData).
            """
        ),
        (
            "Information we do not collect",
            """
            We do not collect:

            • Bank account or credit card numbers
            • Social Security numbers
            • Precise location data
            • Contacts or photos
            • Advertising identifiers for tracking

            Stash Quest does not connect to your bank. All dollar amounts are entered by you.
            """
        ),
        (
            "Notifications",
            """
            If you turn on savings reminders, Stash Quest schedules local notifications on your device (for example, allowance day, Coin Friday, or $5 Friday). Notification permission is optional and controlled in iOS Settings.
            """
        ),
        (
            "Children and families",
            """
            Stash Quest is designed for families. Kid profiles are created and managed by a parent or guardian on the same device. We do not knowingly collect personal information from children through a separate online account because no online account exists.
            """
        ),
        (
            "Data retention and deletion",
            """
            Your data remains on your device until you delete it or remove the app. Deleting a profile, activity entry, or the app removes that information from your device. We cannot recover data after you delete it because we do not store a copy.
            """
        ),
        (
            "Changes",
            """
            We may update this Privacy Policy from time to time. The "Last updated" date at the top of this screen will change when we do. Continued use of the app after an update means you accept the revised policy.
            """
        ),
        (
            "Contact",
            """
            Questions about privacy? Email us at \(contactEmail).
            """
        ),
    ]

    static let termsOfServiceSections: [(title: String, body: String)] = [
        (
            "Agreement",
            """
            By downloading or using Stash Quest, you agree to these Terms of Service. If you do not agree, do not use the app.
            """
        ),
        (
            "What Stash Quest is",
            """
            Stash Quest helps families track real-money savings through challenges, logs, and goals. It is a personal finance helper — not a bank, investment advisor, or payment service.

            Dollar amounts you enter are for your own tracking. The app does not move money, hold deposits, or verify transactions.
            """
        ),
        (
            "Your responsibility",
            """
            You are responsible for:

            • Entering accurate amounts
            • Supervising children who use kid profiles on a shared device
            • Keeping your device secure (passcode, Face ID, etc.)
            • Any real-world saving, spending, or giving you do outside the app

            Stash Quest is not financial advice. Talk to a qualified professional for tax, investment, or legal questions.
            """
        ),
        (
            "Acceptable use",
            """
            You agree not to misuse the app, attempt to reverse engineer it, or use it in any way that violates applicable law.
            """
        ),
        (
            "Intellectual property",
            """
            Stash Quest, including its name, design, and content, is owned by Bradley Virtual Solutions. You receive a limited, personal, non-transferable license to use the app on your Apple devices.
            """
        ),
        (
            "Disclaimer",
            """
            Stash Quest is provided "as is" without warranties of any kind. We do not guarantee that the app will be error-free or uninterrupted. We are not liable for any loss tied to savings decisions you make in real life based on app totals or challenges.
            """
        ),
        (
            "Limitation of liability",
            """
            To the fullest extent permitted by law, Bradley Virtual Solutions is not liable for indirect, incidental, or consequential damages arising from your use of Stash Quest.
            """
        ),
        (
            "Changes and termination",
            """
            We may update these terms or discontinue features at any time. We may stop offering the app. Your local data on your device is unaffected by term updates unless you choose to delete it.
            """
        ),
        (
            "Contact",
            """
            Questions about these terms? Email \(contactEmail).
            """
        ),
    ]
}
