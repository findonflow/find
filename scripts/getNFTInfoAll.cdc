import NFTRegistry from "../contracts/NFTRegistry.cdc"

access(all) fun main() : {String: NFTRegistry.NFTInfo}{

    return NFTRegistry.getNFTInfoAll()

}