package main

import (
	. "github.com/bjartek/overflow/v2"
)

func main() {

	o := Overflow(
		WithNetwork("mainnet"),
		WithPrintResults(),
		WithPanicOnError(),
	)

	if o.Error != nil {
		panic(o.Error)
	}

	o.Tx("adminAddNFTCatalogDirect",
		WithSigner("find-admin"),
		WithArg("collectionIdentifier", "Party Gooberz"),
		WithArg("contractName", "GooberXContract"),
		WithArg("contractAddress", "0x34f2bf4a80bb0f69"),
		WithArg("nftTypeIdentifer", "A.34f2bf4a80bb0f69.GooberXContract.NFT"),
		WithArg("storagePathIdentifier", "GooberzPartyFolksCollection"),
		WithArg("publicPathIdentifier", "GooberzPartyFolksCollectionPublic"),
		WithArg("privatePathIdentifier", "GooberzPartyFolksCollection"),
		WithArg("publicLinkedTypeIdentifier", "A.34f2bf4a80bb0f69.GooberXContract.Collection"),
		WithArg("publicLinkedTypeRestrictions", []string{"A.34f2bf4a80bb0f69.GooberXContract.GooberCollectionPublic", "A.1d7e57aa55817448.NonFungibleToken.Receiver", "A.1d7e57aa55817448.NonFungibleToken.Collection", "A.1d7e57aa55817448.ViewResolver.ResolverCollection"}),
		WithArg("publicLinkedTypeIdentifier", "A.34f2bf4a80bb0f69.GooberXContract.Collection"),
		WithArg("privateLinkedTypeRestrictions", []string{"A.1d7e57aa55817448.NonFungibleToken.Provider", "A.34f2bf4a80bb0f69.GooberXContract.GooberCollectionPublic", "A.1d7e57aa55817448.NonFungibleToken.Receiver", "A.1d7e57aa55817448.NonFungibleToken.Collection", "A.1d7e57aa55817448.ViewResolver.ResolverCollection"}),
		WithArg("collectionName", "Party Mansion Gooberz"),
		WithArg("collectionDescription", "The Party Gooberz is a fun and comical art collection of 3550 collectibles living on the Flow Blockchain. As one of the first PFP collectibles on Flow, we enjoy bringing the party and hanging with friends. So grab a drink, pump up the music, and get ready to party because The Party Goobz are ready to go within Party Mansion!"),
		WithArg("externalURL", "https://partymansion.io/"),
		WithArg("squareImageMediaCID", "QmeiwpEXCidsPae3ZPpSJTKVit1R2LHiF4cw5pvmMPRC4x"),
		WithArg("squareImageMediaType", "image/png"),
		WithArg("bannerImageMediaCID", "QmdU1j5nqeQBmVWZZDhz23z6mMPwMp5i2Ka2sBpMhYggPT"),
		WithArg("bannerImageMediaType", "image/png"),
		WithArg("socials", map[string]string{
			"twitter": "https://mobile.twitter.com/the_goobz_nft",
			"discord": "http://discord.gg/zJRNqKuDQH",
		}),
	)

	o.Tx("adminAddNFTCatalogDirect",
		WithSigner("find-admin"),
		WithArg("collectionIdentifier", "Party Drinks"),
		WithArg("contractName", "PartyMansionDrinksContract"),
		WithArg("contractAddress", "0x34f2bf4a80bb0f69"),
		WithArg("nftTypeIdentifer", "A.34f2bf4a80bb0f69.PartyMansionDrinksContract.NFT"),
		WithArg("storagePathIdentifier", "PartyMansionDrinkCollection"),
		WithArg("publicPathIdentifier", "PartyMansionDrinkCollectionPublic"),
		WithArg("privatePathIdentifier", "PartyMansionDrinkCollectionPublic"),
		WithArg("publicLinkedTypeIdentifier", "A.34f2bf4a80bb0f69.PartyMansionDrinksContract.Collection"),
		WithArg("publicLinkedTypeRestrictions", []string{"A.34f2bf4a80bb0f69.PartyMansionDrinksContract.DrinkCollectionPublic", "A.1d7e57aa55817448.NonFungibleToken.Receiver", "A.1d7e57aa55817448.NonFungibleToken.Collection", "A.1d7e57aa55817448.ViewResolver.ResolverCollection"}),
		WithArg("publicLinkedTypeIdentifier", "A.34f2bf4a80bb0f69.PartyMansionDrinksContract.Collection"),
		WithArg("privateLinkedTypeRestrictions", []string{"A.1d7e57aa55817448.NonFungibleToken.Provider", "A.34f2bf4a80bb0f69.PartyMansionDrinksContract.DrinkCollectionPublic", "A.1d7e57aa55817448.NonFungibleToken.Receiver", "A.1d7e57aa55817448.NonFungibleToken.Collection", "A.1d7e57aa55817448.ViewResolver.ResolverCollection"}),
		WithArg("collectionName", "Party Mansion Drinks"),
		WithArg("collectionDescription", "What is a Party without drinks!? The Party Beers are an fun art collection of whacky drinks that can only be found at the bar in Party Mansion. These collectibles were first airdropped to Party Gooberz and will be a staple in the Mansion, Drink up!"),
		WithArg("externalURL", "https://partymansion.io/"),
		WithArg("squareImageMediaCID", "QmSEJEwqdpotJ7RX42RKDy5sVgQzhNy3XiDmFsc81wgzNC"),
		WithArg("squareImageMediaType", "image/png"),
		WithArg("bannerImageMediaCID", "QmVyXgw67QVAU98765yfQAB1meZhnSnYVoL6mz6UpzSw7W"),
		WithArg("bannerImageMediaType", "image/png"),
		WithArg("socials", map[string]string{
			"twitter": "https://mobile.twitter.com/the_goobz_nft",
			"discord": "http://discord.gg/zJRNqKuDQH",
		}),
	)

}
