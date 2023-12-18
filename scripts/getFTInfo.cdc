import FTRegistry from "../contracts/FTRegistry.cdc"

access(all) main(aliasOrIdentifier: String) : FTRegistry.FTInfo?{

    return FTRegistry.getFTInfo(aliasOrIdentifier)

}
