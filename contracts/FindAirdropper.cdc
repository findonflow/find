import "NonFungibleToken"
import "FIND"
import "FungibleToken"
import "FlowToken"
import "FindMarket"
import "FindViews"
import "FindLostAndFoundWrapper"
import "MetadataViews"

access(all) contract FindAirdropper {
    // Events
    access(all) event Airdropped(from: Address ,fromName: String?, to: Address, toName: String?,uuid: UInt64, nftInfo: FindMarket.NFTInfo, context: {String : String}, remark: String?)
    access(all) event AirdroppedToLostAndFound(from: Address, fromName: String? , to: Address, toName: String?, uuid: UInt64, nftInfo: FindMarket.NFTInfo, context: {String : String}, remark: String?, ticketID: UInt64)
    access(all) event AirdropFailed(from: Address, fromName: String? , to: Address, toName: String?, uuid: UInt64, id: UInt64, type: String, context: {String : String}, reason: String)

    // The normal way of airdrop. If the user didn't init account, they cannot receive it
    access(all) fun safeAirdrop(pointer: FindViews.AuthNFTPointer, receiver: Address, path: PublicPath, context: {String : String}, deepValidation: Bool) {
        let toName = FIND.reverseLookup(receiver)
        let from = pointer.owner()
        let fromName = FIND.reverseLookup(from)
        if deepValidation && !pointer.valid() {
            emit AirdropFailed(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier,  context: context, reason: "Invalid NFT Pointer")
            return
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        let receiverCap = getAccount(receiver).capabilities.get<&{NonFungibleToken.Receiver}>(path)
        // calculate the required storage and check sufficient balance
        let senderStorageBeforeSend = getAccount(from).storage.used

        let item <- pointer.withdraw()

        let requiredStorage = senderStorageBeforeSend - getAccount(from).storage.used
        let receiverAvailableStorage = getAccount(receiver).storage.capacity - getAccount(receiver).storage.used
        // If requiredStorage > receiverAvailableStorage, deposit will not be successful, we will emit fail event and deposit back to the sender's collection
        if receiverAvailableStorage < requiredStorage {
            emit AirdropFailed(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Insufficient User Storage")
            pointer.deposit(<- item)
            return
        }

        if  receiverCap.check() {
            emit Airdropped(from: from , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: nil)
            receiverCap.borrow()!.deposit(token: <- item)
            return
        } else {
            let collectionPublic = getAccount(receiver).capabilities.borrow<&{NonFungibleToken.Collection}>(path)
            if collectionPublic !=nil {

                let from = pointer.owner()
                emit Airdropped(from: from , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid,  nftInfo: nftInfo, context: context, remark: "Receiver Not Linked")

                collectionPublic!.deposit(token: <- item)
                return
            }
        }

        emit AirdropFailed(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Invalid Receiver Capability")
        pointer.deposit(<- item)
    }

    access(all) fun forcedAirdrop(pointer: FindViews.AuthNFTPointer, receiver: Address, path: PublicPath, context: {String : String}, storagePayment: auth(FungibleToken.Withdraw) &{FungibleToken.Vault}, flowTokenRepayment: Capability<&{FungibleToken.Receiver}>, deepValidation: Bool) {

        let toName = FIND.reverseLookup(receiver)
        let from = pointer.owner()
        let fromName = FIND.reverseLookup(from)

        if deepValidation && !pointer.valid() {
            emit AirdropFailed(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Invalid NFT Pointer")
            return
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        // use LostAndFound for dropping
        let ticketID = FindLostAndFoundWrapper.depositNFT(
            receiver: receiver,
            collectionPublicPath: path,
            item: pointer,
            memo: context["message"],
            storagePayment: storagePayment,
            flowTokenRepayment: flowTokenRepayment,
            subsidizeReceiverStorage: false
        )

        if ticketID == nil {
            emit Airdropped(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: nil)
            return
        }
        emit AirdroppedToLostAndFound(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: nil, ticketID: ticketID!)
    }

    access(all) fun subsidizedAirdrop(pointer: FindViews.AuthNFTPointer, receiver: Address, path: PublicPath, context: {String : String}, storagePayment: auth(FungibleToken.Withdraw) &{FungibleToken.Vault}, flowTokenRepayment: Capability<&{FungibleToken.Receiver}>, deepValidation: Bool) {

        let toName = FIND.reverseLookup(receiver)
        let from = pointer.owner()
        let fromName = FIND.reverseLookup(from)

        if deepValidation && !pointer.valid() {
            emit AirdropFailed(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Invalid NFT Pointer")
            return
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        let receiverCap = getAccount(receiver).capabilities.get<&{NonFungibleToken.Receiver}>(path)

        // use LostAndFound for dropping
        let ticketID = FindLostAndFoundWrapper.depositNFT(
            receiver: receiver,
            collectionPublicPath: path,
            item: pointer,
            memo: context["message"],
            storagePayment: storagePayment,
            flowTokenRepayment: flowTokenRepayment,
            subsidizeReceiverStorage: true
        )

        if ticketID == nil {
            emit Airdropped(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: nil)
            return
        }
        emit AirdroppedToLostAndFound(from: pointer.owner() , fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid,  nftInfo: nftInfo, context: context, remark: nil, ticketID: ticketID!)
    }
}

