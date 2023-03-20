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

pub struct FINDReport{
	pub let isDapper: Bool
	pub let profile:Profile.UserReport?
	pub let privateMode: Bool
	pub let activatedAccount: Bool
	pub let hasLostAndFoundItem: Bool
	pub let accounts : [AccountInformation]?
	//not sure
	pub let readyForWearables : Bool?
	pub let paths:[String]

	init(profile: Profile.UserReport?,
	privateMode: Bool,
	activatedAccount: Bool,
	isDapper: Bool,
	hasLostAndFoundItem: Bool,
	accounts: [AccountInformation]?,
	readyForWearables: Bool?,
	paths: [String]) {

		self.hasLostAndFoundItem=hasLostAndFoundItem
		self.profile=profile
		self.privateMode=privateMode
		self.activatedAccount=activatedAccount
		self.isDapper=isDapper
		self.accounts=accounts
		self.readyForWearables=readyForWearables
		self.paths=paths
	}
}

pub struct AccountInformation {
	pub let name: String
	pub let address: String
	pub let network: String
	pub let trusted: Bool
	pub let node: String

	init(name: String, address: String, network: String, trusted: Bool, node: String) {
		self.name = name
		self.address = address
		self.network = network
		self.trusted = trusted
		self.node = node
	}
}


pub fun main(user: String) : FINDReport? {

	let maybeAddress=FIND.resolve(user)
	if maybeAddress == nil{
		return nil
	}

	let address=maybeAddress!

	let account=getAuthAccount(address)
	if account.balance == 0.0 {
		return nil
	}


	var isDapper=false
	if let receiver =account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow() {
		isDapper=receiver.isInstance(Type<@TokenForwarding.Forwarder>())
	} else {
		if let duc = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver).borrow() {
			isDapper = duc.isInstance(Type<@TokenForwarding.Forwarder>())
		} else {
			isDapper = false
		}
	}

	let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
	var profileReport = profile?.asReport()
	if profileReport != nil && profileReport!.findName != FIND.reverseLookup(address) {
		profileReport = Profile.UserReport(
			findName: "",
			address: profileReport!.address,
			name: profileReport!.name,
			gender: profileReport!.gender,
			description: profileReport!.description,
			tags: profileReport!.tags,
			avatar: profileReport!.avatar,
			links: profileReport!.links,
			wallets: profileReport!.wallets,
			following: profileReport!.following,
			followers: profileReport!.followers,
			allowStoringFollowers: profileReport!.allowStoringFollowers,
			createdAt: profileReport!.createdAt
		)
	}

	let discordID = EmeraldIdentity.getDiscordFromAccount(account: address)
	?? EmeraldIdentityDapper.getDiscordFromAccount(account: address)
	?? EmeraldIdentityLilico.getDiscordFromAccount(account: address)
	?? ""

	let emeraldIDAccounts : {String : Address} = {}
	emeraldIDAccounts["blocto"] = EmeraldIdentity.getAccountFromDiscord(discordID: discordID)
	emeraldIDAccounts["lilico"] = EmeraldIdentityLilico.getAccountFromDiscord(discordID: discordID)
	emeraldIDAccounts["dapper"] = EmeraldIdentityDapper.getAccountFromDiscord(discordID: discordID)

	let accounts : [AccountInformation] = []
	for wallet in ["blocto", "lilico", "dapper"] {
		if let w = emeraldIDAccounts[wallet] {
			if w == address {
				continue
			}

			accounts.append(
				AccountInformation(
					name: wallet,
					address: w.toString(),
					network: "Flow",
					trusted: true,
					node: "EmeraldID")
				)
			}
	}

  let allAcctsCap = FindRelatedAccounts.getCapability(address)
  if allAcctsCap.check() {
		let allAcctsRef = allAcctsCap.borrow()!
		let allAccts = allAcctsRef.getAllRelatedAccountInfo()
		for acct in allAccts.values {
			// We only verify flow accounts that are mutually linked
			var trusted = false
			if acct.address != nil {
				if acct.address! == address {
					continue
				}
				trusted = allAcctsRef.linked(name: acct.name, network: acct.network, address: acct.address!)
			}
			accounts.append(AccountInformation(
				name: acct.name,
				address: acct.stringAddress,
				network: acct.network,
				trusted: trusted,
				node: "FindRelatedAccounts")
			)
		}
	}

	var readyForWearables = true
	let wearablesRef= account.borrow<&Wearables.Collection>(from: Wearables.CollectionStoragePath)
	if wearablesRef == nil {
		readyForWearables = false
	}

	let wearablesCap= account.getCapability<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPublicPath)
	if !wearablesCap.check() {
		readyForWearables = false
	}

	let wearablesProviderCap= account.getCapability<&Wearables.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPrivatePath)
	if !wearablesCap.check() {
		readyForWearables = false
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

	let storage = "/storage/"
	let paths : [String] = []
	for p in allPaths {
		if banned.containsKey(p) {
			continue
		}
		let path = p.toString()
		paths.append(path.slice(from: storage.length, upTo: path.length))
	}

	var hasLostAndFoundItem : Bool = false
	for t in LostAndFound.getRedeemableTypes(address) {
		if t.isSubtype(of: Type<@NonFungibleToken.NFT>()) {
			hasLostAndFoundItem = true
			break
		}
	}

	return FINDReport(
		profile: profileReport,
		privateMode: profile?.isPrivateModeEnabled() ?? false,
		activatedAccount: true,
		isDapper:isDapper,
		hasLostAndFoundItem: hasLostAndFoundItem,
		accounts: accounts,
		readyForWearables: readyForWearables,
		paths:paths
	)
}

