import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import FindMarket from "./FindMarket.cdc"
import FindViews from "./FindViews.cdc"
import FindLostAndFoundWrapper from "./FindLostAndFoundWrapper.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"

pub contract FindAirdropper {

    pub event Airdropped(from: Address , to: Address, id: UInt64, uuid: UInt64, type: String, title: String, thumbnail: String, nftInfo: FindMarket.NFTInfo, context: {String : String}, remark: String?)
    pub event AirdroppedToLostAndFound(from: Address , to: Address, id: UInt64, uuid: UInt64, type: String, title: String, thumbnail: String, nftInfo: FindMarket.NFTInfo, context: {String : String}, remark: String?, ticketID: UInt64)
    pub event AirdropFailed(from: Address , to: Address, id: UInt64, uuid: UInt64, type: String, title: String?, thumbnail: String?, nftInfo: FindMarket.NFTInfo?, context: {String : String}, reason: String)

    // The normal way of airdrop. If the user didn't init account, they cannot receive it
    pub fun safeAirdrop(pointer: FindViews.AuthNFTPointer, receiver: Address, path: PublicPath, context: {String : String}) {

        if !pointer.valid() {
            emit AirdropFailed(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nil, thumbnail: nil, nftInfo: nil, context: context, reason: "Invalid NFT Pointer")
            return
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
        let display = pointer.getDisplay()
        let collectionDisplay = MetadataViews.getNFTCollectionDisplay(pointer.getViewResolver())

        let receiverCap = getAccount(receiver).getCapability<&{NonFungibleToken.Receiver}>(path)
        let from = pointer.owner()
        // calculate the required storage and check sufficient balance 
        let senderStorageBeforeSend = getAccount(from).storageUsed

        let item <- pointer.withdraw() 

        let requiredStorage = senderStorageBeforeSend - getAccount(from).storageUsed
        let receiverAvailableStorage = getAccount(receiver).storageCapacity - getAccount(receiver).storageUsed
        // If requiredStorage > receiverAvailableStorage, deposit will not be successful, we will emit fail event and deposit back to the sender's collection
        if receiverAvailableStorage < requiredStorage {
            emit AirdropFailed(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, reason: "Insufficient User Storage")
            pointer.deposit(<- item)
            return
        }

        if receiverCap.check() {

            emit Airdropped(from: from , to: receiverCap.address, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: nil)
            FindLostAndFoundWrapper.emitNFTDepositedEvent(receiver: receiver, sender: from, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType, display: display, collectionDisplay: collectionDisplay, memo: context["message"])

            receiverCap.borrow()!.deposit(token: <- item)
            return 
        } else {
            let collectionPublicCap = getAccount(receiver).getCapability<&{NonFungibleToken.CollectionPublic}>(path)
            if collectionPublicCap.check() {

                let from = pointer.owner()
                emit Airdropped(from: from , to: receiverCap.address, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: "Receiver Not Linked")
                FindLostAndFoundWrapper.emitNFTDepositedEvent(receiver: receiver, sender: from, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType, display: display, collectionDisplay: collectionDisplay, memo: context["message"])

                collectionPublicCap.borrow()!.deposit(token: <- item)
                return 
            }
        }
    
        emit AirdropFailed(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, reason: "Invalid Receiver Capability")
        pointer.deposit(<- item)
    }

    pub fun forcedAirdrop(pointer: FindViews.AuthNFTPointer, receiver: Address, path: PublicPath, context: {String : String}, storagePayment: &FungibleToken.Vault, flowTokenRepayment: Capability<&FlowToken.Vault{FungibleToken.Receiver}>) {
        if !pointer.valid() {
            emit AirdropFailed(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nil, thumbnail: nil, nftInfo: nil, context: context, reason: "Invalid NFT Pointer")
            return
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        let receiverCap = getAccount(receiver).getCapability<&{NonFungibleToken.Receiver}>(path)

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
            emit Airdropped(from: pointer.owner() , to: receiverCap.address, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: "Receiver Not Linked")
            return
        }
        emit AirdroppedToLostAndFound(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: nil, ticketID: ticketID!)
    }

    pub fun subsidizedAirdrop(pointer: FindViews.AuthNFTPointer, receiver: Address, path: PublicPath, context: {String : String}, storagePayment: &FungibleToken.Vault, flowTokenRepayment: Capability<&FlowToken.Vault{FungibleToken.Receiver}>) {
        if !pointer.valid() {
            emit AirdropFailed(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nil, thumbnail: nil, nftInfo: nil, context: context, reason: "Invalid NFT Pointer")
            return
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        let receiverCap = getAccount(receiver).getCapability<&{NonFungibleToken.Receiver}>(path)

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
            emit Airdropped(from: pointer.owner() , to: receiverCap.address, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: "Receiver Not Linked")
            return
        }
        emit AirdroppedToLostAndFound(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: nil, ticketID: ticketID!)
    }


}

