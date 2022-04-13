import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main(name: String) : NFTRegistry.NFTInfo?{

    if let typeIdentifier = NFTRegistry.getTypeIdentifier(name: name) {
        return NFTRegistry.getNFTInfo(typeIdentifier: typeIdentifier)
    }

    return nil
}