import FTRegistry from "../contracts/FTRegistry.cdc"

access(all) main() : {String: FTRegistry.FTInfo}{

    return FTRegistry.getFTInfoAll()

}
