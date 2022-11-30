import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FindMarket from "./FindMarket.cdc"
import FindViews from "./FindViews.cdc"

pub contract FindFurnace {

    pub event Burned(from: Address, uuid: UInt64, nftInfo: FindMarket.NFTInfo, context: {String : String})

    pub fun burn(pointer: FindViews.AuthNFTPointer, context: {String : String}) {
        if !pointer.valid() {
            panic("Invalid NFT Pointer. Type : ".concat(pointer.itemType.identifier).concat(" ID : ").concat(pointer.uuid.toString()))
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        emit Burned(from: pointer.owner() , uuid: pointer.uuid, nftInfo: nftInfo, context: context)
        destroy pointer.withdraw()
    }

    pub fun burnWithoutValidation(pointer: FindViews.AuthNFTPointer, context: {String : String}) {
        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)

        emit Burned(from: pointer.owner() , uuid: pointer.uuid, nftInfo: nftInfo, context: context)
        destroy pointer.withdraw()
    }

}

