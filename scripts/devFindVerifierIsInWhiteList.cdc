import FindVerifier from "../contracts/FindVerifier.cdc"

access(all) main(user: Address, addresses: [Address]) : Result {
    let verifier = FindVerifier.IsInWhiteList(addresses)
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