import FTRegistry from "../contracts/FTRegistry.cdc"

pub fun main(alias: String) : FTRegistry.FTInfo? {

    return FTRegistry.getFTInfoByAlias(alias)
    
}
