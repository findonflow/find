import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NameVoucher from "../contracts/NameVoucher.cdc"
import Wearables from "../contracts/community/Wearables.cdc"
import PartyFavorz from "../contracts/PartyFavorz.cdc"
import NFGv3 from "../contracts/NFGv3.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction() {
	prepare(account: auth(BorrowValue) &Account) {

		// Dandy
		let DandyRef= account.storage.borrow<&Dandy.Collection>(from: Dandy.CollectionStoragePath)
		if DandyRef == nil {
			account.storage.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.unlink(Dandy.CollectionPublicPath)
			account.link<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.unlink(Dandy.CollectionPrivatePath)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let DandyCap= account.getCapability<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Dandy.CollectionPublicPath)
		if !DandyCap.check() {
			account.unlink(Dandy.CollectionPublicPath)
			account.link<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
		}

		let DandyProviderCap= account.getCapability<&Dandy.Collection{NonFungibleToken.Provider,NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Dandy.CollectionPrivatePath)
		if !DandyProviderCap.check() {
			account.unlink(Dandy.CollectionPrivatePath)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		// NFGv3
		let NFGv3Ref= account.storage.borrow<&NFGv3.Collection>(from: NFGv3.CollectionStoragePath)
		if NFGv3Ref == nil {
			account.storage.save<@NonFungibleToken.Collection>(<- NFGv3.createEmptyCollection(), to: NFGv3.CollectionStoragePath)
			account.unlink(NFGv3.CollectionPublicPath)
			account.link<&NFGv3.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NFGv3.CollectionPublicPath,
				target: NFGv3.CollectionStoragePath
			)
			account.unlink(NFGv3.CollectionPrivatePath)
			account.link<&NFGv3.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NFGv3.CollectionPrivatePath,
				target: NFGv3.CollectionStoragePath
			)
		}

		let NFGv3Cap= account.getCapability<&NFGv3.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(NFGv3.CollectionPublicPath)
		if !NFGv3Cap.check() {
			account.unlink(NFGv3.CollectionPublicPath)
			account.link<&NFGv3.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NFGv3.CollectionPublicPath,
				target: NFGv3.CollectionStoragePath
			)
		}

		let NFGv3ProviderCap= account.getCapability<&NFGv3.Collection{NonFungibleToken.Provider,NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(NFGv3.CollectionPrivatePath)
		if !NFGv3ProviderCap.check() {
			account.unlink(NFGv3.CollectionPrivatePath)
			account.link<&NFGv3.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NFGv3.CollectionPrivatePath,
				target: NFGv3.CollectionStoragePath
			)
		}

		// Party Favorz
		let PartyFavorzRef= account.storage.borrow<&PartyFavorz.Collection>(from: PartyFavorz.CollectionStoragePath)
		if PartyFavorzRef == nil {
			account.storage.save<@NonFungibleToken.Collection>(<- PartyFavorz.createEmptyCollection(), to: PartyFavorz.CollectionStoragePath)
			account.unlink(PartyFavorz.CollectionPublicPath)
			account.link<&PartyFavorz.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				PartyFavorz.CollectionPublicPath,
				target: PartyFavorz.CollectionStoragePath
			)
			account.unlink(PartyFavorz.CollectionPrivatePath)
			account.link<&PartyFavorz.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				PartyFavorz.CollectionPrivatePath,
				target: PartyFavorz.CollectionStoragePath
			)
		}

		let PartyFavorzCap= account.getCapability<&PartyFavorz.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(PartyFavorz.CollectionPublicPath)
		if !PartyFavorzCap.check() {
			account.unlink(PartyFavorz.CollectionPublicPath)
			account.link<&PartyFavorz.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				PartyFavorz.CollectionPublicPath,
				target: PartyFavorz.CollectionStoragePath
			)
		}

		let PartyFavorzProviderCap= account.getCapability<&PartyFavorz.Collection{NonFungibleToken.Provider,NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(PartyFavorz.CollectionPrivatePath)
		if !PartyFavorzProviderCap.check() {
			account.unlink(PartyFavorz.CollectionPrivatePath)
			account.link<&PartyFavorz.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				PartyFavorz.CollectionPrivatePath,
				target: PartyFavorz.CollectionStoragePath
			)
		}

		// Name Voucher
		let nameVoucherRef= account.storage.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
		if nameVoucherRef == nil {
			account.storage.save<@NonFungibleToken.Collection>(<- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
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

		// Wearables
		let wearablesRef= account.storage.borrow<&Wearables.Collection>(from: Wearables.CollectionStoragePath)
		if wearablesRef == nil {
			account.storage.save<@NonFungibleToken.Collection>(<- Wearables.createEmptyCollection(), to: Wearables.CollectionStoragePath)
			account.unlink(Wearables.CollectionPublicPath)
			account.link<&Wearables.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Wearables.CollectionPublicPath,
				target: Wearables.CollectionStoragePath
			)
			account.unlink(Wearables.CollectionPrivatePath)
			account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Wearables.CollectionPrivatePath,
				target: Wearables.CollectionStoragePath
			)
		}

		let wearablesCap= account.getCapability<&Wearables.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Wearables.CollectionPublicPath)
		if !wearablesCap.check() {
			account.unlink(Wearables.CollectionPublicPath)
			account.link<&Wearables.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Wearables.CollectionPublicPath,
				target: Wearables.CollectionStoragePath
			)
		}

		let wearablesProviderCap= account.getCapability<&Wearables.Collection{NonFungibleToken.Provider,NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Wearables.CollectionPrivatePath)
		if !wearablesProviderCap.check() {
			account.unlink(Wearables.CollectionPrivatePath)
			account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Wearables.CollectionPrivatePath,
				target: Wearables.CollectionStoragePath
			)
		}

	}
}
