import "PublicPriceOracle" 

// oracleAddress => oracleTag
access(all) fun main(): {Address: String} {
    return PublicPriceOracle.getAllSupportedOracles()
}
