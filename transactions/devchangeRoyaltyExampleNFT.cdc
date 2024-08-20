import "ExampleNFT"

transaction(id: UInt64, cheat: Bool) {
    prepare(account: auth(BorrowValue) &Account) {
        let ref = account.storage.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)!
        let nft = ref.borrowNFT(id)! as! &ExampleNFT.NFT
        nft.changeRoyalties(cheat)
    }
}

