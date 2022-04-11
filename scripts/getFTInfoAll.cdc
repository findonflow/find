import FTRegistry from "../contracts/FTRegistry.cdc"

pub fun main() : {String: FTRegistry.FTInfo}{

    return FTRegistry.getFTInfoAll()

}
