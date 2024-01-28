import FTRegistry from "../contracts/FTRegistry.cdc"

access(all) fun main() : {String: FTRegistry.FTInfo}{

    return FTRegistry.getFTInfoAll()

}
