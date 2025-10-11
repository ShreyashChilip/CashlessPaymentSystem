class WalletValidator {
  static bool isValidSolanaAddress(String address) {
    if (address.isEmpty) return false;
    // Solana addresses are Base58 encoded and typically 32-44 characters
    RegExp solanaAddressRegex = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$');
    return solanaAddressRegex.hasMatch(address);
  }

  // Helper method to check if string is Base58
  static bool isBase58(String value) {
    RegExp base58Regex = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
    return base58Regex.hasMatch(value);
  }
}
