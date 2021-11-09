import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import Artifact from "../contracts/Artifact.cdc"
import Art from "../contracts/Art.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"


//really not sure on how to input links here.)
transaction(name: String) {
	prepare(acct: AuthAccount) {
		//if we do not have a profile it might be stored under a different address so we will just remove it
		let profileCap = acct.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			acct.unlink(Profile.publicPath)
			destroy <- acct.load<@AnyResource>(from:Profile.storagePath)
		}

		//TODO we already have a profile
		if profileCap.check() {
			return 
		}

		let profile <-Profile.createUser(name:name, description: "", allowStoringFollowers:true, tags:["find"])

		//Add exising FUSD or create a new one and add it
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let fusdWallet=Profile.Wallet(
			name:"FUSD", 
			receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver),
			balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
			accept: Type<@FUSD.Vault>(),
			names: ["fusd", "stablecoin"]
		)

		profile.addWallet(fusdWallet)


			let flowWallet=Profile.Wallet(
				name:"Flow", 
				receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
				balance:acct.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance),
				accept: Type<@FlowToken.Vault>(),
				names: ["flow"]
			)
			profile.addWallet(flowWallet)
		let leaseCollection = acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			acct.unlink(FIND.LeasePublicPath)
			destroy <- acct.load<@AnyResource>(from:FIND.LeaseStoragePath)
			acct.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			acct.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}
		profile.addCollection(Profile.ResourceCollection("FINDLeases",leaseCollection, Type<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(), ["find", "leases"]))

		let bidCollection = acct.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			acct.unlink(FIND.BidPublicPath)
			destroy <- acct.load<@AnyResource>(from:FIND.BidStoragePath)
			acct.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			acct.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}
		profile.addCollection(Profile.ResourceCollection( "FINDBids", bidCollection, Type<&FIND.BidCollection{FIND.BidCollectionPublic}>(), ["find", "bids"]))

		let artifactCollection = acct.getCapability<&{TypedMetadata.ViewResolverCollection}>(Artifact.ArtifactPublicPath)
		if !artifactCollection.check() {
			acct.unlink(Artifact.ArtifactPublicPath)
			destroy <- acct.load<@AnyResource>(from:Artifact.ArtifactStoragePath)

			acct.save(<- Artifact.createEmptyCollection(), to: Artifact.ArtifactStoragePath)
			acct.link<&{TypedMetadata.ViewResolverCollection}>( Artifact.ArtifactPublicPath, target: Artifact.ArtifactStoragePath)
		}
		profile.addCollection(Profile.ResourceCollection(name: "artifacts", collection: artifactCollection, type: Type<&{TypedMetadata.ViewResolverCollection}>(), tags: ["artifact", "nft"]))

    //Create versus art collection if it does not exist and add it
    let artCollectionCap=acct.getCapability<&{TypedMetadata.ViewResolverCollection}>(/public/versusArtViewResolver)
    if !artCollectionCap.check() {
      acct.save(<- Art.createEmptyCollection(), to: Art.CollectionStoragePath)
			//NB! this is not how versus current links this, it is just for convenience for this demo
			acct.link<&{Art.CollectionPublic}>(Art.CollectionPublicPath, target: Art.CollectionStoragePath)
      acct.link<&{TypedMetadata.ViewResolverCollection}>(/public/versusArtViewResolver, target: Art.CollectionStoragePath)
    }
    profile.addCollection(Profile.ResourceCollection( name: "versus", collection:artCollectionCap, type: Type<&{TypedMetadata.ViewResolverCollection}>(), tags: ["versus", "nft"]))

		acct.save(<-profile, to: Profile.storagePath)
		acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)

	}
}
