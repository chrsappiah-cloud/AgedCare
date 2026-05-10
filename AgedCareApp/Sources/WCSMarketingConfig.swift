import Foundation

// MARK: - App Product Model

struct WCSAppProduct: Identifiable {
    let id: String
    let name: String
    let bundleId: String
    let appId: String
    let category: String
    let tagline: String
    let icon: String
    let tier: String
    let price: String
    let platform: String
    let betaTrack: BetaTrack

    var websitePage: URL {
        URL(string: "https://wcs-full.vercel.app/apps/\(id)")!
    }
    var paymentLink: URL {
        URL(string: "https://wcs-full.vercel.app/pay/\(id)")!
    }
    var testFlightLink: URL {
        URL(string: "https://wcs-full.vercel.app/testflight/\(id)")!
    }
    var feedbackLink: URL {
        URL(string: "https://wcs-full.vercel.app/feedback/\(id)")!
    }
}

// MARK: - Beta Tracks (from PDF Phase 2)

enum BetaTrack: String, CaseIterable, Identifiable {
    case care = "Track C — WCS Care"
    case learn = "Track A — WCS Learn"
    case artVerse = "Track B — WCS Art-Verse"
    case platform = "Track D — WCS Platform"
    case tools = "Track E — Developer & Productivity"
    case general = "Track F — General"

    var id: String { rawValue }

    var targetAudience: String {
        switch self {
        case .care: return "Carers, dementia support workers, care organizations"
        case .learn: return "Students, educators, institutions"
        case .artVerse: return "Digital artists, art educators, creative professionals"
        case .platform: return "Scholars, mentors, community builders"
        case .tools: return "Developers, builders, productivity users"
        case .general: return "General users, early adopters"
        }
    }

    var northStar: String {
        switch self {
        case .care: return "Reduce confusion and improve daily routine consistency for people living with dementia"
        case .learn: return "Save time for educators and reduce confusion for students"
        case .artVerse: return "Enable creative expression and digital art creation"
        case .platform: return "Connect scholars with mentoring and world-class learning"
        case .tools: return "Accelerate building and shipping products"
        case .general: return "Deliver clear, useful value through focused tools"
        }
    }
}

// MARK: - Growth Phase (12-Month Roadmap from PDF)

enum GrowthPhase: String, CaseIterable, Identifiable {
    case foundation = "Phase 1: Foundation"
    case expansion = "Phase 2: Gradual Expansion"
    case preLaunch = "Phase 3: Pre-Launch Momentum"
    case scale = "Phase 4: Scale & Operations"

    var id: String { rawValue }

    var months: String {
        switch self {
        case .foundation: return "Months 1-3"
        case .expansion: return "Months 4-6"
        case .preLaunch: return "Months 7-9"
        case .scale: return "Months 10-12"
        }
    }

    var goals: [String] {
        switch self {
        case .foundation:
            return [
                "Launch with core features that solve specific problems",
                "Recruit 50-100 targeted testers per beta track",
                "Refine onboarding flows based on early confusion points",
                "Use TestFlight feedback to understand user behavior",
            ]
        case .expansion:
            return [
                "Bi-weekly TestFlight builds with incremental refinements",
                "Segment beta groups by edtech, arts, and care",
                "Scale to 500-1,000 testers through referrals",
                "Document clear positioning for each app",
            ]
        case .preLaunch:
            return [
                "Implement in-app surveys and usage analytics",
                "Test monetization with freemium tiers",
                "Reach 10,000 TestFlight users via partnerships",
                "Prepare App Store positioning and marketing materials",
            ]
        case .scale:
            return [
                "Harden infrastructure and optimize performance",
                "Expand Care Team into structured B2B offering",
                "Use pilot data in grants and investor pitches",
                "Prepare Android/web companion if iOS retention is strong",
            ]
        }
    }

    var testerTarget: String {
        switch self {
        case .foundation: return "50-100"
        case .expansion: return "500-1,000"
        case .preLaunch: return "Up to 10,000"
        case .scale: return "10,000+"
        }
    }
}

struct WCSMarketingConfig {

    // MARK: - Core URLs

    static let websiteURL = URL(string: "https://wcs-full.vercel.app")!
    static let personalLinkURL = URL(string: "https://christopherappiahthompson.link")!
    static let supportEmail = "christopher.appiahthompson@myworldclass.org"
    static let personalEmail = "chrsappiah@gmail.com"
    static let pricingPageURL = URL(string: "https://wcs-full.vercel.app/pricing")!
    static let pilotFormURL = URL(string: "https://wcs-full.vercel.app/pilot-request")!
    static let waitlistURL = URL(string: "https://wcs-full.vercel.app/waitlist")!
    static let privacyPolicyURL = URL(string: "https://wcs-full.vercel.app/privacy")!
    static let termsURL = URL(string: "https://wcs-full.vercel.app/terms")!
    static let allAppsURL = URL(string: "https://wcs-full.vercel.app/apps")!
    static let donateURL = URL(string: "https://wcs-full.vercel.app/donate")!
    static let testFlightURL = URL(string: "https://testflight.apple.com/join/WCSCare")!
    static let feedbackFormURL = URL(string: "https://wcs-full.vercel.app/beta-feedback")!
    static let partnerOnboardingURL = URL(string: "https://wcs-full.vercel.app/partner-onboarding")!
    static let caseStudiesURL = URL(string: "https://wcs-full.vercel.app/case-studies")!
    static let changelogURL = URL(string: "https://wcs-full.vercel.app/changelog")!

    // MARK: - Founder Platforms

    static let myworldclassURL = URL(string: "https://myworldclass.org")!
    static let wcsArtVerseURL = URL(string: "https://wcs-art-verse.com")!
    static let gumroadURL = URL(string: "https://christopherappiahthompson.gumroad.com")!
    static let twineURL = URL(string: "https://www.twine.net/WorldClass123")!

    // MARK: - Real Social Media Handles

    static let socialLinks: [(name: String, icon: String, url: URL, handle: String)] = [
        ("Twitter / X", "bird.fill", URL(string: "https://x.com/christopherappi")!, "@christopherappi"),
        ("Instagram", "camera.fill", URL(string: "https://instagram.com/christopherappi")!, "@christopherappi"),
        ("LinkedIn", "link.circle.fill", URL(string: "https://linkedin.com/in/christopher-appiah-thompson-a2014045")!, "Christopher Appiah-Thompson"),
        ("Facebook", "person.2.fill", URL(string: "https://facebook.com/chris.appiah.396045")!, "Christopher Appiah-Thompson"),
        ("YouTube", "play.rectangle.fill", URL(string: "https://youtube.com/@christopherappi")!, "@christopherappi"),
        ("TikTok", "music.note", URL(string: "https://tiktok.com/@christopherappi")!, "@christopherappi"),
        ("Threads", "at.circle.fill", URL(string: "https://threads.net/@christopherappi")!, "@christopherappi"),
        ("Gumroad", "bag.fill", URL(string: "https://christopherappiahthompson.gumroad.com")!, "Art & Digital Works"),
    ]

    // MARK: - All 12 TestFlight App Products

    static let appProducts: [WCSAppProduct] = [
        WCSAppProduct(
            id: "agedcare",
            name: "AgedCare-Shared",
            bundleId: "wcs.Agedcare-shared",
            appId: "6767978725",
            category: "Health & Care",
            tagline: "AI-powered aged care monitoring with fall detection and real-time alerts",
            icon: "heart.circle.fill",
            tier: "Care Pro",
            price: "$9.99/mo",
            platform: "iOS",
            betaTrack: .care
        ),
        WCSAppProduct(
            id: "carelens",
            name: "carelens-aged+",
            bundleId: "wcs.Carelens-Aged-",
            appId: "6767072418",
            category: "Health & Care",
            tagline: "Smart lens for aged care — visual monitoring and AI-driven insights",
            icon: "eye.circle.fill",
            tier: "Care Pro",
            price: "$9.99/mo",
            platform: "iOS",
            betaTrack: .care
        ),
        WCSAppProduct(
            id: "medlingo",
            name: "medlingo",
            bundleId: "wcs.medlingo",
            appId: "6766951084",
            category: "Medical Education",
            tagline: "Medical terminology and language learning for healthcare professionals",
            icon: "textbook.fill",
            tier: "Pro",
            price: "$4.99/mo",
            platform: "iOS",
            betaTrack: .learn
        ),
        WCSAppProduct(
            id: "etherealveil",
            name: "Etherealveil",
            bundleId: "com.worldclassscholars.etherealveil",
            appId: "6763116253",
            category: "Creative & Art",
            tagline: "Digital art creation with ethereal filters and AI-enhanced visuals",
            icon: "paintbrush.pointed.fill",
            tier: "Creator",
            price: "$6.99/mo",
            platform: "iOS",
            betaTrack: .artVerse
        ),
        WCSAppProduct(
            id: "memorycanvas",
            name: "MemoryCanvas",
            bundleId: "com.worldclassscholars.memorycanvas",
            appId: "6762592097",
            category: "Reminiscence & Memory",
            tagline: "Memory preservation through photos, stories, and interactive timelines",
            icon: "photo.stack.fill",
            tier: "Premium",
            price: "$4.99/mo",
            platform: "iOS",
            betaTrack: .care
        ),
        WCSAppProduct(
            id: "neurocanvas",
            name: "NeuroCanvas",
            bundleId: "com.superappmac.neurocanvas",
            appId: "6762577204",
            category: "Neuroscience & Creative",
            tagline: "Brain-inspired creative tools for artists and neuroscience enthusiasts",
            icon: "brain.head.profile.fill",
            tier: "Pro",
            price: "$7.99/mo",
            platform: "iOS + macOS",
            betaTrack: .artVerse
        ),
        WCSAppProduct(
            id: "wcs-platform",
            name: "WCS-Platform",
            bundleId: "wcs.WCS-Platform",
            appId: "6763751751",
            category: "Education Platform",
            tagline: "World Class Scholars learning platform — courses, mentoring, and community",
            icon: "graduationcap.fill",
            tier: "Scholar",
            price: "$12.99/mo",
            platform: "iOS + macOS",
            betaTrack: .platform
        ),
        WCSAppProduct(
            id: "wcslib",
            name: "WCSLIB",
            bundleId: "wcs.WCSLIB",
            appId: "6764653278",
            category: "Developer Tools",
            tagline: "WCS component library and SDK for building world-class apps",
            icon: "hammer.fill",
            tier: "Developer",
            price: "$9.99/mo",
            platform: "iOS",
            betaTrack: .tools
        ),
        WCSAppProduct(
            id: "build-space",
            name: "build-space",
            bundleId: "com.wcs.neurocanvas",
            appId: "6762591870",
            category: "Productivity",
            tagline: "Collaborative workspace for builders — plan, design, and ship products",
            icon: "square.stack.3d.up.fill",
            tier: "Builder",
            price: "$7.99/mo",
            platform: "iOS",
            betaTrack: .tools
        ),
        WCSAppProduct(
            id: "geowcs",
            name: "GeoWCS",
            bundleId: "com.wcs.GeoWCS",
            appId: "6761536110",
            category: "Geography & Maps",
            tagline: "Geographic data visualisation and location intelligence",
            icon: "map.fill",
            tier: "Pro",
            price: "$4.99/mo",
            platform: "iOS",
            betaTrack: .general
        ),
        WCSAppProduct(
            id: "equity-kombat",
            name: "Equity Kombat",
            bundleId: "com.wcs.equity-kombat",
            appId: "6761084713",
            category: "Finance & Gaming",
            tagline: "Learn financial literacy through gamified combat and trading challenges",
            icon: "banknote.fill",
            tier: "Fighter",
            price: "$5.99/mo",
            platform: "iOS",
            betaTrack: .general
        ),
        WCSAppProduct(
            id: "african-fashion",
            name: "Wendy'SAfricanFash",
            bundleId: "wcs.AfricanFashionApp",
            appId: "6763326670",
            category: "Fashion & Culture",
            tagline: "African fashion marketplace — discover, style, and shop authentic designs",
            icon: "tshirt.fill",
            tier: "Stylist",
            price: "$3.99/mo",
            platform: "iOS",
            betaTrack: .general
        ),
    ]

    // MARK: - Payment Links (aggregated)

    static var paymentLinks: [(name: String, url: URL)] {
        appProducts.map { app in
            ("\(app.name) — \(app.tier) (\(app.price))", app.paymentLink)
        } + [
            ("Donate / Support All Projects", donateURL),
        ]
    }

    // MARK: - Backward-compatible flat list

    static var testFlightApps: [(name: String, bundleId: String, appId: String)] {
        appProducts.map { ($0.name, $0.bundleId, $0.appId) }
    }

    // MARK: - Apps by Beta Track

    static func apps(for track: BetaTrack) -> [WCSAppProduct] {
        appProducts.filter { $0.betaTrack == track }
    }

    // MARK: - Revenue Validation Questions (from PDF)

    static let revenueValidationQuestions: [String] = [
        "Which segment gets value fastest: family carers, support workers, or organizations?",
        "Which feature drives retention: routines, reminders, reports, or calming activities?",
        "Which message converts best: reduce confusion, save time, or improve consistency?",
        "Which plan feels credible: low-cost consumer subscription or higher-value institutional pilot?",
        "What proof is needed before payment: testimonials, case studies, usage reports, or clinical partner validation?",
    ]

    // MARK: - Success Metrics (from PDF)

    static let successMetrics: [(name: String, description: String)] = [
        ("Activation Rate", "Carers who create the first routine"),
        ("Retention Rate", "Carers still using after 4 and 8 weeks"),
        ("Value Signal Rate", "Testers who click into paid plan interest"),
        ("Pilot Conversion", "Organizations that move from demo to pilot"),
        ("Paid Conversion", "Active users who subscribe after launch"),
    ]

    // MARK: - Content Rhythm (from PDF Section 7.2)

    static let weeklyContentRhythm: [String] = [
        "1 educational blog / article clarifying a problem and solution",
        "1-3 short videos (5-30 seconds) showing micro-features",
        "1 newsletter / LinkedIn update with progress and insights",
        "1 short demo video: routine setup, mood logging, or calming canvas",
    ]

    // MARK: - Email Templates

    static func betaInviteSubject() -> String {
        "Join WCS Beta — Test our apps and shape the future"
    }

    static func betaInviteBody() -> String {
        let appList = appProducts
            .map { "• \($0.name) — \($0.tagline)" }
            .joined(separator: "\n")

        return """
        Hi there,

        We're inviting you to test our suite of apps built by World Class Scholars.

        Apps available on TestFlight:
        \(appList)

        Join our TestFlight beta: \(testFlightURL.absoluteString)
        Browse all apps: \(allAppsURL.absoluteString)

        Your feedback helps us build something genuinely useful.

        Visit us: \(websiteURL.absoluteString)
        Personal: \(personalLinkURL.absoluteString)

        Follow us:
        \(socialLinks.map { "• \($0.name): \($0.url.absoluteString)" }.joined(separator: "\n"))

        Best regards,
        Dr Christopher Appiah-Thompson
        CEO, World Class Scholars
        \(supportEmail)
        """
    }

    static func appShareText(for app: WCSAppProduct) -> String {
        """
        Check out \(app.name) — \(app.tagline)

        Try it on TestFlight: \(app.testFlightLink.absoluteString)
        Learn more: \(app.websitePage.absoluteString)

        Built by @christopherappi | World Class Scholars
        \(personalLinkURL.absoluteString)

        #WCS #\(app.name.replacingOccurrences(of: " ", with: "")) #TestFlight #iOS
        """
    }

    static func weeklyNewsletterTemplate(weekNumber: Int) -> String {
        """
        WCS Weekly Update — Week \(weekNumber)

        What we shipped:
        • [Feature/fix description]

        What we learned:
        • [User feedback insight]

        What's next:
        • [Upcoming improvement]

        Try our apps: \(allAppsURL.absoluteString)
        Follow: \(socialLinks.map { "\($0.name): \($0.handle)" }.joined(separator: " | "))

        — Dr Christopher Appiah-Thompson
        \(personalLinkURL.absoluteString)
        """
    }
}
