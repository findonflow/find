import FTRegistry from "../contracts/FTRegistry.cdc"

pub fun main(alias: String) : FTRegistry.FTInfo?{

    if let typeIdentifier = FTRegistry.getTypeIdentifier(alias: alias) {
        return FTRegistry.getFTInfo(typeIdentifier: typeIdentifier)
    }

    return nil
}
