import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) fun main(user: String) : Report {

    if let address = FIND.resolve(user){
        let type : Type = Type<@NonFungibleToken.NFT>()
        return Report(nftTypes: typeToStringArray(FindLostAndFoundWrapper.getSpecificRedeemableTypes(user: address, specificType: type)), err: nil)
    }
    return logErr("cannot resolve user")

}

access(all) typeToStringArray(_ array: [Type]) : [String] {
    let res : [String] = []
    for type in array {
        res.append(type.identifier)
    }
    return res
}

access(all) struct Report {
    access(all) let nftTypes : [String]
    access(all) let err : String? 

    init(nftTypes : [String] , err : String? ) {
        self.nftTypes = nftTypes
        self.err = err
    }
}

access(all) logErr(_ err: String) : Report{
    return Report(nftTypes: [], err: err)
}