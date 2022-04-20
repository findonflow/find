import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main(alias: String) : NFTRegistry.NFTInfo?{

    return NFTRegistry.getNFTInfoByAlias(alias)

}