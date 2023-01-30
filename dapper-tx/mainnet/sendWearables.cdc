import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import FindViews from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef
import FindAirdropper from 0x097bafa4e0b48eef
import Wearables from 0xe81193c424cfd3fb

transaction(allReceivers: [String] , ids:[UInt64], memos: [String]) {

    let authPointers : [FindViews.AuthNFTPointer]

    prepare(account : AuthAccount) {

        self.authPointers = []
        let privatePath = Wearables.CollectionPrivatePath
        let storagePath = Wearables.CollectionStoragePath

        for id in ids {

            var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(privatePath)
            if !providerCap.check() {
                let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                    privatePath,
                    target: storagePath
                )
                if newCap == nil {
                    // If linking is not successful, we link it using finds custom link
                    let pathIdentifier = privatePath.toString()
                    let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
                    account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                        findPath,
                        target: storagePath
                    )
                    providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
                }
            }
            let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: id)

            self.authPointers.append(pointer)
        }

    }

    execute {
        let addresses : {String : Address} = {}
        let publicPath = Wearables.CollectionPublicPath

        let ctx : {String : String} = {
            "tenant" : "find"
        }

        for i,  pointer in self.authPointers {
            let receiver = allReceivers[i]
            let id = ids[i]
            ctx["message"] = memos[i]

            var user = addresses[receiver]
            if user == nil {
                user = FIND.resolve(receiver) ?? panic("Cannot resolve user with name / address : ".concat(receiver))
                addresses[receiver] = user
            }

            // airdrop thru airdropper
            FindAirdropper.safeAirdrop(pointer: pointer, receiver: user!, path: publicPath, context: ctx, deepValidation: true)
        }

    }
}
