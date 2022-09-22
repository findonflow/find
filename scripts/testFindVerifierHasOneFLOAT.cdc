import FindVerifier from "../contracts/FindVerifier.cdc"

pub fun main(user: Address, floatIDs: [UInt64]) : Bool {
    let verifier = FindVerifier.HasOneFLOAT(floatIDs)
    let input : {String : AnyStruct} = {"address" : user}
    return verifier.verify(input)
}