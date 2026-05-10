import Foundation

struct WCSMarketingConfig {
    static let websiteURL = URL(string: "https://wcs-full.vercel.app")!
    static let supportEmail = "christopher.appiahthompson@myworldclass.org"
    static let pricingPageURL = URL(string: "https://wcs-full.vercel.app/pricing")!
    static let pilotFormURL = URL(string: "https://wcs-full.vercel.app/pilot-request")!
    static let waitlistURL = URL(string: "https://wcs-full.vercel.app/waitlist")!
    static let privacyPolicyURL = URL(string: "https://wcs-full.vercel.app/privacy")!
    static let termsURL = URL(string: "https://wcs-full.vercel.app/terms")!

    // MARK: - Social Media

    static let socialLinks: [(name: String, icon: String, url: URL)] = [
        ("Twitter / X", "bird.fill", URL(string: "https://x.com/WCSCareApp")!),
        ("Instagram", "camera.fill", URL(string: "https://instagram.com/wcscare")!),
        ("LinkedIn", "link.circle.fill", URL(string: "https://linkedin.com/company/worldclass-scholars")!),
        ("Facebook", "person.2.fill", URL(string: "https://facebook.com/WCSCareApp")!),
        ("YouTube", "play.rectangle.fill", URL(string: "https://youtube.com/@WCSCare")!),
        ("TikTok", "music.note", URL(string: "https://tiktok.com/@wcscare")!),
    ]

    // MARK: - Payment & Testing

    static let paymentLinks: [(name: String, url: URL)] = [
        ("Care Pro Monthly ($9.99)", URL(string: "https://wcs-full.vercel.app/pay/care-pro")!),
        ("Care Team Annual (Custom)", URL(string: "https://wcs-full.vercel.app/pay/care-team")!),
        ("Donate / Support Development", URL(string: "https://wcs-full.vercel.app/donate")!),
    ]

    // MARK: - TestFlight

    static let testFlightURL = URL(string: "https://testflight.apple.com/join/WCSCare")!

    static let testFlightApps: [(name: String, bundleId: String, appId: String)] = [
        ("AgedCare-Shared", "wcs.Agedcare-shared", "6767978725"),
        ("carelens-aged+", "wcs.Carelens-Aged-", "6767072418"),
        ("medlingo", "wcs.medlingo", "6766951084"),
        ("Etherealveil", "com.worldclassscholars.etherealveil", "6763116253"),
        ("MemoryCanvas", "com.worldclassscholars.memorycanvas", "6762592097"),
        ("NeuroCanvas", "com.superappmac.neurocanvas", "6762577204"),
        ("WCS-Platform", "wcs.WCS-Platform", "6763751751"),
        ("WCSLIB", "wcs.WCSLIB", "6764653278"),
        ("build-space", "com.wcs.neurocanvas", "6762591870"),
        ("GeoWCS", "com.wcs.GeoWCS", "6761536110"),
        ("Equity Kombat", "com.wcs.equity-kombat", "6761084713"),
        ("Wendy'SAfricanFash", "wcs.AfricanFashionApp", "6763326670"),
    ]

    // MARK: - Email Templates

    static func betaInviteSubject() -> String {
        "Join WCS Care Beta — Help shape the future of aged care"
    }

    static func betaInviteBody() -> String {
        """
        Hi there,

        We're inviting you to test WCS Care — an app designed to reduce confusion, \
        save time, and bring consistency to daily care routines.

        Join our TestFlight beta: \(testFlightURL.absoluteString)

        What you get:
        • Daily routines & reminders
        • Mood & wellbeing tracking
        • AI-powered fall detection & monitoring
        • Real-time alerts for care teams

        Your feedback helps us build something genuinely useful for carers \
        and the people they support.

        Visit us: \(websiteURL.absoluteString)

        Best regards,
        WCS Care Team
        \(supportEmail)
        """
    }
}
