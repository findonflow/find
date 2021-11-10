
import FIND from "../contracts/FIND.cdc"
import Art from "../contracts/Art.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

//mint an art and add it to a users collection
transaction(
    artist: Address,
    artistName: String, 
    artName: String, 
    description: String,
	  target:Address,
    type: String,
    artistCut: UFix64,
    minterCut: UFix64
		content: String,
	) {

    let artistCollection: Capability<&{Art.CollectionPublic}>
    let client: &FIND.AdminProxy
		let minterWallet: Capability<&{FungibleToken.Receiver}>

    prepare(account: AuthAccount) {
				self.client=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!
        self.artistCollection= getAccount(target).getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
				self.minterWallet=account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    }

    execute {
			    let artistWallet= getAccount(artist).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
  
         let royalty = {
           "artist" : Art.Royalty(wallet: artistWallet, cut: artistCut),
           "minter" : Art.Royalty(wallet: self.minterWallet, cut: minterCut)
         }
			let art <-  self.client.createVersusArtWithContent(name: artName, artist: artistName, artistAddress: artist, description: description, url: content, type: type, royalty: royalty, edition: 1, maxEdition: 1)
        self.artistCollection.borrow()!.deposit(token: <- art)
    }
}

