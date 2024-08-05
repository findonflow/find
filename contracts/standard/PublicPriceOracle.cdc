/**

# This contract provides public oracle data sourced from the multi-node PriceOracle contracts of Increment.

# Anyone can access price data directly with getLatestPrice() & getLatestBlockHeight(), no whitelist needed. Check example here: https://docs.increment.fi/protocols/decentralized-price-feed-oracle/using-price-feeds

# Admin controls what PriceOracles are exposed publicly.

# Author: Increment Labs

THIS is a local stub for testing
*/


access(all) contract PublicPriceOracle {

    access(all) view fun getLatestPrice(oracleAddr: Address): UFix64 {
        return 0.5
    }

    /// Get the block height at the time of the latest update.
    ///
    access(all) view fun getLatestBlockHeight(oracleAddr: Address): UInt64 {
        return getCurrentBlock().height
    }


}
