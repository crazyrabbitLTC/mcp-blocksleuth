import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { callDuneApi } from "../../utils/api.js";
import { callBlockscoutApi } from "../../utils/api.js";
import { BLOCKSCOUT_NETWORKS } from "../../utils/constants.js";
import { getChainId, getNetworkName } from "../../utils/helpers.js";

export function registerInvestigateSmartContractTool(server: McpServer) {
  server.tool(
  "investigate_smart_contract",
  "Comprehensive smart contract analysis combining real-time data from Blockscout with historical analytics from Dune.",
  {
    contractAddress: z.string().describe("The smart contract address to investigate"),
    chainId: z.string().describe("The chain ID or network name (e.g., '1', 'ethereum', '137', 'polygon')"),
  },
  async ({ contractAddress, chainId }) => {
    try {
      // Convert network name to chain ID if necessary
      const numericChainId = getChainId(chainId);
      const networkName = getNetworkName(numericChainId);
      
      // Fetch data from both sources in parallel
      const [blockscoutInfo, blockscoutMethods, duneTokenInfo] = await Promise.all([
        // Get contract info from Blockscout
        callBlockscoutApi(numericChainId, `/smart-contracts/${contractAddress}`).catch(err => ({ error: err.message })),
        // Get contract methods from Blockscout
        callBlockscoutApi(numericChainId, `/smart-contracts/${contractAddress}/methods-read`)
          .then(readMethods => 
            callBlockscoutApi(numericChainId, `/smart-contracts/${contractAddress}/methods-write`)
              .then(writeMethods => ({ readMethods, writeMethods }))
          )
          .catch(err => ({ error: err.message })),
        // Get token analytics from Dune if available
        callDuneApi(`/v1/evm/token-info/${numericChainId}/${contractAddress}`, new URLSearchParams({ chain_ids: numericChainId }))
          .catch(err => ({ error: err.message }))
      ]) as [any, any, any];

      // Combine the results
      const analysis = {
        contract: {
          address: contractAddress,
          chainId: chainId,
          network: BLOCKSCOUT_NETWORKS[chainId]?.name || `Chain ${chainId}`,
        },
        realTimeData: {
          contractInfo: blockscoutInfo,
          methods: blockscoutMethods,
        },
        analytics: {
          tokenMetrics: duneTokenInfo,
        },
        summary: {
          isVerified: blockscoutInfo?.is_verified || false,
          hasTokenInfo: !duneTokenInfo?.error,
          contractType: blockscoutInfo?.proxy_type || "standard",
          language: blockscoutInfo?.language || "unknown",
        }
      };

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(analysis, null, 2),
          },
        ],
      };
    } catch (error: any) {
      return {
        isError: true,
        content: [{ type: "text", text: `Error analyzing contract: ${error.message}` }],
      };
    }
  }
);
}