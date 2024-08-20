import "FindVerifier"

access(all) fun main(user: Address, findNames: [String]) : Result {
    let verifier = FindVerifier.HasFINDName(findNames)
    let input : {String : AnyStruct} = {"address" : user}
    return Result(verifier, input: input)
}

access(all) struct Result{
    access(all) let result : Bool 
    access(all) let description : String 

    init(_ v : {FindVerifier.Verifier}, input: {String : AnyStruct}) {
        self.result=v.verify(input)
        self.description=v.description
    }
}
