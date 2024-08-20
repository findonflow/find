import "FindThoughts"
import "MetadataViews"
import "FindViews"
import "FindMarket"
import "Profile"
import "FIND"

access(all) fun main(address: Address) : [Thought] {
    let thoughts : [Thought] = [] 

    let account = getAccount(address) 
    if let ref = account.capabilities.borrow<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath) {
        let a = ref as! &FindThoughts.Collection
        for id in a.getIDs() {
            let t = ref.borrowThoughtPublic(id) 
            thoughts.append(getThought(t, withQuote: true))
        }

    }
    return thoughts
}

access(all) struct User {
    access(all) var name: String?
    access(all) let address: Address 
    access(all) let findName: String? 
    access(all) var avatar: String? 
    access(all) let reaction: String

    init(address: Address, reaction: String){
        self.name = nil
        self.findName = FIND.reverseLookup(address)
        self.avatar = nil
        self.reaction = reaction
        self.address = address 
        if let p = getAccount(address).capabilities.borrow<&{Profile.Public}>(Profile.publicPath) {
            self.name = p.getName()
            self.avatar = p.getAvatar()
        }
    }
}

access(all) struct Thought {
    access(all) let id: UInt64 
    access(all) let creator: Address 
    access(all) let creatorName: String? 
    access(all) var creatorProfileName: String? 
    access(all) var creatorAvatar: String? 
    access(all) var header: String?
    access(all) var body: String?
    access(all) let created: UFix64? 
    access(all) var lastUpdated: UFix64?
    access(all) let medias: {String : String}
    access(all) let nft: [FindMarket.NFTInfo]
    access(all) var tags: [String]
    access(all) var reacted: {String : [User]}
    access(all) var reactions: {String : Int}
    access(all) var reactedUsers: {String : [String]}
    access(all) var quotedThought: Thought?
    access(all) var hidden: Bool?

    init(id: UInt64 , creator: Address , creatorName: String? , creatorProfileName: String? , creatorAvatar: String? , header: String? , body: String? , created: UFix64? , lastUpdated: UFix64?, medias: {String : String}, nft: [FindMarket.NFTInfo], tags: [String], reacted: {String : [User]}, reactions: {String : Int}, reactedUsers: {String : [String]}, quotedThought: Thought?, hidden: Bool?) {
        self.id = id
        self.creator = creator
        self.creatorName = creatorName
        self.creatorProfileName = creatorProfileName
        self.creatorAvatar = creatorAvatar
        self.header = header
        self.body = body
        self.created = created
        self.lastUpdated = lastUpdated
        self.medias = medias
        self.nft = nft
        self.tags = tags
        self.reacted = reacted
        self.reactions = reactions
        self.reactedUsers = reactedUsers
        self.quotedThought = quotedThought
        self.hidden = hidden
    }
}

access(all) fun getThought(_ t: &{FindThoughts.ThoughtPublic}, withQuote: Bool) : Thought {

    var creatorProfileName : String? = nil
    var creatorAvatar : String? = nil 
    if let profile = getAccount(t.creator).capabilities.borrow<&{Profile.Public}>(Profile.publicPath) {
        creatorProfileName = profile.getName()
        creatorAvatar = profile.getAvatar()
    }

    let medias : {String : String} = {}
    for m in t.medias {
        medias[m.file.uri()] = m.mediaType
    }

    let nft : [FindMarket.NFTInfo] = [] 
    let nftLength = t.getNFTS().length
    for n in t.nft {
        let vr = n.getViewResolver() 
        nft.append(FindMarket.NFTInfo(vr, id: n.id, detail: true))
    }

    let reacted : {String : [User]} = {}
    let reactedUsers : {String :[String]} = {}
    for user in t.reacted.keys {
        let reaction = t.reacted[user]!
        let allReacted = reacted[reaction] ?? []
        let u = User(address: user, reaction: reaction)

        allReacted.append(u)
        reacted[reaction] = allReacted

        let preReactedUser = reactedUsers[reaction] ?? []
        preReactedUser.append(u.name ?? u.address.toString())
        reactedUsers[reaction] = preReactedUser
    }

    var quotedThought : Thought? = nil 
    if withQuote {
        if let p = t.getQuotedThought() {
            if let ref = p.borrowThoughtPublic() {
                quotedThought = getThought(ref, withQuote: false)
            } else {
                let creator = p.owner()
                var qCreatorProfileName : String? = nil
                var qCreatorAvatar : String? = nil 
                if let qProfile = getAccount(creator).capabilities.borrow<&{Profile.Public}>(Profile.publicPath) {
                    qCreatorProfileName = qProfile.getName()
                    qCreatorAvatar = qProfile.getAvatar()
                }

                quotedThought = Thought(
                    id: p.id , 
                    creator: creator  , 
                    creatorName: FIND.reverseLookup(creator) , 
                    creatorProfileName: qCreatorProfileName , 
                    creatorAvatar: qCreatorAvatar, 
                    header: nil, 
                    body: nil , 
                    created: nil, 
                    lastUpdated: nil, 
                    medias: {}, 
                    nft: [], 
                    tags: [], 
                    reacted: {}, 
                    reactions: {}, 
                    reactedUsers: {},
                    quotedThought: nil, 
                    hidden: nil
                )
            }
        }
    }

    return Thought(
        id: t.id , 
        creator: t.creator  , 
        creatorName: FIND.reverseLookup(t.creator) , 
        creatorProfileName: creatorProfileName , 
        creatorAvatar: creatorAvatar, 
        header: t.header , 
        body: t.body , 
        created: t.created, 
        lastUpdated: t.lastUpdated, 
        medias: medias, 
        nft: nft, 
        tags: t.getTags(), 
        reacted: reacted, 
        reactions: t.getReactions(), 
        reactedUsers: reactedUsers,
        quotedThought: quotedThought,
        hidden: t.getHide()
    )

}
