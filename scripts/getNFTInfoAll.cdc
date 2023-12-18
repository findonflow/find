import NFTRegistry from "../contracts/NFTRegistry.cdc"

access(all) main() : {String: NFTRegistry.NFTInfo}{

    return NFTRegistry.getNFTInfoAll()

}