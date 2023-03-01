import NameVoucher from "../contracts/NameVoucher.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction() {
	prepare(account: AuthAccount) {

		let nameVoucherRef= account.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
		if nameVoucherRef == nil {
			account.save<@NonFungibleToken.Collection>(<- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
			account.unlink(NameVoucher.CollectionPublicPath)
			account.link<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPublicPath,
				target: NameVoucher.CollectionStoragePath
			)
			account.unlink(NameVoucher.CollectionPrivatePath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPrivatePath,
				target: NameVoucher.CollectionStoragePath
			)
			return
		}

		let nameVoucherCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NameVoucher.CollectionPublicPath)
		if !nameVoucherCap.check() {
			account.unlink(NameVoucher.CollectionPublicPath)
			account.link<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPublicPath,
				target: NameVoucher.CollectionStoragePath
			)
		}

		let nameVoucherProviderCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NameVoucher.CollectionPrivatePath)
		if !nameVoucherProviderCap.check() {
			account.unlink(NameVoucher.CollectionPrivatePath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPrivatePath,
				target: NameVoucher.CollectionStoragePath
			)
		}

	}
}
