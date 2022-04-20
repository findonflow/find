import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main(typeIdentifier: String) : NFTRegistry.NFTInfo? {

    return NFTRegistry.getNFTInfoByTypeIdentifier(typeIdentifier)

}