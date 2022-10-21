import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FindMarket from "./FindMarket.cdc"
import FindViews from "./FindViews.cdc"

pub contract FindAirdropper {

    pub event Airdropped(from: Address , to: Address, id: UInt64, uuid: UInt64, type: String, title: String, thumbnail: String, nftInfo: FindMarket.NFTInfo, context: {String : String}, remark: String?)
    pub event AirdropFailed(from: Address , to: Address, id: UInt64, uuid: UInt64, type: String, title: String?, thumbnail: String?, nftInfo: FindMarket.NFTInfo?, context: {String : String}, reason: String)

    pub fun airdrop(pointer: FindViews.AuthNFTPointer, receiver: Address, path: PublicPath, context: {String : String}) {
        if !pointer.valid() {
            emit AirdropFailed(from: pointer.owner() , to: receiver, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nil, thumbnail: nil, nftInfo: nil, context: context, reason: "Invalid NFT Pointer")
            return
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        let receiverCap = getAccount(receiver).getCapability<&{NonFungibleToken.Receiver}>(path)

        if receiverCap.check() {

            emit Airdropped(from: pointer.owner() , to: receiverCap.address, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: nil)

            let nft <- pointer.withdraw()
            receiverCap.borrow()!.deposit(token: <- nft)
            return
        } else {
            let collectionPublicCap = getAccount(receiver).getCapability<&{NonFungibleToken.CollectionPublic}>(path)
            if collectionPublicCap.check() {
                emit Airdropped(from: pointer.owner() , to: receiverCap.address, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, remark: "Receiver Not Linked")

                let nft <- pointer.withdraw()
                collectionPublicCap.borrow()!.deposit(token: <- nft)
                return
            }
        }

        emit AirdropFailed(from: pointer.owner() , to: receiverCap.address, id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context, reason: "Invalid Receiver Capability")
        return

    }

}

