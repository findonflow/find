import NFTRegistry from "../contracts/NFTRegistry.cdc"

access(all) main(aliasOrIdentifier: String) : NFTRegistry.NFTInfo? {

    return NFTRegistry.getNFTInfo(aliasOrIdentifier)

}