import '../../core/ingestion/raw_txn_signal.dart';

/// Notification-shaped fixtures used by [ParserTest] for smoke testing
/// the 5-layer parser. Intentionally small — the full corpus harness
/// is out of scope for the current pivot.
final List<RawTxnSignal> mockNotifications = [
  // ---------- INDIA UPI ----------
  RawTxnSignal(
    source: 'notification',
    sender: 'com.snapwork.hdfc',
    title: 'HDFC Bank',
    body:
        'Rs.250 spent on UPI at SWIGGY@okaxis on 03-May-26. Avl bal: Rs 12,304.10',
    timestamp: 1714472000,
    matchedBy: 'allowlist',
  ),
  RawTxnSignal(
    source: 'notification',
    sender: 'com.csam.icici.bank.imobile',
    title: 'iMobile',
    body: 'INR 149 paid to spotifyindia@okhdfcbank via UPI. Ref 938201733.',
    timestamp: 1714473000,
    matchedBy: 'allowlist',
  ),

  // ---------- INDIA CARD ----------
  RawTxnSignal(
    source: 'notification',
    sender: 'com.snapwork.hdfc',
    title: 'HDFC Bank',
    body: 'Your Card XX1234 is used for INR 2199 at AMAZON SELLER SERVICES.',
    timestamp: 1714474000,
    matchedBy: 'allowlist',
  ),
  RawTxnSignal(
    source: 'notification',
    sender: 'com.csam.icici.bank.imobile',
    title: 'ICICI Bank',
    body: 'Debit Card XX2221 used at DOMINOS BANGALORE for Rs.499',
    timestamp: 1714475000,
    matchedBy: 'allowlist',
  ),

  // ---------- KSA ----------
  RawTxnSignal(
    source: 'notification',
    sender: 'com.ARB.AlRajhiBankRetail',
    title: 'Al Rajhi Bank',
    body: 'Debit of SAR 25.00 at Carrefour Hyper. Available balance SAR 300',
    timestamp: 1714476000,
    matchedBy: 'allowlist',
  ),
  RawTxnSignal(
    source: 'notification',
    sender: 'com.alahli.alahliMobileBanking',
    title: 'SNB',
    body: 'SAR 19.50 spent at Starbucks Coffee Riyadh',
    timestamp: 1714477000,
    matchedBy: 'allowlist',
  ),

  // ---------- HEURISTIC PATH (unknown bank app) ----------
  RawTxnSignal(
    source: 'notification',
    sender: 'com.example.someregionalwallet',
    title: 'Wallet',
    body: 'You spent Rs 89 at ALBK FOOD #443. Balance Rs 411.20',
    timestamp: 1714478500,
    matchedBy: 'heuristic',
  ),

  // ---------- SHOULD REJECT ----------
  RawTxnSignal(
    source: 'notification',
    sender: 'com.amazon.shopping',
    title: 'Amazon',
    body: '123456 is your OTP. Do not share.',
    timestamp: 1714478000,
    matchedBy: 'heuristic',
  ),
  RawTxnSignal(
    source: 'notification',
    sender: 'com.snapwork.hdfc',
    title: 'HDFC Bank',
    body: 'A/c credited with Rs 1000.',
    timestamp: 1714479000,
    matchedBy: 'allowlist',
  ),
  RawTxnSignal(
    source: 'notification',
    sender: 'com.csam.icici.bank.imobile',
    title: 'iMobile',
    body: 'You are eligible for a personal loan.',
    timestamp: 1714480000,
    matchedBy: 'allowlist',
  ),
  RawTxnSignal(
    source: 'notification',
    sender: 'com.phonepe.app',
    title: 'PhonePe',
    body: 'Rs.1800 will be debited on approval.',
    timestamp: 1714481000,
    matchedBy: 'allowlist',
  ),
];
