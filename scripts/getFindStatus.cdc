import "FIND"
import "Profile"
import "FindRelatedAccounts"
import "NonFungibleToken"
import "MetadataViews"
import "EmeraldIdentity"
import "TokenForwarding"
import "FungibleToken"
//import "Wearables"
import "FindUtils"
import "Clock"
//import "LostAndFound"

access(all) 
struct FINDReport{
    access(all) let isDapper: Bool
    access(all) let profile:Profile.UserReport?
    access(all) let privateMode: Bool
    access(all) let activatedAccount: Bool
    access(all) let hasLostAndFoundItem: Bool
    access(all) let accounts : [AccountInformation]?
    //not sure
    access(all) let readyForWearables : Bool?

    init(profile: Profile.UserReport?,
    privateMode: Bool,
    activatedAccount: Bool,
    isDapper: Bool,
    hasLostAndFoundItem: Bool,
    accounts: [AccountInformation]?,
    readyForWearables: Bool?
) {

    self.hasLostAndFoundItem=hasLostAndFoundItem
    self.profile=profile
    self.privateMode=privateMode
    self.activatedAccount=activatedAccount
    self.isDapper=isDapper
    self.accounts=accounts
    self.readyForWearables=readyForWearables
}
}

access(all) struct AccountInformation {
    access(all) let name: String
    access(all) let address: String
    access(all) let network: String
    access(all) let trusted: Bool
    access(all) let node: String

    init(name: String, address: String, network: String, trusted: Bool, node: String) {
        self.name = name
        self.address = address
        self.network = network
        self.trusted = trusted
        self.node = node
    }
}


access(all) 
fun main(user: String) : FINDReport? {

    let maybeAddress=FIND.resolve(user)
    if maybeAddress == nil{
        return nil
    }

    let address=maybeAddress!

    //why not auth account here?
    let account=getAccount(address)
    if account.balance == 0.0 {
        return nil
    }


    var isDapper=false
    if let receiver =account.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver) {
        isDapper=receiver.isInstance(Type<@TokenForwarding.Forwarder>())
    } else {
        if let duc = account.capabilities.borrow<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver){
            isDapper = duc.isInstance(Type<@TokenForwarding.Forwarder>())
        } else {
            isDapper = false
        }
    }

    let profile=account.capabilities.borrow<&{Profile.Public}>(Profile.publicPath)
    var profileReport = profile?.asReport()
    if profileReport != nil && profileReport!.findName != FIND.reverseLookup(address) {
        profileReport = Profile.UserReport(
            findName: "",
            address: profileReport!.address,
            name: profileReport!.name,
            gender: profileReport!.gender,
            description: profileReport!.description,
            tags: profileReport!.tags,
            avatar: profileReport!.avatar,
            links: profileReport!.links,
            wallets: profileReport!.wallets,
            following: profileReport!.following,
            followers: profileReport!.followers,
            allowStoringFollowers: profileReport!.allowStoringFollowers,
            createdAt: profileReport!.createdAt
        )
    }

    let discordID = EmeraldIdentity.getDiscordFromAccount(account: address) ?? ""
    //?? EmeraldIdentityDapper.getDiscordFromAccount(account: address)
    //?? EmeraldIdentityLilico.getDiscordFromAccount(account: address)
    //    ?? ""

    let emeraldIDAccounts : {String : Address} = {}
    emeraldIDAccounts["blocto"] = EmeraldIdentity.getAccountFromDiscord(discordID: discordID)
    //   emeraldIDAccounts["lilico"] = EmeraldIdentityLilico.getAccountFromDiscord(discordID: discordID)
    //   emeraldIDAccounts["dapper"] = EmeraldIdentityDapper.getAccountFromDiscord(discordID: discordID)

    let accounts : [AccountInformation] = []
    for wallet in ["blocto", "lilico", "dapper"] {
        if let w = emeraldIDAccounts[wallet] {
            if w == address {
                continue
            }

            accounts.append(
                AccountInformation(
                    name: wallet,
                    address: w.toString(),
                    network: "Flow",
                    trusted: true,
                    node: "EmeraldID")
                )
            }
        }

        if let allAcctsCap = FindRelatedAccounts.getCapability(address) {
            let allAcctsRef = allAcctsCap.borrow()!
            let allAccts = allAcctsRef.getAllRelatedAccountInfo()
            for acct in allAccts.values {
                // We only verify flow accounts that are mutually linked
                var trusted = false
                if acct.address != nil {
                    if acct.address! == address {
                        continue
                    }
                    trusted = allAcctsRef.linked(name: acct.name, network: acct.network, address: acct.address!)
                }
                accounts.append(AccountInformation(
                    name: acct.name,
                    address: acct.stringAddress,
                    network: acct.network,
                    trusted: trusted,
                    node: "FindRelatedAccounts")
                )
            }
        }

        var readyForWearables = false
        var hasLostAndFoundItem : Bool = false
        /*
        let wearablesRef= account.storage.borrow<&Wearables.Collection>(from: Wearables.CollectionStoragePath)
        if wearablesRef == nil {
            readyForWearables = false
        }

        let wearablesCap= account.capabilities.borrow<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Wearables.CollectionPublicPath)
        if wearablesCap == nil {
            readyForWearables = false
        }

        let wearablesProviderCap= account.capabilities.get<&{NonFungibleToken.Provider,NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Wearables.CollectionPrivatePath)
        if !wearablesCap.check() {
            readyForWearables = false
        }

        for t in LostAndFound.getRedeemableTypes(address) {
            if t.isSubtype(of: Type<@NonFungibleToken.NFT>()) {
                hasLostAndFoundItem = true
                break
            }
        }
        */

        return FINDReport(
            profile: profileReport,
            privateMode: profile?.isPrivateModeEnabled() ?? false,
            activatedAccount: true,
            isDapper:isDapper,
            hasLostAndFoundItem: hasLostAndFoundItem,
            accounts: accounts,
            readyForWearables: readyForWearables,
        )
    }

