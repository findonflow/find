import FungibleToken from "../standard/FungibleToken.cdc"    
import NonFungibleToken from "../standard/NonFungibleToken.cdc"
import FlowtyUtils from "./FlowtyUtils.cdc"
import Flowty from "./Flowty.cdc"
import CoatCheck from "./CoatCheck.cdc"

// FlowtyRentals
//
// A smart contract responsible for the letting accounts take temporary ownership
// of assets. It allows owners to list items they own for a fee + deposit and a term
// that other accounts can then rent. If the item being rented is returned before
// the term is up, their deposit is returned. If, however, they do not return the rented
// item by this time, they might lose their deposit if settlement cannot facilitate
// automatically returning the asset.
//
// Each account that wants to list a an item for rent installs a Storefront.
// Storefronts can list items for rent. There is one Storefront per account,
// it handles rentals of all NFT types for that account.
//
// Each NFT may be listed in one or more Listings, the validity of each
// Listing can easily be checked.
//
// Lenders can watch for Listing events and check the NFT type and
// ID to see if they wish to rent the listing on a storefront.
pub contract FlowtyRentals {

    // FlowtyRentalsInitialized
    // This contract has been deployed
    pub event FlowtyRentalsInitialized()

    // FlowtyRentalsStorefrontInitialized
    // A FlowtyRentalsStorefront resource has been created.
    // Event consumers can now expect events from this FlowtyRentalsStorefront.
    // Note that we do not specify an address: we cannot and should not.
    // Created resources do not have an owner address, and may be moved
    // after creation in ways we cannot check.
    // ListingAvailable events can be used to determine the address
    // of the owner of the FlowtyRentalsStorefront (...its location) at the time of
    // the listing but only at that precise moment in that precise transaction.
    // If the seller moves the FlowtyRentalsStorefront while the listing is valid,
    // that is on them.
    //
    pub event FlowtyRentalsStorefrontInitialized(flowtyRentalsStorefrontResourceID: UInt64)

    // FlowtyRentalsStorefrontfrontDestroyed
    // A FlowtyRentalsStorefront has been destroyed.
    // Event consumers can now stop processing events from this FlowtyRentalsStorefront.
    // Note that we do not specify an address.
    //
    pub event FlowtyRentalsStorefrontDestroyed(flowtyRentalsStorefrontResourceID: UInt64)

    // FlowtyRentalsMarketplaceInitialized
    // A FlowtyRentalsMarketplace resource has been created.
    // Event consumers can now expect events from this FlowtyRentalsMarketplace.
    // Note that we do not specify an address: we cannot and should not.
    // Created resources do not have an owner address, and may be moved
    // after creation in ways we cannot check.
    // While additional FlowtyRentalsMarketplace resources can be made, this contract will,
    // by default, access the one stored in this contract address's account. Any listing that is
    // funded will get routed to and stored there.
    //
    pub event FlowtyRentalsMarketplaceInitialized(flowtyRentalsMarketplaceResourceID: UInt64)

    // FlowtyRentalsMarketplaceDestroyed
    // A FlowtyRentalsMarketplace has been destroyed.
    // Event consumers can now stop processing events from this FlowtyRentalsMarketplace.
    // Note that we do not specify an address.
    //
    pub event FlowtyRentalsMarketplaceDestroyed(flowtyRentalsMarketplaceResourceID: UInt64)

    // ListingAvailable
    // A listing has been created and added to a FlowtyRentalsStorefront resource.
    // The address values here are valid when the event is emitted, but
    // the state of the accounts they refer to may be changed outside of the
    // FlowtyRentalsStorefront workflow, so be careful to check before using them.
    //
    pub event ListingAvailable(
        flowtyStorefrontAddress: Address,
        flowtyStorefrontID: UInt64,
        listingResourceID: UInt64,
        nftType: String,
        nftID: UInt64,
        amount: UFix64,
        deposit: UFix64,
        term: UFix64,
        royaltyRate: UFix64,
        expiresAfter: UFix64,
        paymentTokenType: String,
        renter: Address?
    )

    // ListingRented
    // A Rental has been created and added to a FlowtyRentalsStorefront resource
    // The address values here are valid when an event is emitted, but the state
    // of the accounts they refer to may be changed outside of the
    // FlowtyRentalsMarketplace workflow, so be careful to check when using them.
    //
    pub event ListingRented(
        flowtyStorefrontAddress: Address,
        flowtyStorefrontID: UInt64,
        renterAddress: Address,
        listingResourceID: UInt64,
        rentalResourceID: UInt64,
        nftID: UInt64,
        nftType: String,
        amount: UFix64,
        deposit: UFix64,
        enabledAutomaticReturn: Bool
    )

    // RentalReturned
    // A rental has been returned, releasing the deposit back to its renter
    //
    pub event RentalReturned(
        flowtyStorefrontAddress: Address,
        flowtyStorefrontID: UInt64,
        renterAddress: Address,
        listingResourceID: UInt64,
        rentalResourceID: UInt64,
        nftID: UInt64,
        nftType: String
    )

    // ListingDestroyed
    // Listing has been destroyed and has been removed from
    // the owning account's FlowtyRentalsStorefront
    //
    pub event ListingDestroyed(
        flowtyStorefrontAddress: Address,
        flowtyStorefrontID: UInt64,
        listingResourceID: UInt64,
        nftID: UInt64,
        nftType: String
    )

    // RentalSettled
        // This Rental was not returned in time, its deposit has been distributed
        // to the original owner of the rented asset and to the assets'
        // royalty beneficiaries
        //
    pub event RentalSettled(
        rentalResourceID: UInt64, 
        listingResourceID: UInt64,
        renter: Address,
        lender: Address,
        nftID: UInt64,
        nftType: String,
        deposit: UFix64
    )

    pub let FlowtyRentalsStorefrontStoragePath: StoragePath
    pub let FlowtyRentalsMarketplaceStoragePath: StoragePath
    pub let FlowtyRentalsStorefrontPublicPath: PublicPath
    pub let FlowtyRentalsMarketplacePublicPath: PublicPath
    pub let FlowtyRentalsAdminStoragePath: StoragePath

    // SuspendedFundingPeriod
    // A period of time in seconds before which
    // a listing cannot be rented.
    pub var SuspendedFundingPeriod: UFix64

    // Fee
    // Fee taken as a percentage of the initial rental fee.
    // For instance, if a rental has a fee of 10, Flowty will take a fee
    // of 10 * Fee where Fee is less than 1.
    pub var Fee: UFix64

    // ListingDetails
    // Non-resource data about a listing.
    //
    pub struct ListingDetails {
        // The ID of the storefront that this listing was made on.
        // Note that this listing cannot be transferred to another address
        pub var flowtyStorefrontID: UInt64

        // Signal indicating whether the listing has been rented or not.
        // It can only be rented once.
        pub var rented: Bool

        // The type of the nft being rented. When attempting to rent an nft,
        // a listing will check that the type of the nft being rented
        // matches nftType
        //
        pub let nftType: Type

        // The ID of the nft being rented. When attempting to rent an nft,
        // a listing will check that the ID of the nft being rented
        // matched nftID
        pub let nftID: UInt64

        // The flat fee amount collected. This amount is split when a listing is
        // rented to the owner of the listing, flowty, and royalty owners
        //
        pub let amount: UFix64

        // The deposit fee collected. This amount is returned to a renter
        // if they return the nft they rented. However, if they do not,
        // the deposit will be transferred to the original owner of the nft
        // and to the royalty recipient of the nft collection
        //
        pub let deposit: UFix64

        // The number of seconds that a rental is valid for when it is rented
        // After the term has elapsed, a rental can be settled.
        pub var term: UFix64

        // The type of FungibleToken to be accepted as payment.
        pub let paymentVaultType: Type

        // A flag to reenable the listing once it has been returned
        // This allows a user to keep a listing open in perpetuity
        // should they desire to leave it open.
        pub var reenableOnReturn: Bool

        // Contains information about how to pay owner of this listing
        access(self) let paymentCut: Flowty.PaymentCut

        // The time that this listing was created
        pub let listedTime: UFix64

        // The royalty percentage taken at the time of listing.
        pub var royaltyRate: UFix64

        // The duration that this listing is valid for. If this amount of time
        // has passed, the listing can no-longer be rented.
        pub var expiresAfter: UFix64

        // An optional parameter that can be used to prevent all addresses
        // except for the specified one to rent this listing.
        // This is how we achieve private listings.
        pub var renter: Address?

        pub fun getPaymentCut(): Flowty.PaymentCut {
            return self.paymentCut
        }

        // getTotalPayment
        // get the total amount needed to rent this listing.
        pub fun getTotalPayment(): UFix64 {
            return self.amount + self.deposit
        }

        access(contract) fun setToRented() {
            self.rented = true
        }

        init (
            nftType: Type,
            nftID: UInt64,
            amount: UFix64,
            deposit: UFix64,
            term: UFix64,
            paymentVaultType: Type,
            storefrontID: UInt64,
            paymentCut: Flowty.PaymentCut,
            expiresAfter: UFix64,
            renter: Address?
        ) {
            assert(paymentCut.amount > 0.0, message: "Listing must have non-zero requested amount")
            
            self.flowtyStorefrontID = storefrontID
            self.rented = false
            self.nftType = nftType
            self.nftID = nftID
            self.amount = amount
            self.deposit = deposit
            self.term = term
            self.paymentVaultType = paymentVaultType
            self.listedTime = getCurrentBlock().timestamp
            self.royaltyRate = Flowty.getRoyalty(nftTypeIdentifier: nftType.identifier).Rate
            self.expiresAfter = expiresAfter
            self.paymentCut = paymentCut
            self.renter = renter
            self.reenableOnReturn = false
        }
    }

    // ListingPublic
    // An inerface providing a useful public interface to a listing
    //
    pub resource interface ListingPublic {
        // borrowNFT
        // This will assert in the same way as the NFT standard borrowNFT()
        // if the NFT is absent, for example if it has been sold via another listing.
        //
        pub fun borrowNFT(): &NonFungibleToken.NFT

        // rent
        // Rent the listing. Distributing fees to all parties and taking a deposit to be held
        // until the nft is either returned or the rental defaults. A rental can be automatically returned
        // if renterNFTProvider is provided, giving us a way obtain the rented nft automatically
        // to be returned.
        pub fun rent(
            payment: @FungibleToken.Vault,
            renterFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            renterNFTCollection: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            renterNFTProvider: Capability<&AnyResource{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}>?
        )

        pub fun getDetails(): ListingDetails

        // suspensionTimeRemaining
        // returns the amount of time left until a listing can be filled.
        //
        pub fun suspensionTimeRemaining(): Fix64

        // remainingTimeToRent
        // returns the amount of time left until this listing is no longer valid
        //
        pub fun remainingTimeToRent(): Fix64

        // isRentingEnabled
        // checks if a listing can be rented or not.
        //
        pub fun isRentingEnabled(): Bool
    }

    // Listing
    // A resource that allows an NFT to be temporarily owned by another account in exchange
    // for a Fee and a Deposit.
    pub resource Listing: ListingPublic {
        // The simple (non-Capability, non-complex) details of the listing
        access(self) let details: ListingDetails

        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let nftProviderCapability: Capability<&AnyResource{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>

        // A capability allowing this resource to access the owner's NFT public collection
        access(contract) let nftPublicCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>

        // reference to the owner's fungibleTokenReceiver to pay them in the event of a settlement.
        access(contract) let ownerFungibleTokenReceiver: Capability<&AnyResource{FungibleToken.Receiver}>

        // borrowNFT
        // This will assert in the same way as the NFT standard borrowNFT()
        // if the NFT is absent, for example if it has been sold via another listing.
        //
        pub fun borrowNFT(): &NonFungibleToken.NFT {
            pre {
                self.nftProviderCapability.check(): "provider capability failed check"
            }

            let ref = self.nftProviderCapability.borrow()!.borrowNFT(id: self.getDetails().nftID)
            assert(ref.getType() == self.getDetails().nftType, message: "token has wrong type")
            assert(ref.id == self.getDetails().nftID, message: "token has wrong ID")
            return ref
        }

        // getDetails
        // Get the details of the current state of the Listing as a struct.
        // This avoids having more public variables and getter methods for them, and plays
        // nicely with scripts (which cannot return resources).
        //
        pub fun getDetails(): ListingDetails {
            return self.details
        }

        // rent
        // Rent the listing. Distributing fees to all parties and taking a deposit to be held
        // until the nft is either returned or the rental defaults. A rental can be automatically returned
        // if renterNFTProvider is provided, giving us a way obtain the rented nft automatically
        // to be returned.
        pub fun rent(
            payment: @FungibleToken.Vault,
            renterFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            renterNFTCollection: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            renterNFTProvider: Capability<&AnyResource{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}>?
        ) {
            pre {
                self.isRentingEnabled(): "Renting is not enabled or this listing has expired"
                !self.details.rented: "listing has already been rented"
                payment.getType() == self.details.paymentVaultType: "payment vault is not requested fungible token"
                Flowty.getRoyalty(nftTypeIdentifier: self.details.nftType.identifier) != nil: "royalty information not found for given collection"
                payment.balance == self.details.getTotalPayment(): "payment vault does not contain requested amount"
                self.nftProviderCapability.check(): "nftProviderCapability failed check"
                renterNFTCollection.check(): "renterNFTCollection failed check"
                renterNFTProvider == nil || renterNFTProvider!.check(): "renterNFTProvider failed check"
            }

            // handle if this listing is private or not.
            if self.details.renter != nil {
                assert(renterNFTCollection.address == self.details.renter, message: "incorrect renter address on renterNFTCollection")
                assert(renterFungibleTokenReceiver.address == self.details.renter, message: "incorrect renter address")
            }

            self.details.setToRented()

            // withdraw the NFT being rented and ensure that its type and id match the listing.
            // This protects the renter from receiving the wrong nft.
            let nft <- self.nftProviderCapability.borrow()!.withdraw(withdrawID: self.details.nftID)
            assert(nft.getType() == self.details.nftType, message: "withdrawn NFT is not of specified type")
            assert(nft.id == self.details.nftID, message: "withdrawn NFT does not have specified ID")

            // transfer the nft being rented into the renter's nft collection
            let renterCollectionCap = renterNFTCollection.borrow()!
            renterCollectionCap.deposit(token: <-nft)
            
            // set the deposit aside and calculate fee payouts for the rest
            let depositCut <- payment.withdraw(amount: self.details.deposit)
            assert(payment.balance == self.details.amount, message: "balance after deposit does not match rental amount")

            // Calculate fee amounts. First we calculate the amount sent to Flowty
            // and to the royalty recipient. The remainder goes to the listing owner.
            let flowtyFeeAmount = payment.balance * FlowtyRentals.Fee
            let royaltyFeeAmount = payment.balance * self.details.royaltyRate

            // withdraw the cuts going to flowty and our royalty recipient into their own vaults
            let flowtyFeeCut <- payment.withdraw(amount: flowtyFeeAmount)           
            let royaltyFeeCut <- payment.withdraw(amount: royaltyFeeAmount)

            // distribute the royalty, checking who should receive it and dispersing it as needed.
            let royalty = Flowty.getRoyalty(nftTypeIdentifier: self.details.nftType.identifier)
            let royaltyTokenPath = Flowty.TokenPaths[self.details.paymentVaultType.identifier]!
            let royaltyReceiver = getAccount(royalty.Address).getCapability<&AnyResource{FungibleToken.Receiver}>(royaltyTokenPath)
            FlowtyUtils.trySendFungibleTokenVault(vault: <-royaltyFeeCut, receiver: royaltyReceiver)

            // get payment cut information for the listing owner to receive payment for
            // this listing being rented.
            assert(self.details.getPaymentCut().receiver.check(), message: "paymentCut receiver failed check")
            let receiver = self.details.getPaymentCut().receiver.borrow()!
            receiver.deposit(from: <-payment)

            // get the path and corresponding capability to send fees to the Flowty account
            let tokenPaths = Flowty.getTokenPaths()
            let feeTokenPath = tokenPaths[self.details.paymentVaultType.identifier]!
            let flowtyFeeReceiver = FlowtyRentals.account.getCapability<&AnyResource{FungibleToken.Receiver}>(feeTokenPath).borrow()!
            flowtyFeeReceiver.deposit(from: <-flowtyFeeCut)

            // create the Rental resource on the Flowty accounts' marketplace
            let listingResourceID = self.uuid
            let marketplace = FlowtyRentals.borrowMarketplace()
            let rentalResourceID = marketplace.createRental(
                storefrontID: self.details.flowtyStorefrontID,
                listingResourceID: listingResourceID,
                nftID: self.details.nftID,
                nftType: self.details.nftType,
                paymentVaultType: self.details.paymentVaultType,
                term: self.details.term,
                listingDetails: self.details,
                ownerNFTCollectionPublic: self.nftPublicCollectionCapability,
                ownerFungibleTokenReceiver: self.ownerFungibleTokenReceiver,
                renterFungibleTokenReceiver: renterFungibleTokenReceiver,
                depositedFungibleTokens: <-depositCut,
                renterNFTCollection: renterNFTCollection,
                renterNFTProvider: renterNFTProvider
            )

            // check if automatic return has been enabled by renter.
            let enabledAutomaticReturn = renterNFTProvider != nil

            emit ListingRented(
                flowtyStorefrontAddress: self.owner!.address,
                flowtyStorefrontID: self.details.flowtyStorefrontID,
                renterAddress: renterNFTCollection.address,
                listingResourceID: listingResourceID,
                rentalResourceID: rentalResourceID,
                nftID: self.details.nftID,
                nftType: self.details.nftType.identifier,
                amount: self.details.amount,
                deposit: self.details.deposit,
                enabledAutomaticReturn: enabledAutomaticReturn
            )
        }
        
        // suspensionTimeRemaining
        // returns the amount of time left until a listing can be filled.
        //
        pub fun suspensionTimeRemaining() : Fix64 {
            let listedTime = self.details.listedTime
            let currentTime = getCurrentBlock().timestamp

            let remaining = Fix64(listedTime + Flowty.SuspendedFundingPeriod) - Fix64(currentTime)

            return remaining
        }

        // remainingTimeToRent
        // returns the amount of time left until this listing is no longer valid
        //
        pub fun remainingTimeToRent(): Fix64 {
            let listedTime = self.details.listedTime
            let currentTime = getCurrentBlock().timestamp
            let remaining = Fix64(listedTime + self.details.expiresAfter) - Fix64(currentTime)
            return remaining
        }

        // isRentingEnabled
        // checks if a listing can be rented or not.
        //
        pub fun isRentingEnabled(): Bool {
            let timeRemaining = self.suspensionTimeRemaining()
            let listingTimeRemaining = self.remainingTimeToRent()
            return timeRemaining < Fix64(0.0) && listingTimeRemaining > Fix64(0.0)
        }

        init (
            nftProviderCapability: Capability<&AnyResource{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftPublicCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            ownerFungibleTokenReceiver: Capability<&AnyResource{FungibleToken.Receiver}>,
            nftType: Type,
            nftID: UInt64,
            amount: UFix64,
            deposit: UFix64,
            term: UFix64,
            paymentVaultType: Type,
            paymentCut: Flowty.PaymentCut,
            storefrontID: UInt64,
            expiresAfter: UFix64,
            renter: Address?
        ) {
            pre {
                nftProviderCapability.check(): "nftProviderCapability failed check"
                nftPublicCollectionCapability.check(): "nftPublicCollectionCapability failed check"
                ownerFungibleTokenReceiver.check(): "ownerFungibleTokenReceiver failed check"
            }

            self.details = ListingDetails(
                nftType: nftType,
                nftID: nftID,
                amount: amount,
                deposit: deposit,
                term: term,
                paymentVaultType: paymentVaultType,
                storefrontID: storefrontID,
                paymentCut: paymentCut,
                expiresAfter: expiresAfter,
                renter: renter
            )
            self.nftProviderCapability = nftProviderCapability
            self.nftPublicCollectionCapability = nftPublicCollectionCapability
            self.ownerFungibleTokenReceiver = ownerFungibleTokenReceiver
            let provider = self.nftProviderCapability.borrow()!

            let nft = provider.borrowNFT(id: self.details.nftID)
            assert(nft.getType() ==self.details.nftType, message: "token is not of specified type")
            assert(nft.id == self.details.nftID, message: "token does not have specified ID")
        }

        destroy() {
            emit ListingDestroyed(
                flowtyStorefrontAddress: self.ownerFungibleTokenReceiver.address,
                flowtyStorefrontID: self.details.flowtyStorefrontID,
                listingResourceID: self.uuid,
                nftID: self.details.nftID,
                nftType: self.details.nftType.identifier
            )
        }

    }

    // Rental Details
    // A struct containing a Rental's non-resource data.
    pub struct RentalDetails {
        // |-- gathered by an initialized Rental resource --|
        // The storefront which owns this rental.
        pub var flowtyStorefrontID: UInt64
        // The listing being funded
        pub var listingResourceID: UInt64
        // They type used for payment to obtain the rental.
        // Tokens taken as a deposit are also made of this type
        pub var paymentVaultType: Type

        // The number of seconds that this rental is good for.
        // If the rental is not returned before this time, the deposit can be revoked
        pub var term: UFix64

        // The id of the nft that was rented. This is the same as listingDetails.nftID
        pub var nftID: UInt64

        // The type of the nft that was rented. This is the same as listingDetails.nftType
        pub var nftType: Type

        // |-- The below variables are maintained by our smart contract --|
        pub var returned: Bool
        pub var settled: Bool

        // The time this Rental was created
        pub var startTime: UFix64

        access(contract) fun setToReturned() {
            self.returned = true
        }

        access(contract) fun setToSettled() {
            self.settled = true
        }

        init (
            flowtyStorefrontID: UInt64,
            listingResourceID: UInt64,
            paymentVaultType: Type,
            nftType: Type,
            nftID: UInt64,
            term: UFix64
        ) {
            self.flowtyStorefrontID = flowtyStorefrontID
            self.listingResourceID = listingResourceID
            self.nftType = nftType
            self.nftID = nftID
            self.term = term
            self.paymentVaultType = paymentVaultType

            self.startTime = getCurrentBlock().timestamp
            self.returned = false
            self.settled = false
        }
    }

    // RentalPublic
    // An interface providing a useful public interface to a Rental.
    //
    pub resource interface RentalPublic {
        // The entry point method to return a rental.
        // The same NFT as the one that was rented must be returned.
        pub fun returnNFT(nft: @NonFungibleToken.NFT)

        // Return the details of this Rental
        pub fun getDetails(): RentalDetails

        // Return the listingDetails that were used to create this rental
        pub fun getListingDetails(): FlowtyRentals.ListingDetails

        // How much time is left until this Rental has expired
        pub fun timeRemaining() : Fix64

        // Whether this rental has expired and can be settled
        pub fun isRentalExpired(): Bool
    }

    // The resource used to represent a Rental.
    // A Rental contains the deposit held in exchange for an NFT
    // If that same NFT is returned, the deposit is released back to the renter.
    pub resource Rental: RentalPublic {
        // The non-resource data of a Rental
        access(self) let details: RentalDetails

        // The details of the listing that was rented
        access(self) let listingDetails: ListingDetails

        // Tokens held as a deposit
        access(contract) var depositedFungibleTokens: @FungibleToken.Vault?

        // reference to the original owner of the nft which was rented
        access(contract) let ownerNFTCollectionPublic: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        // reference to pay the original owner in the event that the rented NFT is not returned
        access(contract) let ownerFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>

        // Used to return the deposit held when the Rental was made
        access(contract) let renterFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>

        // Capability used to transfer the rented nft to our renter
        access(contract) let renterNFTCollection: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>

        // optional capability to automatically return the asset on settlement
        access(contract) let renterNFTProvider: Capability<&AnyResource{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}>?

        init (
            // Rental details
            storefrontID: UInt64,
            listingResourceID: UInt64,
            paymentVaultType: Type,
            term: UFix64,
            nftID: UInt64,
            nftType: Type,
            listingDetails: ListingDetails,

            // Rental resource
            ownerNFTCollectionPublic: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            renterFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            ownerFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            depositedFungibleTokens: @FungibleToken.Vault?,
            renterNFTCollection: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            renterNFTProvider: Capability<&AnyResource{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}>?
        ) {
            self.ownerNFTCollectionPublic = ownerNFTCollectionPublic
            self.renterFungibleTokenReceiver = renterFungibleTokenReceiver
            self.ownerFungibleTokenReceiver = ownerFungibleTokenReceiver
            self.depositedFungibleTokens <- depositedFungibleTokens
            self.renterNFTProvider = renterNFTProvider

            self.renterNFTCollection = renterNFTCollection
            self.listingDetails = listingDetails

            self.details = RentalDetails(
                flowtyStorefrontID: storefrontID,
                listingResourceID: listingResourceID,
                paymentVaultType: paymentVaultType,
                nftType: nftType,
                nftID: nftID,
                term: term
            )
        }

        pub fun getDetails(): RentalDetails {
            return self.details
        }

        pub fun getListingDetails(): ListingDetails {
            return self.listingDetails
        }

        // The entry point method to return a rental.
        // The same NFT as the one that was rented must be returned.
        pub fun returnNFT(nft: @NonFungibleToken.NFT) {
            pre {
                !self.isRentalExpired(): "rental has expired"
                !self.details.returned: "rental has been returned"
                nft.getType() == self.details.nftType: "returned nft has the wrong type"
                nft.id == self.details.nftID: "incorrect nftID"
            }

            // withdraw the deposited tokens when the rental was created
            let deposit <- self.depositedFungibleTokens <- nil

            self.details.setToReturned()

            // get the fungibleToken vault capable of receiving the deposit so it can be returned
            FlowtyUtils.trySendFungibleTokenVault(vault: <-deposit!, receiver: self.renterFungibleTokenReceiver)

            // return the nft to the owner's collection
            FlowtyUtils.trySendNFT(nft: <-nft, receiver: self.ownerNFTCollectionPublic)
            
            emit RentalReturned(
                flowtyStorefrontAddress: self.ownerFungibleTokenReceiver.address,
                flowtyStorefrontID: self.details.flowtyStorefrontID,
                renterAddress: self.renterFungibleTokenReceiver.address,
                listingResourceID: self.details.listingResourceID,
                rentalResourceID: self.uuid,
                nftID: self.details.nftID,
                nftType: self.details.nftType.identifier
            )
        }

        // settleRental can only be executed after the rental has expired.
        // If the Renter supplied an optional provider which we can withdraw the NFT with,
        // Then we will attempt to automatically take the NFT back. If this is possible, the deposit will
        // be returned to the renter.
        pub fun settleRental() {
            pre {
                self.isRentalExpired(): "rental hasn't expired"
                self.details.returned == false: "rental has already been returned"
                self.details.settled == false: "rental has already been settled"
            }

            // check if we can automatically return the NFT
            // do we have a provider?
            if self.renterNFTProvider != nil {
                // borrow it.
                if self.renterNFTProvider!.check() {
                    let renterNFTProvider = self.renterNFTProvider!.borrow()!
                    // does this NFT Collection have the ID that we need to withdraw?
                    let ids = renterNFTProvider.getIDs()
                    if ids.contains(self.details.nftID) {
                        let borrowedNFT = renterNFTProvider.borrowNFT(id: self.details.nftID)
                        if borrowedNFT != nil && borrowedNFT.getType() == self.details.nftType && borrowedNFT.id == self.details.nftID {
                            let nft <- renterNFTProvider.withdraw(withdrawID: self.details.nftID)
                            if nft.getType() == self.details.nftType && nft.id == self.details.nftID {
                                FlowtyUtils.trySendNFT(nft: <-nft, receiver: self.ownerNFTCollectionPublic)

                                let deposit <- self.depositedFungibleTokens <- nil
                                FlowtyUtils.trySendFungibleTokenVault(vault: <-deposit!, receiver: self.renterFungibleTokenReceiver)

                                // it worked! the nft is returned
                                self.details.setToReturned()

                                emit RentalReturned(
                                    flowtyStorefrontAddress: self.ownerFungibleTokenReceiver.address,
                                    flowtyStorefrontID: self.details.flowtyStorefrontID,
                                    renterAddress: self.renterFungibleTokenReceiver.address,
                                    listingResourceID: self.details.listingResourceID,
                                    rentalResourceID: self.uuid,
                                    nftID: self.details.nftID,
                                    nftType: self.details.nftType.identifier
                                )
                                return
                            } else {
                                // this path should only be able to be reached intentionally. At that point, we won't know if the
                                // receiver is setup properly to receive the borrowed item back or not so we should just make a coatcheck 
                                // item for them and move on. If they can mess with a borrowed item returning a type that is different than 
                                // the actual withdrawn nft, they can handle redeeming their item back in the coatcheck contract.
                                let valet = CoatCheck.getValet()
                                let nfts: @[NonFungibleToken.NFT] <- []
                                nfts.append(<-nft)
                                valet.createTicket(redeemer: self.renterFungibleTokenReceiver.address, vaults: nil, tokens: <-nfts)
                            }
                        }
                    }
                }
            }

            // we couldn't return the nft, settle it.
            self.details.setToSettled()

            if self.depositedFungibleTokens != nil {
                // calculate the amounts to send to the owner and royalty
                let vault <- self.depositedFungibleTokens <- nil
                let amount = vault?.balance ?? panic("nil vault")
                let royaltyFeeAmount = amount * self.listingDetails.royaltyRate
                let ownerAmount = amount * (1.0 - self.listingDetails.royaltyRate)

                // get the vaults for payment
                let royaltyFeeCut <- vault?.withdraw(amount: royaltyFeeAmount)
                let ownerCut <- vault?.withdraw(amount: ownerAmount)

                // distribute the royalty
                let royalty = Flowty.getRoyalty(nftTypeIdentifier: self.details.nftType.identifier)
                let royaltyTokenPath = Flowty.TokenPaths[self.details.paymentVaultType.identifier]!
                let royaltyReceiver = getAccount(royalty.Address).getCapability<&AnyResource{FungibleToken.Receiver}>(royaltyTokenPath)

                FlowtyUtils.trySendFungibleTokenVault(vault: <-royaltyFeeCut!, receiver: royaltyReceiver)

                // distribute the rest to the original owner
                FlowtyUtils.trySendFungibleTokenVault(vault: <-ownerCut!, receiver: self.listingDetails.getPaymentCut().receiver)
                destroy vault
            }

            emit RentalSettled(
                rentalResourceID: self.uuid, 
                listingResourceID: self.details.listingResourceID,
                renter: self.renterFungibleTokenReceiver.address,
                lender: self.ownerFungibleTokenReceiver.address,
                nftID: self.details.nftID,
                nftType: self.details.nftType.identifier,
                deposit: self.listingDetails.deposit
            )
        }

        destroy() {
            pre {
                self.details.settled || self.details.returned: "rental must be returned or settled to be destroyed"
                self.depositedFungibleTokens?.balance == 0.0: "deposit balance is not 0"
            }          
            
            if self.depositedFungibleTokens != nil {
                let deposit <- self.depositedFungibleTokens <- nil
                destroy deposit
            }  
            
            destroy self.depositedFungibleTokens
        }

        // how much time is left to return this rental
        pub fun timeRemaining() : Fix64 {
            let rentalTerm = self.details.term
            let startTime = self.details.startTime
            let currentTime = getCurrentBlock().timestamp
            let remaining = Fix64(startTime + rentalTerm) - Fix64(currentTime)
            return remaining
        }

        pub fun isRentalExpired() : Bool {
            return self.timeRemaining() < Fix64(0.0)
        }
    }

    // FlowtyRentalsMarketplaceManager
    // An interface for adding and removing rental resources within a FlowtyRentalsMarketplace,
    //
    pub resource interface FlowtyRentalsMarketplaceManager {
        // createFunding
        // Allows the FlowtyRentalsMarketplace owner to create and insert Fundings.
        //
        access(contract) fun createRental(
            storefrontID: UInt64, 
            listingResourceID: UInt64,
            nftID: UInt64,
            nftType: Type,
            paymentVaultType: Type,
            term: UFix64,
            listingDetails: ListingDetails,
            ownerNFTCollectionPublic: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            ownerFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            renterFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            depositedFungibleTokens: @FungibleToken.Vault?,
            renterNFTCollection: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            renterNFTProvider: Capability<&AnyResource{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}>?
        ): UInt64
        // removeRental
        // Allows the FlowtyRentalsMarketplace owner to remove any rental resource.
        //
        pub fun removeRental(rentalResourceID: UInt64)

        pub fun borrowPrivateRental(rentalResourceID: UInt64): &Rental?
    }

    pub resource interface FlowtyRentalsMarketplacePublic {
        pub fun getRentalIDs(): [UInt64]
        pub fun borrowRental(rentalResourceID: UInt64): &Rental{RentalPublic}?
    }

    pub resource FlowtyRentalsMarketplace: FlowtyRentalsMarketplaceManager, FlowtyRentalsMarketplacePublic { 
        access(self) var rentals: @{UInt64: Rental}

        // create a rental and store it on our contract marketplace
        access(contract) fun createRental(
            storefrontID: UInt64, 
            listingResourceID: UInt64,
            nftID: UInt64,
            nftType: Type,
            paymentVaultType: Type,
            term: UFix64,
            listingDetails: ListingDetails,
            ownerNFTCollectionPublic: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            ownerFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            renterFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
            depositedFungibleTokens: @FungibleToken.Vault?,
            renterNFTCollection: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            renterNFTProvider: Capability<&AnyResource{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}>?
         ): UInt64 {
            let renter = renterFungibleTokenReceiver.address
            let owner = ownerNFTCollectionPublic.address

            // Create funding resource
            let rental <- create Rental(
                storefrontID: storefrontID,
                listingResourceID: listingResourceID,
                paymentVaultType: paymentVaultType,
                term: term,
                nftID: nftID,
                nftType: nftType,
                listingDetails: listingDetails,
                ownerNFTCollectionPublic: ownerNFTCollectionPublic,
                renterFungibleTokenReceiver: renterFungibleTokenReceiver,
                ownerFungibleTokenReceiver: ownerFungibleTokenReceiver,
                depositedFungibleTokens: <-depositedFungibleTokens,
                renterNFTCollection: renterNFTCollection,
                renterNFTProvider: renterNFTProvider
            )

            let rentalResourceID = rental.uuid

            // set the rental item here so we can reference it later
            let oldRental <- self.rentals[rentalResourceID] <- rental
            
            // Note that oldRental will always be nil, but we have to handle it.
            destroy oldRental
            return rentalResourceID
        }

        // removes a rental from our contract
        pub fun removeRental(rentalResourceID: UInt64) {
            let rental <- self.rentals.remove(key: rentalResourceID)
                ?? panic("missing Rental")
    
            assert(rental.getDetails().returned == true || rental.getDetails().settled == true, message: "rental is not returned or settled")


            destroy rental
        }

        pub fun getRentalIDs(): [UInt64] {
            return self.rentals.keys
        }

        pub fun borrowRental(rentalResourceID: UInt64): &Rental{RentalPublic}? {
            if self.rentals[rentalResourceID] != nil {
                return &self.rentals[rentalResourceID] as &Rental{RentalPublic}?
            } else {
                return nil
            }
        }

        pub fun borrowPrivateRental(rentalResourceID: UInt64): &Rental? {
            if self.rentals[rentalResourceID] != nil {
                return &self.rentals[rentalResourceID] as &Rental?
            } else {
                return nil
            }
        }

        destroy () {
            destroy self.rentals

            // Let event consumers know that this marketplace will no longer exist
            emit FlowtyRentalsMarketplaceDestroyed(flowtyRentalsMarketplaceResourceID: self.uuid)
        }

        init () {
            self.rentals <- {}

            // Let event consumers know that this storefront exists
            emit FlowtyRentalsMarketplaceInitialized(flowtyRentalsMarketplaceResourceID: self.uuid)
        }
    }

    pub resource interface FlowtyRentalsStorefrontManager {
        pub fun createListing(
            nftProviderCapability: Capability<&AnyResource{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftPublicCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            ownerFungibleTokenReceiver: Capability<&AnyResource{FungibleToken.Receiver}>,
            nftType: Type,
            nftID: UInt64,
            amount: UFix64,
            deposit: UFix64,
            term: UFix64,
            paymentVaultType: Type,
            paymentCut: Flowty.PaymentCut,
            expiresAfter: UFix64,
            renter: Address?
        ): UInt64

        pub fun removeListing(listingResourceID: UInt64)
    }

    pub resource interface FlowtyRentalsStorefrontPublic {
        pub fun getListingIDs(): [UInt64]
        pub fun borrowListing(listingResourceID: UInt64): &Listing{ListingPublic}?
        pub fun cleanup(listingResourceID: UInt64)
   }

   // FlowtyRentalsStorefront -  The storefront which stores listing and provides functionality to fill them
   // A listing records the an nftid and type, a fee and deposit, and an optional address.
   pub resource FlowtyRentalsStorefront : FlowtyRentalsStorefrontManager, FlowtyRentalsStorefrontPublic {
       access(self) var listings: @{UInt64: Listing}

       // create a new listing. Takes in a provider to withdraw the listed nft, and details
       // about the terms of the rental and ways to send out payment
       pub fun createListing(
            nftProviderCapability: Capability<&AnyResource{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftPublicCollectionCapability: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>,
            ownerFungibleTokenReceiver: Capability<&AnyResource{FungibleToken.Receiver}>,
            nftType: Type,
            nftID: UInt64,
            amount: UFix64,
            deposit: UFix64,
            term: UFix64,
            paymentVaultType: Type,
            paymentCut: Flowty.PaymentCut,
            expiresAfter: UFix64,
            renter: Address?
         ): UInt64 {
             pre {
                FlowtyUtils.isTokenSupported(type: paymentVaultType): "provided payment type is not supported"
                Flowty.SupportedCollections[nftType.identifier] != nil : "nftType is not supported"
                paymentCut.receiver.check() && paymentCut.receiver.borrow()!.getType() == paymentVaultType: "paymentCut receiver type and paymentVaultType do not match"
            }

            // create the listing
            let listing <- create Listing(
                nftProviderCapability: nftProviderCapability,
                nftPublicCollectionCapability: nftPublicCollectionCapability,
                ownerFungibleTokenReceiver: ownerFungibleTokenReceiver,
                nftType: nftType,
                nftID: nftID,
                amount: amount,
                deposit: deposit,
                term: term,
                paymentVaultType: paymentVaultType,
                paymentCut: paymentCut,
                storefrontID: self.uuid,
                expiresAfter: expiresAfter,
                renter: renter
            )

            let listingResourceID = listing.uuid
            let royaltyRate = listing.getDetails().royaltyRate
            let expiration = listing.getDetails().expiresAfter

            // Add the new listing to the dictionary.
            let oldListing <- self.listings[listingResourceID] <- listing
            // Note that oldListing will always be nil, but we have to handle it.
            destroy oldListing

            emit ListingAvailable(
                flowtyStorefrontAddress: self.owner!.address,
                flowtyStorefrontID: self.uuid,
                listingResourceID: listingResourceID,
                nftType: nftType.identifier,
                nftID: nftID,
                amount: amount,
                deposit: deposit,
                term: term,
                royaltyRate: royaltyRate,
                expiresAfter: expiration,
                paymentTokenType: paymentVaultType.identifier,
                renter: renter
            )

            return listingResourceID
        }

        pub fun removeListing(listingResourceID: UInt64) {
            let listing <- self.listings.remove(key: listingResourceID)
                ?? panic("missing Listing")
    
            destroy listing
        }

        pub fun getListingIDs(): [UInt64] {
            return self.listings.keys
        }

        pub fun borrowListing(listingResourceID: UInt64): &Listing{ListingPublic}? {
            if self.listings[listingResourceID] != nil {
                return &self.listings[listingResourceID] as &Listing{ListingPublic}?
            } else {
                return nil
            }
        }

        pub fun cleanup(listingResourceID: UInt64) {
            pre {
                self.listings[listingResourceID] != nil: "could not find listing with given id"
            }

            let listing <- self.listings.remove(key: listingResourceID)!
            assert(listing.getDetails().rented == true, message: "listing is not rented, only admin can remove")
            destroy listing
        }

        destroy () {
            destroy self.listings

            // Let event consumers know that this storefront will no longer exist
            emit FlowtyRentalsStorefrontDestroyed(flowtyRentalsStorefrontResourceID: self.uuid)
        }

        init () {
            self.listings <- {}

            // Let event consumers know that this storefront exists
            emit FlowtyRentalsStorefrontInitialized(flowtyRentalsStorefrontResourceID: self.uuid)
        }
   }

   pub resource FlowtyAdmin {
        pub fun setFees(fee: UFix64) {
            pre {
                fee <= 1.0: "rental is a percentage"
            }

            FlowtyRentals.Fee = fee
        }
    }

    pub fun createStorefront(): @FlowtyRentalsStorefront {
        return <-create FlowtyRentalsStorefront()
    }

    access(account) fun borrowMarketplace(): &FlowtyRentals.FlowtyRentalsMarketplace {
        return self.account.borrow<&FlowtyRentals.FlowtyRentalsMarketplace>(from: FlowtyRentals.FlowtyRentalsMarketplaceStoragePath)!
    }

    pub resource FlowtyRentalsAdmin {
        pub fun setFees(rentalFee: UFix64) {
            pre {
                rentalFee <= 1.0: "Funding fee should be a percentage"
            }

            FlowtyRentals.Fee = rentalFee
        }

        pub fun setSuspendedFundingPeriod(period: UFix64) {
            FlowtyRentals.SuspendedFundingPeriod = period
        }
     }

    init () {
        self.FlowtyRentalsStorefrontStoragePath = /storage/FlowtyRentalsStorefront
        self.FlowtyRentalsStorefrontPublicPath = /public/FlowtyRentalsStorefront
        self.FlowtyRentalsMarketplaceStoragePath = /storage/FlowtyRentalsMarketplace
        self.FlowtyRentalsMarketplacePublicPath = /public/FlowtyRentalsMarketplace
        self.FlowtyRentalsAdminStoragePath = /storage/FlowtyRentalsAdmin
        
        self.Fee = 0.05 // Percentage of the rental amount taken as a fee
        self.SuspendedFundingPeriod = 300.0 // Period in seconds until the listing is valid

        let marketplace <- create FlowtyRentalsMarketplace()

        self.account.save(<-marketplace, to: self.FlowtyRentalsMarketplaceStoragePath) 
        self.account.link<&FlowtyRentals.FlowtyRentalsMarketplace{FlowtyRentals.FlowtyRentalsMarketplacePublic}>(FlowtyRentals.FlowtyRentalsMarketplacePublicPath, target: FlowtyRentals.FlowtyRentalsMarketplaceStoragePath)

        // FlowtyAdmin
        let flowtyAdmin <- create FlowtyRentalsAdmin()
        self.account.save(<-flowtyAdmin, to: self.FlowtyRentalsAdminStoragePath)

        emit FlowtyRentalsInitialized()
    }
}
