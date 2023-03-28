import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import EmeraldIdentity from "../contracts/standard/EmeraldIdentity.cdc"
import EmeraldIdentityDapper from "../contracts/standard/EmeraldIdentityDapper.cdc"
import EmeraldIdentityLilico from "../contracts/standard/EmeraldIdentityLilico.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Wearables from "../contracts/community/Wearables.cdc"
import FindUtils from "../contracts/FindUtils.cdc"
import Clock from "../contracts/Clock.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"

pub fun main(user: String) : Report? {

	let maybeAddress=FIND.resolve(user)
	if maybeAddress == nil{
		return nil
	}

	let address=maybeAddress!

	let account=getAuthAccount(address)
	if account.balance == 0.0 {
		return nil
	}

	let allPaths = account.storagePaths

	 let banned : {StoragePath : Bool} = {
		/storage/FantastecNFTCollection: true,
		/storage/FantastecNFTMinter: true,
		/storage/jambbLaunchCollectiblesCollection: true,
		/storage/jambbLaunchCollectiblesMinter: true,
		/storage/RacingTimeCollection: true,
		/storage/RacingTimeMinter: true,
		/storage/MusicBlockCollection: true,
		/storage/MusicBlockMinter: true,
		/storage/SupportUkraineCollectionV10: true,
		/storage/SupportUkraineMinterV10: true,
		/storage/DropzTokenCollection: true,
		/storage/DropzTokenAdmin: true,
		/storage/TokenLendingUserCertificate001: true,
		/storage/TokenLendingPlaceMinterProxy001: true,
		/storage/TokenLendingPlaceAdmin: true,
		/storage/TokenLendingPlace001: true,
		/storage/BnGNFTCollection: true,
		/storage/FuseCollectiveCollection: true,
		/storage/NFTLXKickCollection: true,
		/storage/NFTLXKickMinter: true,
		/storage/revvTeleportCustodyAdmin: true,
		/storage/ZayTraderCollection: true,
		/storage/RaribleNFTCollection: true,
		/storage/LibraryPassCollection: true
	}

	let nonNFTPaths : {StoragePath : Bool} = {
		/storage/USDCVault : true,
		/storage/flowTokenVault : true,
		/storage/fusdVault : true,
		/storage/A_097bafa4e0b48eef_FindMarketDirectOfferEscrow_SaleItemCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindMarket_Tenant_onefootball : true,
		/storage/A_097bafa4e0b48eef_FindMarket_Tenant_findLease : true,
		/storage/A_097bafa4e0b48eef_FindMarket_Tenant_find_dapper : true,
		/storage/A_097bafa4e0b48eef_FindMarketDirectOfferEscrow_MarketBidCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindLeaseMarketDirectOfferSoft_MarketBidCollection_findLease : true,
		/storage/A_097bafa4e0b48eef_FindMarketAuctionSoft_MarketBidCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindMarketAuctionEscrow_SaleItemCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindMarketAuctionEscrow_MarketBidCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindLeaseMarketSale_SaleItemCollection_findLease : true,
		/storage/A_097bafa4e0b48eef_FindLeaseMarketAuctionSoft_MarketBidCollection_findLease : true,
		/storage/A_097bafa4e0b48eef_FindMarketSale_SaleItemCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindMarketDirectOfferSoft_MarketBidCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindLeaseMarketAuctionSoft_SaleItemCollection_findLease : true,
		/storage/A_097bafa4e0b48eef_FindLeaseMarketDirectOfferSoft_SaleItemCollection_findLease : true,
		/storage/A_097bafa4e0b48eef_FindMarketDirectOfferSoft_SaleItemCollection_find : true,
		/storage/A_097bafa4e0b48eef_FindMarketAuctionSoft_SaleItemCollection_find : true,
		/storage/dapperUtilityCoinReceiver : true,
		/storage/flowUtilityTokenReceiver : true,
		/storage/fungibleTokenSwitchboard : true,
		/storage/FLOATEventsStoragePath : true,
		/storage/FindThoughts : true,
		/storage/findBids : true,
		/storage/findLeases : true,
		/storage/findProfile : true,
		/storage/findSender : true
	}

	let storage = "/storage/"
	let paths : [String] = []
	for p in allPaths {
		if banned.containsKey(p) {
			continue
		}
		if nonNFTPaths.containsKey(p) {
			continue
		}
		let path = p.toString()
		paths.append(path.slice(from: storage.length, upTo: path.length))
	}

	return Report(paths: paths, address: address)
}

pub struct Report {
	pub let paths : [String]
	pub let address : Address

	init(
		paths: [String],
		address: Address
	) {
		self.paths=paths
		self.address=address
	}
}
