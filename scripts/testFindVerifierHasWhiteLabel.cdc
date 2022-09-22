import FindVerifier from "../contracts/FindVerifier.cdc"

pub fun main(user: Address, addresses: [Address]) : Bool {
    let verifier = FindVerifier.HasWhiteLabel(addresses)
    let input : {String : AnyStruct} = {"address" : user}
    return verifier.verify(input)
}