import FTRegistry from "../contracts/FTRegistry.cdc"

pub fun main(typeIdentifier: String) : FTRegistry.FTInfo?{

    return FTRegistry.getFTInfoByTypeIdentifier(typeIdentifier)

}
