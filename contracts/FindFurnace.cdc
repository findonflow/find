import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FindMarket from "./FindMarket.cdc"
import FindViews from "./FindViews.cdc"

pub contract FindFurnace {

    pub event Burned(from: Address , id: UInt64, uuid: UInt64, type: String, title: String, thumbnail: String, nftInfo: FindMarket.NFTInfo, context: {String : String})

    pub fun burn(pointer: FindViews.AuthNFTPointer, path: PublicPath, context: {String : String}) {
        if !pointer.valid() {
            panic("Invalid NFT Pointer. Type : ".concat(pointer.itemType.identifier).concat(" ID : ").concat(pointer.uuid.toString()))
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        emit Burned(from: pointer.owner() , id: pointer.id, uuid: pointer.uuid, type: pointer.itemType.identifier, title: nftInfo.name, thumbnail: nftInfo.thumbnail, nftInfo: nftInfo, context: context)
        destroy pointer.withdraw()
    }

}

