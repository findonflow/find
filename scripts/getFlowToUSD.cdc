import "PublicPriceOracle"

access(all) fun main():UFix64? {

    let feeds = PublicPriceOracle.getAllSupportedOracles()
    for address in feeds.keys {

        let name= feeds[address]
        if name=="FLOW/USD" {
            return PublicPriceOracle.getLatestPrice(oracleAddr: address)
        }

    }
    return nil
}

