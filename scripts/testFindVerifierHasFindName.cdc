import FindVerifier from "../contracts/FindVerifier.cdc"

pub fun main(user: Address, findNames: [String]) : Bool {
    let verifier = FindVerifier.HasFINDName(findNames)
    let input : {String : AnyStruct} = {"address" : user}
    return verifier.verify(input)
}