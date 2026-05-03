package com.amandev.tracke

object NotificationFilters {

    // Initial seed. Tunable on real devices.
    // Keep small and explicit so the Play disclosure stays defensible.
    private val ALLOWLIST: Set<String> = setOf(
        // India banks
        "com.snapwork.hdfc",
        "com.csam.icici.bank.imobile",
        "com.sbi.SBIFreedomPlus",
        "com.axis.mobile",
        "com.kotak.kotakmb",

        // India payments / wallets
        "com.google.android.apps.nbu.paisa.user",
        "com.phonepe.app",
        "net.one97.paytm",
        "in.amazon.mShop.android.shopping",
        "com.dreamplug.androidapp",

        // KSA banks
        "com.ARB.AlRajhiBankRetail",
        "com.alahli.alahliMobileBanking",
        "com.riyadbank.banking",
        "sa.alinma.app",
    )

    private val MONEY_PATTERN = Regex(
        pattern = "(rs\\.?|inr|sar|aed|usd|eur|gbp|₹|﷼|\\$)\\s*[\\d,]+(\\.\\d+)?",
        option = RegexOption.IGNORE_CASE,
    )

    private val TRANSACTION_KEYWORDS = Regex(
        pattern = "\\b(debited|credited|spent|paid|purchase|withdrawn|debit of|charged|txn|upi|atm|pos|card used|sent to|received from)\\b",
        option = RegexOption.IGNORE_CASE,
    )

    private val SECURITY_NOISE = Regex(
        pattern = "\\b(otp|verification code|sign[- ]?in|login|2fa|one[- ]time password|do not share)\\b",
        option = RegexOption.IGNORE_CASE,
    )

    fun isAllowlistedPackage(pkg: String): Boolean = ALLOWLIST.contains(pkg)

    fun looksTransactional(text: String): Boolean {
        if (text.isBlank()) return false
        return TRANSACTION_KEYWORDS.containsMatchIn(text) &&
                MONEY_PATTERN.containsMatchIn(text)
    }

    fun isSecurityNoise(text: String): Boolean {
        if (text.isBlank()) return false
        return SECURITY_NOISE.containsMatchIn(text)
    }
}
