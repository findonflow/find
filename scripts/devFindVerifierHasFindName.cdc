import FindVerifier from "../contracts/FindVerifier.cdc"

pub fun main(user: Address, findNames: [String]) : Result {
    let verifier = FindVerifier.HasFINDName(findNames)
    let input : {String : AnyStruct} = {"address" : user}
    return Result(verifier, input: input)
}

pub struct Result{
    pub let result : Bool 
    pub let description : String 

    init(_ v : {FindVerifier.Verifier}, input: {String : AnyStruct}) {
        self.result=v.verify(input)
        self.description=v.description
    }
}