import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main(aliasOrIdentifier: String) : NFTRegistry.NFTInfo? {

    return NFTRegistry.getNFTInfo(aliasOrIdentifier)

}