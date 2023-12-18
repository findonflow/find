import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main() : {String: NFTRegistry.NFTInfo}{

    return NFTRegistry.getNFTInfoAll()

}