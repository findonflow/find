import "FindVerifier"
import "MetadataViews"

access(all) fun main(user: Address, path: String, rarityA: Bool, rarityB: Bool) : Result {

    let rarities : [MetadataViews.Rarity] = []

    if rarityA {
        rarities.append(MetadataViews.Rarity(score: 1.0, max: 2.0, description: "rarity description"))
    }

    if rarityB {
        rarities.append(MetadataViews.Rarity(score: 1.0, max: 2.0, description: "fake rarity"))
    }

    let verifier = FindVerifier.HasNFTWithRarities(path: PublicPath(identifier: path)!, rarities: rarities)
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
