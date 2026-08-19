import Foundation

enum ChallengeAudience: String, CaseIterable {
    case grownUp = "Grown-ups"
    case kid = "Kids"
    case family = "Family"
}

enum ChallengeCategory: String {
    case skip = "Skip it"
    case stash = "Stash it"
    case goal = "Build a goal"
}

enum ChallengeDuration: String {
    case oneDay = "1 day"
    case weekend = "Weekend"
    case week = "7 days"
    case tenWeeks = "10 weeks"
    case month = "30 days"
    case ongoing = "Ongoing"
}

struct Challenge: Identifiable, Hashable {
    let id: String
    let name: String
    let rule: String
    let audience: ChallengeAudience
    let category: ChallengeCategory
    let duration: ChallengeDuration
    let defaultAmount: Double
    let defaultAmountLabel: String
    let supportsParentMatch: Bool
    let goalAmount: Double?

    var durationDays: Int? {
        switch duration {
        case .oneDay: return 1
        case .weekend: return 2
        case .week: return 7
        case .tenWeeks: return 70
        case .month: return 30
        case .ongoing: return nil
        }
    }
}

enum ChallengeCatalog {
    static let all: [Challenge] = grownUp + kids + family

    static func challenges(for audience: ChallengeAudience) -> [Challenge] {
        all.filter { $0.audience == audience }
    }

    static func challenge(id: String) -> Challenge? {
        all.first { $0.id == id }
    }

    // MARK: - Grown-ups (22)

    static let grownUp: [Challenge] = [
        Challenge(id: "adult-no-spend-day", name: "No-Spend Day", rule: "24 hours with no non-essential spending. Log what you almost bought.", audience: .grownUp, category: .skip, duration: .oneDay, defaultAmount: 15, defaultAmountLabel: "$15", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-no-spend-weekend", name: "No-Spend Weekend", rule: "Saturday and Sunday — essentials only.", audience: .grownUp, category: .skip, duration: .weekend, defaultAmount: 40, defaultAmountLabel: "$40", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-no-spend-week", name: "No-Spend Week", rule: "7 days: rent, utilities, and groceries only.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 75, defaultAmountLabel: "$75", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-pantry-raid", name: "Pantry Raid", rule: "5 days cooking only from food already at home.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 25, defaultAmountLabel: "$25", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-brown-bag", name: "Brown-Bag Week", rule: "Pack lunch every workday. Log skipped takeout.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 12, defaultAmountLabel: "$12", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-coffee-skip", name: "Coffee Shop Skip", rule: "Homemade coffee for 7 days. Log your usual order.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 6.50, defaultAmountLabel: "$6.50", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-delivery-detox", name: "Delivery Detox", rule: "No delivery apps for 7 days.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 22, defaultAmountLabel: "$22", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-streaming-sweep", name: "Streaming Sweep", rule: "Cancel one unused subscription. Log the monthly fee.", audience: .grownUp, category: .skip, duration: .oneDay, defaultAmount: 12.99, defaultAmountLabel: "$12.99", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-subscription-audit", name: "Subscription Audit", rule: "Review all subscriptions and cancel at least one.", audience: .grownUp, category: .skip, duration: .oneDay, defaultAmount: 9.99, defaultAmountLabel: "$9.99", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-24-hour-rule", name: "24-Hour Rule", rule: "Impulse over $20 waits a day. If you pass, log the price.", audience: .grownUp, category: .skip, duration: .ongoing, defaultAmount: 25, defaultAmountLabel: "$25", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-cash-only-weekend", name: "Cash-Only Weekend", rule: "Withdraw a spending cap. Leftover gets stashed.", audience: .grownUp, category: .skip, duration: .weekend, defaultAmount: 30, defaultAmountLabel: "$30", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-homemade-week", name: "Homemade Week", rule: "No restaurants for 7 days.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 35, defaultAmountLabel: "$35", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-amazon-freeze", name: "Amazon Freeze", rule: "7 days off Amazon. Log abandoned-cart totals.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 28, defaultAmountLabel: "$28", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-closet-challenge", name: "Closet Challenge", rule: "30 days with no new clothes.", audience: .grownUp, category: .skip, duration: .month, defaultAmount: 45, defaultAmountLabel: "$45", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-walk-it-off", name: "Walk It Off", rule: "Skip rideshare and parking for short trips.", audience: .grownUp, category: .skip, duration: .week, defaultAmount: 8, defaultAmountLabel: "$8", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-round-up", name: "Round-Up", rule: "Round each purchase to the next dollar. Stash the cents.", audience: .grownUp, category: .stash, duration: .ongoing, defaultAmount: 0.75, defaultAmountLabel: "$0.75", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-five-friday", name: "$5 Friday", rule: "Every Friday, stash $5 (or more).", audience: .grownUp, category: .stash, duration: .ongoing, defaultAmount: 5, defaultAmountLabel: "$5", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-52-week", name: "52-Week", rule: "Week N, stash $N. Full year reaches $1,378.", audience: .grownUp, category: .stash, duration: .ongoing, defaultAmount: 1, defaultAmountLabel: "$1", supportsParentMatch: false, goalAmount: 1378),
        Challenge(id: "adult-payday-slice", name: "Payday Slice", rule: "Every payday, stash a fixed amount.", audience: .grownUp, category: .stash, duration: .ongoing, defaultAmount: 50, defaultAmountLabel: "$50", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-found-money", name: "Found Money", rule: "Refunds, cashback, and gifts — 100% into savings.", audience: .grownUp, category: .stash, duration: .ongoing, defaultAmount: 20, defaultAmountLabel: "$20", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "adult-500-starter", name: "$500 Starter", rule: "Build your first emergency cushion.", audience: .grownUp, category: .goal, duration: .ongoing, defaultAmount: 25, defaultAmountLabel: "$25", supportsParentMatch: false, goalAmount: 500),
        Challenge(id: "adult-1000-starter", name: "First $1,000", rule: "Classic starter emergency fund.", audience: .grownUp, category: .goal, duration: .ongoing, defaultAmount: 50, defaultAmountLabel: "$50", supportsParentMatch: false, goalAmount: 1000),
    ]

    // MARK: - Kids (22)

    static let kids: [Challenge] = [
        Challenge(id: "kid-piggy-1", name: "Piggy $1", rule: "Each allowance, at least $1 goes in the piggy.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 1, defaultAmountLabel: "$1", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-half-half", name: "Half and Half", rule: "Half of allowance saved, half to spend.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 2.50, defaultAmountLabel: "$2.50", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-three-jars", name: "Three Jars", rule: "Spend, Save, and Give. Log each Save jar deposit.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 1, defaultAmountLabel: "$1", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-wait-one-day", name: "Wait One Day", rule: "Want a toy? Wait 24 hours. If you still pass, log the price.", audience: .kid, category: .skip, duration: .oneDay, defaultAmount: 10, defaultAmountLabel: "$10", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "kid-no-candy", name: "No Candy Checkout", rule: "Skip candy or gum at checkout. Log $1–$3.", audience: .kid, category: .skip, duration: .ongoing, defaultAmount: 2, defaultAmountLabel: "$2", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "kid-leave-toy", name: "Leave the Toy", rule: "Skip one toy at the store. Log the tag price.", audience: .kid, category: .skip, duration: .oneDay, defaultAmount: 15, defaultAmountLabel: "$15", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "kid-save-for-it", name: "Save For It", rule: "Pick one thing you want. Stash until you can buy it.", audience: .kid, category: .goal, duration: .ongoing, defaultAmount: 2, defaultAmountLabel: "$2", supportsParentMatch: true, goalAmount: 25),
        Challenge(id: "kid-coin-friday", name: "Coin Friday", rule: "Dump coins into savings once a week.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 3, defaultAmountLabel: "$3", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-birthday-bite", name: "Birthday Bite", rule: "Save some birthday money instead of spending it all.", audience: .kid, category: .stash, duration: .oneDay, defaultAmount: 5, defaultAmountLabel: "$5", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-tooth-fairy", name: "Tooth Fairy Stash", rule: "Tooth money goes straight in the piggy.", audience: .kid, category: .stash, duration: .oneDay, defaultAmount: 2, defaultAmountLabel: "$2", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-found-money", name: "Found Money", rule: "Couch coins and dropped dollars — 100% in.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 1, defaultAmountLabel: "$1", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-chore-boost", name: "Chore Boost", rule: "Extra chore pay — stash part or all of it.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 3, defaultAmountLabel: "$3", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-lemonade-cut", name: "Lemonade Cut", rule: "Money from lemonade or odd jobs — stash a slice.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 5, defaultAmountLabel: "$5", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-no-vending", name: "No Vending", rule: "Skip the vending machine. Log the snack price.", audience: .kid, category: .skip, duration: .ongoing, defaultAmount: 1.50, defaultAmountLabel: "$1.50", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "kid-water-not-soda", name: "Water Not Soda", rule: "Drink water instead. Stash the soda or juice cost.", audience: .kid, category: .skip, duration: .ongoing, defaultAmount: 2, defaultAmountLabel: "$2", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "kid-toy-fast", name: "Toy Fast", rule: "7 days with no new toys or apps. Log what you almost bought.", audience: .kid, category: .skip, duration: .week, defaultAmount: 8, defaultAmountLabel: "$8", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "kid-library", name: "Library Not Store", rule: "Borrow a book or game instead of buying.", audience: .kid, category: .skip, duration: .oneDay, defaultAmount: 12, defaultAmountLabel: "$12", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "kid-yard-sale", name: "Yard Sale", rule: "Sell old toys. Stash what you made.", audience: .kid, category: .stash, duration: .oneDay, defaultAmount: 10, defaultAmountLabel: "$10", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-break-five", name: "Break the $5", rule: "Any $5 you get — $1 must go in.", audience: .kid, category: .stash, duration: .ongoing, defaultAmount: 1, defaultAmountLabel: "$1", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "kid-10-weeks", name: "10 Weeks of $1", rule: "$1 a week for 10 weeks toward a $10 goal.", audience: .kid, category: .goal, duration: .tenWeeks, defaultAmount: 1, defaultAmountLabel: "$1", supportsParentMatch: true, goalAmount: 10),
        Challenge(id: "kid-wish-list", name: "Wish-List One", rule: "Pick one gift you want to give someone. Save for it.", audience: .kid, category: .goal, duration: .ongoing, defaultAmount: 2, defaultAmountLabel: "$2", supportsParentMatch: true, goalAmount: 20),
        Challenge(id: "kid-want-vs-need", name: "Want vs Need Week", rule: "7 days — only needs. Log skipped wants.", audience: .kid, category: .skip, duration: .week, defaultAmount: 5, defaultAmountLabel: "$5", supportsParentMatch: false, goalAmount: nil),
    ]

    // MARK: - Family (6)

    static let family: [Challenge] = [
        Challenge(id: "family-parent-match", name: "Parent Match", rule: "When a kid stashes money, a grown-up adds the same amount to the kid's vault.", audience: .family, category: .stash, duration: .ongoing, defaultAmount: 5, defaultAmountLabel: "$5", supportsParentMatch: true, goalAmount: nil),
        Challenge(id: "family-no-spend-night", name: "Family No-Spend Night", rule: "One evening of free fun only. Log the outing you skipped.", audience: .family, category: .skip, duration: .oneDay, defaultAmount: 40, defaultAmountLabel: "$40", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "family-trip-jar", name: "Trip Jar", rule: "Shared vacation or day-trip goal. Anyone can log into the family pot.", audience: .family, category: .goal, duration: .ongoing, defaultAmount: 20, defaultAmountLabel: "$20", supportsParentMatch: false, goalAmount: 500),
        Challenge(id: "family-holiday", name: "Holiday Together", rule: "Weekly family stash until December.", audience: .family, category: .goal, duration: .ongoing, defaultAmount: 15, defaultAmountLabel: "$15", supportsParentMatch: false, goalAmount: 300),
        Challenge(id: "family-game-night", name: "Game Night In", rule: "Skip paid entertainment. Log the outing cost.", audience: .family, category: .skip, duration: .oneDay, defaultAmount: 35, defaultAmountLabel: "$35", supportsParentMatch: false, goalAmount: nil),
        Challenge(id: "family-give-little", name: "Give a Little", rule: "Pick a cause. Each person stashes a small give amount, then donates it.", audience: .family, category: .stash, duration: .oneDay, defaultAmount: 5, defaultAmountLabel: "$5", supportsParentMatch: false, goalAmount: nil),
    ]
}
