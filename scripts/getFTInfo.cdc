import FTRegistry from "../contracts/FTRegistry.cdc"

pub fun main(aliasOrIdentifier: String) : FTRegistry.FTInfo?{

    return FTRegistry.getFTInfo(aliasOrIdentifier)

}
