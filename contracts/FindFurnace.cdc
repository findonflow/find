import "NonFungibleToken"
import "FindMarket"
import "FindViews"
import "FIND"

access(all) contract FindFurnace {

    access(all) event Burned(from: Address, fromName: String?, uuid: UInt64, nftInfo: FindMarket.NFTInfo, context: {String : String})

    access(all) fun burn(pointer: FindViews.AuthNFTPointer, context: {String : String}) {
        if !pointer.valid() {
            panic("Invalid NFT Pointer. Type : ".concat(pointer.itemType.identifier).concat(" ID : ").concat(pointer.uuid.toString()))
        }

        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
        let owner = pointer.owner()
        emit Burned(from: owner, fromName: FIND.reverseLookup(owner) , uuid: pointer.uuid, nftInfo: nftInfo, context: context)
        destroy pointer.withdraw()
    }

    access(all) fun burnWithoutValidation(pointer: FindViews.AuthNFTPointer, context: {String : String}) {
        let vr = pointer.getViewResolver()
        let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
        let owner = pointer.owner()
        emit Burned(from: owner, fromName: FIND.reverseLookup(owner) , uuid: pointer.uuid, nftInfo: nftInfo, context: context)
        destroy pointer.withdraw()
    }

}

