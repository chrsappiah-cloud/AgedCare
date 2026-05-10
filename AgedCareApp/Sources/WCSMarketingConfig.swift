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

struct WCSMarketingConfig {

    // MARK: - Core URLs

    static let websiteURL = URL(string: "https://wcs-full.vercel.app")!
    static let supportEmail = "christopher.appiahthompson@myworldclass.org"
    static let pricingPageURL = URL(string: "https://wcs-full.vercel.app/pricing")!
    static let pilotFormURL = URL(string: "https://wcs-full.vercel.app/pilot-request")!
    static let waitlistURL = URL(string: "https://wcs-full.vercel.app/waitlist")!
    static let privacyPolicyURL = URL(string: "https://wcs-full.vercel.app/privacy")!
    static let termsURL = URL(string: "https://wcs-full.vercel.app/terms")!
    static let allAppsURL = URL(string: "https://wcs-full.vercel.app/apps")!
    static let donateURL = URL(string: "https://wcs-full.vercel.app/donate")!
    static let testFlightURL = URL(string: "https://testflight.apple.com/join/WCSCare")!

    // MARK: - Social Media

    static let socialLinks: [(name: String, icon: String, url: URL, handle: String)] = [
        ("Twitter / X", "bird.fill", URL(string: "https://x.com/WCSCareApp")!, "@WCSCareApp"),
        ("Instagram", "camera.fill", URL(string: "https://instagram.com/wcscare")!, "@wcscare"),
        ("LinkedIn", "link.circle.fill", URL(string: "https://linkedin.com/company/worldclass-scholars")!, "worldclass-scholars"),
        ("Facebook", "person.2.fill", URL(string: "https://facebook.com/WCSCareApp")!, "WCSCareApp"),
        ("YouTube", "play.rectangle.fill", URL(string: "https://youtube.com/@WCSCare")!, "@WCSCare"),
        ("TikTok", "music.note", URL(string: "https://tiktok.com/@wcscare")!, "@wcscare"),
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
            platform: "iOS"
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
            platform: "iOS"
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
            platform: "iOS"
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
            platform: "iOS"
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
            platform: "iOS"
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
            platform: "iOS + macOS"
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
            platform: "iOS + macOS"
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
            platform: "iOS"
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
            platform: "iOS"
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
            platform: "iOS"
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
            platform: "iOS"
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
            platform: "iOS"
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

        Follow us:
        \(socialLinks.map { "• \($0.name): \($0.url.absoluteString)" }.joined(separator: "\n"))

        Best regards,
        WCS Team
        \(supportEmail)
        """
    }

    static func appShareText(for app: WCSAppProduct) -> String {
        """
        Check out \(app.name) — \(app.tagline)

        Try it on TestFlight: \(app.testFlightLink.absoluteString)
        Learn more: \(app.websitePage.absoluteString)

        #WCS #\(app.name.replacingOccurrences(of: " ", with: "")) #TestFlight #iOS
        """
    }
}
