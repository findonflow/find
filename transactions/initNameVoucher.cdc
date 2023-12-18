import NameVoucher from "../contracts/NameVoucher.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		let nameVoucherRef= account.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
		if nameVoucherRef == nil {
			account.save<@NonFungibleToken.Collection>(<- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
			account.unlink(NameVoucher.CollectionPublicPath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NameVoucher.CollectionPublicPath,
				target: NameVoucher.CollectionStoragePath
			)
			account.unlink(NameVoucher.CollectionPrivatePath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NameVoucher.CollectionPrivatePath,
				target: NameVoucher.CollectionStoragePath
			)
			return
		}

		let nameVoucherCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(NameVoucher.CollectionPublicPath)
		if !nameVoucherCap.check() {
			account.unlink(NameVoucher.CollectionPublicPath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NameVoucher.CollectionPublicPath,
				target: NameVoucher.CollectionStoragePath
			)
		}

		let nameVoucherProviderCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.Provider,NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(NameVoucher.CollectionPrivatePath)
		if !nameVoucherProviderCap.check() {
			account.unlink(NameVoucher.CollectionPrivatePath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NameVoucher.CollectionPrivatePath,
				target: NameVoucher.CollectionStoragePath
			)
		}

	}
}
