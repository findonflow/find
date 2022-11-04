import FIND from "../contracts/FIND.cdc" 
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import NFTStorefrontV2 from "../contracts/standard/NFTStorefrontV2.cdc"
import Flowty from "../contracts/community/Flowty.cdc"
import FlowtyRentals from "../contracts/community/FlowtyRentals.cdc"

// An auction saleItem contract that escrows the FT, does _not_ escrow the NFT
pub contract FindUserStatus {

	pub struct StoreFrontCut {

		pub let amount:UFix64
		pub let address: Address
		pub let findName:String?
		pub let tags: {String : String} 
		pub let scalars: {String : UFix64}
		pub let extra: {String : AnyStruct}

		init(amount:UFix64, address:Address){
			self.amount=amount
			self.address=address
			self.findName= FIND.reverseLookup(address)
			self.tags={}
			self.scalars={}
			self.extra={}
		}
	}


	pub struct StorefrontListing {
		pub var listingId: UInt64
		// if purchased is true -> don't show it
		//pub var purchased: Bool
		pub let nftIdentifier: String
		pub let nftId: UInt64
		pub let ftTypeIdentifier: String
		pub let amount: UFix64
		pub let cuts: [StoreFrontCut]
		pub var customID: String?
		pub let commissionAmount: UFix64?
		pub let listingValidUntil: UInt64?
		pub let tags: {String : String} 
		pub let scalars: {String : UFix64}
		pub let extra: {String : AnyStruct}

		init(storefrontID: UInt64, nftType: String, nftID: UInt64, salePaymentVaultType: String, salePrice: UFix64, saleCuts: [StoreFrontCut], customID: String?, commissionAmount: UFix64?, expiry: UInt64?) {
			self.listingId = storefrontID
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.ftTypeIdentifier = salePaymentVaultType
			self.amount = salePrice
			self.cuts = saleCuts
			self.customID = customID
			self.commissionAmount = commissionAmount
			self.listingValidUntil = expiry
			self.tags={}
			self.scalars={}
			self.extra={}
		}
	}

	pub struct FlowtyListing {

        pub var listingId: UInt64
        // Whether this listing has been funded or not.
        pub var funded: Bool
        // The Type of the NonFungibleToken.NFT that is being listed.
        pub let nftIdentifier: String
        // The ID of the NFT within that type.
        pub let nftId: UInt64
        // The amount of the requested loan.
        pub let amount: UFix64
        // The interest rate in %, a number between 0 and 1.
        pub let interestRate: UFix64
        //The term in seconds for this listing.
        pub var term: UFix64
        // The Type of the FungibleToken that fundings must be made in.
        pub let paymentVaultType: String

		pub let paymentCuts: [StoreFrontCut]
        //The time the funding start at
        pub var listedTime: UFix64
        // The royalty rate needed as a deposit for this loan to be funded
        pub var royaltyRate: UFix64
        // The number of seconds this listing is valid for
        pub var listingValidUntil: UFix64
		// Total fee needed for repayment
        pub var repaymentAmount: UFix64

		pub let tags: {String : String} 
		pub let scalars: {String : UFix64}
		pub let extra: {String : AnyStruct}

		init(flowtyStorefrontID: UInt64, funded: Bool, nftType: String, nftID: UInt64, amount: UFix64, interestRate: UFix64, term: UFix64, paymentVaultType: String,paymentCuts: [StoreFrontCut], listedTime: UFix64, royaltyRate: UFix64, expiresAfter: UFix64, repaymentAmount: UFix64) {
			self.listingId = flowtyStorefrontID
			self.funded = funded
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.amount = amount
			self.interestRate = interestRate
			self.term = term
			self.paymentVaultType = paymentVaultType
			self.paymentCuts = paymentCuts
			self.listedTime = listedTime
			self.royaltyRate = royaltyRate
			self.listingValidUntil = expiresAfter + listedTime
			self.repaymentAmount = repaymentAmount
			self.tags={}
			self.scalars={}
			self.extra={}
		}
	}

	pub struct FlowtyRental {

        pub var listingId: UInt64
        // Whether this listing has been funded or not.
        pub var rented: Bool
        // The Type of the NonFungibleToken.NFT that is being listed.
        pub let nftIdentifier: String
        // The ID of the NFT within that type.
        pub let nftId: UInt64
        // The amount of the requested loan.
        pub let amount: UFix64
		pub let deposit: UFix64
        //The term in seconds for this listing.
        pub var term: UFix64
        // The Type of the FungibleToken that fundings must be made in.
        pub let paymentVaultType: String
        pub let reenableOnReturn: Bool

		pub let paymentCuts: [StoreFrontCut]
        //The time the funding start at
        pub var listedTime: UFix64
        // The royalty rate needed as a deposit for this loan to be funded
        pub var royaltyRate: UFix64
        // The number of seconds this listing is valid for
        pub var listingValidUntil: UFix64
		// Total fee needed for repayment
        pub var repaymentAmount: UFix64
        pub var renter: Address? 
		pub var renterName: String? 

		pub let tags: {String : String} 
		pub let scalars: {String : UFix64}
		pub let extra: {String : AnyStruct}

		init(flowtyStorefrontID: UInt64, rented: Bool, nftType: String, nftID: UInt64, amount: UFix64, deposit: UFix64, term: UFix64, paymentVaultType: String, reenableOnReturn:Bool, paymentCuts: [StoreFrontCut], listedTime: UFix64, royaltyRate: UFix64, expiresAfter: UFix64, repaymentAmount: UFix64, renter: Address?) {
			self.listingId = flowtyStorefrontID
			self.rented = rented
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.deposit = deposit
			self.amount = amount
			self.term = term
			self.paymentVaultType = paymentVaultType
			self.reenableOnReturn = reenableOnReturn
			self.paymentCuts = paymentCuts
			self.listedTime = listedTime
			self.royaltyRate = royaltyRate
			self.listingValidUntil = expiresAfter + listedTime
			self.repaymentAmount = repaymentAmount
			self.renter = renter
			self.renterName = nil 
			if renter != nil {
				self.renterName = FIND.reverseLookup(renter!)
			}
			self.tags={}
			self.scalars={}
			self.extra={}
		}
	}

	pub fun getStorefrontListing(user: Address, id: UInt64) : StorefrontListing? {
	
		var listingsV1 : StorefrontListing? = nil
		let account = getAccount(user)
		let storefrontCap = account.getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)

		if storefrontCap.check() {
			let storefrontRef=storefrontCap.borrow()!
			for listingId in storefrontRef.getListingIDs() {
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID==id {
					if !d.purchased {
						let saleCuts : [StoreFrontCut] = [] 
						for cut in d.saleCuts {
							saleCuts.append(
								StoreFrontCut(
									amount: cut.amount, 
									address: cut.receiver.address
								)
							)
						}
						listingsV1 = StorefrontListing(storefrontID: d.storefrontID, nftType: d.nftType.identifier, nftID: d.nftID, salePaymentVaultType: d.salePaymentVaultType.identifier, salePrice: d.salePrice, saleCuts: saleCuts, customID: nil, commissionAmount: nil, expiry: nil)
						return listingsV1
					}
				}
			}
		}
		return nil
	}


	pub fun getStorefrontV2Listing(user: Address, id: UInt64) : StorefrontListing? {
		var listingsV2 : StorefrontListing? = nil
		let account = getAccount(user)
		let storefrontV2Cap = account.getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath)

		if storefrontV2Cap.check() {
			let storefrontRef=storefrontV2Cap.borrow()!
			for listingId in storefrontRef.getListingIDs() {
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID==id {
					if !d.purchased {
						let saleCuts : [StoreFrontCut] = [] 
						for cut in d.saleCuts {
							saleCuts.append(
								StoreFrontCut(
									amount: cut.amount, 
									address: cut.receiver.address
								)
							)
						}
						listingsV2 = StorefrontListing(storefrontID: d.storefrontID, nftType: d.nftType.identifier, nftID: d.nftID, salePaymentVaultType: d.salePaymentVaultType.identifier, salePrice: d.salePrice, saleCuts: saleCuts, customID: d.customID, commissionAmount: d.commissionAmount, expiry: d.expiry)
						return listingsV2
					}
				}
			}
		}
		return nil
	}

	pub fun getFlowtyListing(user: Address, id: UInt64) : FlowtyListing? {
		var flowty : FlowtyListing? = nil
		let account = getAccount(user)
		let flowtyCap = account.getCapability<&Flowty.FlowtyStorefront{Flowty.FlowtyStorefrontPublic}>(Flowty.FlowtyStorefrontPublicPath)

		if flowtyCap.check() {
			let storefrontRef=flowtyCap.borrow()!
			for listingId in storefrontRef.getListingIDs() {
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID==id {
					if !d.funded {
						let saleCuts : [StoreFrontCut] = [] 
						for cut in d.getPaymentCuts() {
							saleCuts.append(
								StoreFrontCut(
									amount: cut.amount, 
									address: cut.receiver.address
								)
							)
						}
						flowty = FlowtyListing(flowtyStorefrontID: d.flowtyStorefrontID, funded: d.funded, nftType: d.nftType.identifier, nftID: d.nftID, amount: d.amount, interestRate: d.interestRate, term: d.term, paymentVaultType: d.paymentVaultType.identifier ,paymentCuts: saleCuts, listedTime: d.listedTime, royaltyRate: d.royaltyRate, expiresAfter: d.expiresAfter, repaymentAmount: d.getTotalPayment())
						return flowty
					}
				}
			}
		}
		return nil
	}

	pub fun getFlowtyRentals(user: Address, id: UInt64) : FlowtyRental? {

		var flowtyRental : FlowtyRental? = nil
		let account = getAccount(user)
		let flowtyRentalCap = account.getCapability<&FlowtyRentals.FlowtyRentalsStorefront{FlowtyRentals.FlowtyRentalsStorefrontPublic}>(FlowtyRentals.FlowtyRentalsStorefrontPublicPath)

		if flowtyRentalCap.check() {
			let storefrontRef=flowtyRentalCap.borrow()!
			for listingId in storefrontRef.getListingIDs() {
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID==id {
					if !d.rented {
						let saleCuts : [StoreFrontCut] = [] 
						let cut = d.getPaymentCut() 
							saleCuts.append(
								StoreFrontCut(
									amount: cut.amount, 
									address: cut.receiver.address
								)
							)
						
						flowtyRental = FlowtyRental(flowtyStorefrontID: d.flowtyStorefrontID, rented: d.rented, nftType: d.nftType.identifier, nftID: d.nftID, amount: d.amount, deposit: d.deposit, term: d.term, paymentVaultType: d.paymentVaultType.identifier, reenableOnReturn: d.reenableOnReturn, paymentCuts: saleCuts, listedTime: d.listedTime, royaltyRate: d.royaltyRate, expiresAfter: d.expiresAfter, repaymentAmount: d.getTotalPayment(), renter: d.renter)
						return flowtyRental
					}
				}
			}
		}
		return nil
	}
}
