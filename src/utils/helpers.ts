// Helper function to convert network names to chain IDs
export function getChainId(networkNameOrId: string): string {
  // If it's already a numeric chain ID, return it
  if (/^\d+$/.test(networkNameOrId)) {
    return networkNameOrId;
  }
  
  // Map common network names to chain IDs
  const networkMap: Record<string, string> = {
    // Main networks
    "ethereum": "1",
    "eth": "1",
    "mainnet": "1",
    "optimism": "10",
    "op": "10",
    "bnb": "56",
    "bsc": "56",
    "binance": "56",
    "gnosis": "100",
    "xdai": "100",
    "polygon": "137",
    "matic": "137",
    "fantom": "250",
    "ftm": "250",
    "base": "8453",
    "arbitrum": "42161",
    "arb": "42161",
    "avalanche": "43114",
    "avax": "43114",
    
    // Testnets
    "sepolia": "11155111",
    "goerli": "5",
    "mumbai": "80001",
    "bsc-testnet": "97",
    "fuji": "43113",
    "arbitrum-goerli": "421613",
    "optimism-goerli": "420",
    "base-goerli": "84531"
  };
  
  const normalized = networkNameOrId.toLowerCase().replace(/[\s-_]/g, "");
  return networkMap[normalized] || networkNameOrId;
}

// Helper function to get network name from chain ID
export function getNetworkName(chainId: string): string {
  const chainNames: Record<string, string> = {
    "1": "Ethereum",
    "10": "Optimism",
    "56": "BNB Smart Chain",
    "100": "Gnosis",
    "137": "Polygon",
    "250": "Fantom",
    "8453": "Base",
    "42161": "Arbitrum",
    "43114": "Avalanche",
    "11155111": "Sepolia",
    "5": "Goerli",
    "80001": "Mumbai",
    "97": "BSC Testnet",
    "43113": "Fuji",
    "421613": "Arbitrum Goerli",
    "420": "Optimism Goerli",
    "84531": "Base Goerli"
  };
  
  return chainNames[chainId] || `Chain ${chainId}`;
}

// Helper function to determine wallet type
export function determineWalletType(txPatterns: any, portfolio: any): string {
  if (portfolio.nftCount > portfolio.tokenCount * 0.5) return "NFT Collector";
  if (portfolio.defiTokens > 2) return "DeFi User";
  if (txPatterns.contractInteractions > txPatterns.totalTransactions * 0.7) return "Smart Contract Power User";
  if (portfolio.stablecoins > portfolio.tokenCount * 0.5) return "Stablecoin Holder";
  if (txPatterns.totalTransactions < 10) return "New/Inactive Wallet";
  return "General User";
}

// Helper function to determine primary wallet use
export function determinePrimaryUse(txPatterns: any, portfolio: any): string {
  const uses = [];
  if (portfolio.nftCount > 0) uses.push("NFT Trading");
  if (portfolio.defiTokens > 0) uses.push("DeFi");
  if (portfolio.stablecoins > 0) uses.push("Stablecoin Transactions");
  if (txPatterns.contractInteractions > 10) uses.push("dApp Interactions");
  if (uses.length === 0) uses.push("Basic Transfers");
  return uses.join(", ");
}