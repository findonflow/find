import NFTRegistry from "../contracts/NFTRegistry.cdc"

access(all) fun main(aliasOrIdentifier: String) : NFTRegistry.NFTInfo? {

    return NFTRegistry.getNFTInfo(aliasOrIdentifier)

}