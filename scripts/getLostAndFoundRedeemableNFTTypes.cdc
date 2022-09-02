import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String) : Report {

    if let address = FIND.resolve(user){
        let type : Type = Type<@NonFungibleToken.NFT>()
        return Report(nftTypes: typeToStringArray(FindLostAndFoundWrapper.getSpecificRedeemableTypes(user: address, specificType: type)), err: nil)
    }
    return logErr("cannot resolve user")

}

pub fun typeToStringArray(_ array: [Type]) : [String] {
    let res : [String] = []
    for type in array {
        res.append(type.identifier)
    }
    return res
}

pub struct Report {
    pub let nftTypes : [String]
    pub let err : String? 

    init(nftTypes : [String] , err : String? ) {
        self.nftTypes = nftTypes
        self.err = err
    }
}

pub fun logErr(_ err: String) : Report{
    return Report(nftTypes: [], err: err)
}