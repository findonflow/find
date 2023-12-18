import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

// map of {User in string (find name or address) : [tag]}
transaction(follows:{String : [String]}) {

	let profile : &Profile.User

	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		self.profile =account.borrow<&Profile.User>(from:Profile.storagePath) ?? panic("Cannot borrow reference to profile")

		//Add exising FUSD or create a new one and add it
		let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}


		var hasFusdWallet=false
		var hasFlowWallet=false
		let wallets=self.profile.getWallets()
		for wallet in wallets {
			if wallet.name=="FUSD" {
				hasFusdWallet=true
			}

			if wallet.name =="Flow" {
				hasFlowWallet=true
			}
		}

		if !hasFlowWallet {
			let flowWallet=Profile.Wallet(
				name:"Flow",
				receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
				balance:account.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance),
				accept: Type<@FlowToken.Vault>(),
				tags: ["flow"]
			)
			self.profile.addWallet(flowWallet)
		}

		if !hasFusdWallet {
			let fusdWallet=Profile.Wallet(
				name:"FUSD",
				receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver),
				balance:account.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
				accept: Type<@FUSD.Vault>(),
				tags: ["fusd", "stablecoin"]
			)
			self.profile.addWallet(fusdWallet)
		}

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)

		}

		let bidCollection = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			account.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			account.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}
	}

	execute{
		for key in follows.keys {
			let user = FIND.resolve(key) ?? panic(key.concat(" cannot be resolved. It is either an invalid .find name or address"))
			let tags = follows[key]!
			self.profile.follow(user, tags: tags)
		}
	}
}

