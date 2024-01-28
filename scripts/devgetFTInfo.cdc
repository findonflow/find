import FTRegistry from "../contracts/FTRegistry.cdc"

access(all) fun main(aliasOrIdentifier: String) : FTRegistry.FTInfo?{

    return FTRegistry.getFTInfo(aliasOrIdentifier)

}
