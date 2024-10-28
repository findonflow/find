import "FungibleToken"
import "FlowToken"

/// The Flow blockchain contract for the Band Protocol Oracle.
/// https://docs.bandchain.org/
///
access(all) contract BandOracle {

    /// Paths

    // OracleAdmin resource path.
    access(all) let OracleAdminStoragePath: StoragePath

    // Relay resource path.
    access(all) let RelayStoragePath: StoragePath

    // FeeCollector resource path.
    access(all) let FeeCollectorStoragePath: StoragePath


    /// Fields

    // String as base private path for data updater capabilities.
    access(contract) let dataUpdaterBasePath: String

    // Mapping from symbol to data struct.
    access(contract) let symbolsRefData: {String: RefData}

    // Aux constant for holding the 10^18 value.
    access(all) let e18: UInt256

    // Aux constant for holding the 10^9 value.
    access(all) let e9: UInt256

    // Vault for storing service fees.
    access(contract) let payments: @{FungibleToken.Vault}

    // Service fee per request.
    access(contract) var fee: UFix64

    // Mapping of Relayer address to their issued capability ID
    access(contract) let relayersCapabilityID: {Address: UInt64}


    /// Events

    // Emitted when a relayer updates a set of symbols.
    access(all) event BandOracleSymbolsUpdated(symbols: [String], relayerID: UInt64, requestID: UInt64)

    // Emitted when a symbol is removed from the oracle.
    access(all) event BandOracleSymbolRemoved(symbol: String)

    // Emitted when fees are collected.
    access(all) event FeesCollected(amount: UFix64, to: Address?, collectorUUID: UInt64, collectorAddress: Address)

    // Emitted when fees are updated.
    access(all) event FeeUpdated(old: UFix64, new: UFix64)


    /// Structs

    /// Structure for storing any symbol USD-rate.
    ///
    access(all) struct RefData {
        /// USD-rate, multiplied by 1e9.
        access(all) var rate: UInt64
        /// UNIX epoch when data is last resolved. 
        access(all) var timestamp: UInt64
        /// BandChain request identifier for this data.
        access(all) var requestID: UInt64

        init(rate: UInt64, timestamp: UInt64, requestID: UInt64) {
            self.rate = rate
            self.timestamp = timestamp
            self.requestID = requestID
        }
    }

    /// Structure for consuming data as quote / base symbols.
    ///
    access(all) struct ReferenceData {
        /// Base / quote symbols rate multiplied by 10^18.
        access(all) var integerE18Rate: UInt256
        /// Base / quote symbols rate as a fixed point number.
        access(all) var fixedPointRate: UFix64
        /// UNIX epoch when base data is last resolved. 
        access(all) var baseTimestamp: UInt64
        /// UNIX epoch when quote data is last resolved. 
        access(all) var quoteTimestamp: UInt64

        init(rate: UInt256, baseTimestamp: UInt64, quoteTimestamp: UInt64) {
            self.integerE18Rate = rate
            self.fixedPointRate = BandOracle.e18ToFixedPoint(rate: rate)
            self.baseTimestamp = baseTimestamp
            self.quoteTimestamp = quoteTimestamp
        }
    }


    /// Resources

    /// Admin only operations.
    ///
    access(all) resource interface OracleAdmin {
        access(all) fun setRelayerCapabilityID (relayer: Address, capabilityID: UInt64)
        access(all) fun removeRelayerCapabilityID (relayer: Address)
        access(all) fun getUpdaterCapabilityIDFromAddress (relayer: Address): UInt64?
        access(all) fun removeSymbol (symbol: String)
        access(all) fun createNewFeeCollector (): @BandOracle.FeeCollector
    }

    /// Relayer operations.
    ///
    access(all) resource interface DataUpdater {
        access(all) fun updateData (symbolsRates: {String: UInt64}, resolveTime: UInt64, 
        requestID: UInt64, relayerID: UInt64)
        access(all) fun forceUpdateData (symbolsRates: {String: UInt64}, resolveTime: UInt64, 
        requestID: UInt64, relayerID: UInt64)
    }

    /// The `BandOracleAdmin` will be created on the contract deployment, and will allow 
    /// the own admin to manage the oracle and the relayers to update prices on it.
    ///
    access(all) resource BandOracleAdmin: OracleAdmin, DataUpdater {

        /// Stores in contract the data updater capability ID along with the address
        /// of the relayer who got the capability
        ///
        /// @param relayer: The entitled relayer account address
        /// @param capabilityID: The ID of the data updater capability
        ///
        access(all) fun setRelayerCapabilityID (relayer: Address, capabilityID: UInt64) {
            BandOracle.relayersCapabilityID[relayer] = capabilityID
        }

        /// Deletes a relayer's CapabilityID from `BandOracle.relayersCapabilityID` mapping for traceability purposes
        /// NOTE: Does not revoke the underlying Capability - this must be done in a separate call from the issuing account
        ///
        /// @param relayer: The entitled relayer account address
        ///
        access(all) fun removeRelayerCapabilityID (relayer: Address) {
            BandOracle.relayersCapabilityID.remove(key: relayer)
        }

        /// Method to retrieve the data updater capability ID from the relayer
        ///
        /// @param relayer: The entitled relayer account address
        ///
        access(all) fun getUpdaterCapabilityIDFromAddress (relayer: Address): UInt64? {
            return BandOracle.relayersCapabilityID[relayer]
        }

        /// Removes a symbol and its quotes from the contract storage.
        ///
        /// @param symbol: The string representing the symbol to be removed from the contract.
        ///
        access(all) fun removeSymbol (symbol: String) {
            BandOracle.removeSymbol(symbol: symbol)
        }

        /// Relayers can call this method to update rates.
        ///
        /// @param symbolsRates: Set of symbols and corresponding usd rates to update.
        /// @param resolveTime: The registered time for the rates.
        /// @param requestID: The Band Protocol request ID.
        /// @param relayerID: The ID of the relayer carrying the update.
        ///
        access(all) fun updateData (symbolsRates: {String: UInt64}, resolveTime: UInt64, 
        requestID: UInt64, relayerID: UInt64) {
            BandOracle.updateRefData(symbolsRates: symbolsRates, resolveTime: resolveTime, 
            requestID: requestID, relayerID: relayerID)
        }

        /// Relayers can call this method to force update rates.
        ///
        /// @param symbolsRates: Set of symbols and corresponding usd rates to update.
        /// @param resolveTime: The registered time for the rates.
        /// @param requestID: The Band Protocol request ID.
        /// @param relayerID: The ID of the relayer carrying the update.
        ///
        access(all) fun forceUpdateData (symbolsRates: {String: UInt64}, resolveTime: UInt64, 
        requestID: UInt64, relayerID: UInt64) {
            BandOracle.forceUpdateRefData(symbolsRates: symbolsRates, resolveTime: resolveTime, 
            requestID: requestID, relayerID: relayerID)
        }

        /// Creates a fee collector, meant to be called once after contract deployment
        /// for storing the resource on the maintainer's account.
        ///
        /// @return The `FeeCollector` resource
        ///
        access(all) fun createNewFeeCollector (): @FeeCollector {
            return <- create FeeCollector()
        }

    }

    /// The resource that will allow an account to make quote updates
    ///
    access(all) resource Relay {

        // Capability linked to the OracleAdmin allowing relayers to relay rate updates
        access(self) let updaterCapability: Capability<&{DataUpdater}>

        /// Relay updated rates to the Oracle Admin
        ///
        /// @param symbolsRates: Set of symbols and corresponding usd rates to update.
        /// @param resolveTime: The registered time for the rates.
        /// @param requestID: The Band Protocol request ID.
        ///
        access(all) fun relayRates (symbolsRates: {String: UInt64}, resolveTime: UInt64, requestID: UInt64) {
            let updaterRef = self.updaterCapability.borrow() 
            ?? panic ("Can't borrow reference to data updater while processing request ".concat(requestID.toString()))
            updaterRef.updateData(symbolsRates: symbolsRates, resolveTime: resolveTime, requestID: requestID, relayerID: self.uuid)
        }

        /// Relay updated rates to the Oracle Admin forcing the update of the symbols even if the `resolveTime` is older than the last update.
        ///
        /// @param symbolsRates: Set of symbols and corresponding usd rates to update.
        /// @param resolveTime: The registered time for the rates.
        /// @param requestID: The Band Protocol request ID.
        ///
        access(all) fun forceRelayRates (symbolsRates: {String: UInt64}, resolveTime: UInt64, requestID: UInt64) {
            let updaterRef = self.updaterCapability.borrow() 
            ?? panic ("Can't borrow reference to data updater while processing request ".concat(requestID.toString()))
            updaterRef.forceUpdateData(symbolsRates: symbolsRates, resolveTime: resolveTime, requestID: requestID, relayerID: self.uuid)
        }

        init(updaterCapability: Capability<&{DataUpdater}>) {
            self.updaterCapability = updaterCapability
            let updaterRef = self.updaterCapability.borrow() 
            ?? panic ("Can't borrow linked updater")
        }
    }

    /// The resource that allows the maintainer account to charge a fee for the use of the oracle.
    ///
    access(all) resource FeeCollector {

        /// Sets the fee in Flow tokens for the oracle use.
        ///
        /// @param fee: The amount of Flow tokens.
        ///
        access(all) fun setFee (fee: UFix64) {
            BandOracle.setFee(fee: fee)
            emit FeeUpdated(old: BandOracle.fee, new: fee)
        }

        /// Extracts the fees from the contract's vault.
        /// 
        /// @return A vault containing the funds obtained for the oracle use.
        ///
        access(all) fun collectFees (receiver: &{FungibleToken.Receiver}) {
            let fees <- BandOracle.collectFees()
            emit FeesCollected(amount: fees.balance, to: receiver.owner?.address, collectorUUID: self.uuid, collectorAddress: self.owner!.address)
            receiver.deposit(from: <-fees)
        }

    }


    /// Functions

    /// Aux access(contract) functions

    /// Auxiliary private function for the `OracleAdmin` to update the rates.
    ///
    /// @param symbolsRates: Set of symbols and corresponding usd rates to update.
    /// @param resolveTime: The registered time for the rates.
    /// @param requestID: The Band Protocol request ID.
    /// @param relayerID: The ID of the relayer carrying the update.
    ///
    access(contract) fun updateRefData (symbolsRates: {String: UInt64}, resolveTime: UInt64, requestID: UInt64, relayerID: UInt64) {
        let updatedSymbols: [String] = []
        // For each symbol rate relayed
        for symbol in symbolsRates.keys {
            // If the symbol hasn't stored rates yet, or the stored records are older
            // than the new relayed rates
            if (BandOracle.symbolsRefData[symbol] == nil ) ||
            (BandOracle.symbolsRefData[symbol]!.timestamp < resolveTime) {
                // Store the relayed rate
                BandOracle.symbolsRefData[symbol] = 
                RefData(rate: symbolsRates[symbol]!, timestamp: resolveTime, requestID: requestID)
                updatedSymbols.append(symbol)
            }
        }
        emit BandOracleSymbolsUpdated(symbols: updatedSymbols, relayerID: relayerID, requestID: requestID)
    }

    /// Auxiliary private function for the `OracleAdmin` to force update the rates.
    ///
    /// @param symbolsRates: Set of symbols and corresponding usd rates to update.
    /// @param resolveTime: The registered time for the rates.
    /// @param requestID: The Band Protocol request ID.
    /// @param relayerID: The ID of the relayer carrying the update.
    ///
    access(contract) fun forceUpdateRefData (symbolsRates: {String: UInt64}, resolveTime: UInt64, requestID: UInt64, relayerID: UInt64) {
        // For each symbol rate relayed, store it no matter what was the previous
        // records for it
        for symbol in symbolsRates.keys {
            BandOracle.symbolsRefData[symbol] = 
            RefData(rate: symbolsRates[symbol]!, timestamp: resolveTime, requestID: requestID)
        }
        emit BandOracleSymbolsUpdated(symbols: symbolsRates.keys, relayerID: relayerID, requestID: requestID)
    }

    /// Auxiliary private function for removing a stored symbol
    ///
    /// @param symbol: The string representing the symbol to delete
    ///
    access(contract) fun removeSymbol (symbol: String) {
        BandOracle.symbolsRefData.remove(key: symbol)
        emit BandOracleSymbolRemoved(symbol: symbol)
    }

    /// Auxiliary private function for checking and retrieving data for a given symbol.
    ///
    /// @param symbol: String representing a symbol.
    /// @return Optional `RefData` struct if there is any quote stored for the requested symbol.
    ///
    access(contract) fun _getRefData (symbol: String): RefData? {
        // If the requested symbol is USD just return 10^9
        if (symbol == "USD") {
            return RefData(rate: UInt64(BandOracle.e9), timestamp: UInt64(getCurrentBlock().timestamp), requestID: 0)
        } else {
            return self.symbolsRefData[symbol] ?? nil
        }
    }

    /// Private function that calculates the reference data between two base and quote symbols.
    ///
    /// @param baseRefData: Base ref data.
    /// @param quoteRefData: Quote ref data.
    /// @return Calculated `ReferenceData` structure.
    ///
    access(contract) fun calculateReferenceData (baseRefData: RefData, quoteRefData: RefData): ReferenceData {
        let rate = UInt256((UInt256(baseRefData.rate) * BandOracle.e18) / UInt256(quoteRefData.rate))
        return ReferenceData (rate: rate,
        baseTimestamp: baseRefData.timestamp,
        quoteTimestamp: quoteRefData.timestamp)
    }

    /// Private method for the `FeeCollector` to be able to set the fee for using the oracle
    ///
    /// @param fee: The amount of flow tokens to set as fee.
    ///
    access(contract) fun setFee (fee: UFix64) {
        BandOracle.fee = fee
    }

    /// Private method for the `FeeCollector` to be able to collect the fees from the contract vault.
    ///
    /// @return A flow token vault with the collected fees so far.
    ///
    access(contract) fun collectFees (): @{FungibleToken.Vault} {
        let collectedFees <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        collectedFees.deposit(from: <- BandOracle.payments.withdraw(amount: BandOracle.payments.balance))
        return <- collectedFees
    }


    /// Public access functions.

    /// Public method for creating a relay and become a relayer.
    ///
    /// @param updaterCapability: The capability pointing to the OracleAdmin resource needed to create the relay.
    /// @return The new relay resource.
    ///
    access(all) fun createRelay (updaterCapability: Capability<&{DataUpdater}>): @Relay {
        return <- create Relay(updaterCapability: updaterCapability)
    }

    /// Auxiliary method to ensure that the formation of the capability name that 
    /// identifies data updater capability for relayers is done in a uniform way
    /// by both admin and relayers.
    ///
    /// @param relayer: Address of the account who will be granted with a relayer.
    /// @return The capability name.
    ///
    access(all) view fun getUpdaterCapabilityNameFromAddress (relayer: Address): String {
        // Create the string that will form the private path concatenating the base
        // path and the relayer identifying address.
        let capabilityName = 
        BandOracle.dataUpdaterBasePath.concat(relayer.toString())
        return capabilityName
    }

    /// This function returns the current fee for using the oracle in Flow tokens.
    ///
    /// @return The fee to be charged for every request made to the oracle.
    ///
    access(all) view fun getFee (): UFix64 {
        return BandOracle.fee
    }

    /// The entry point for consumers to query the oracle in exchange of a fee.
    ///
    /// @param baseSymbol: String representing base symbol.
    /// @param quoteSymbol: String representing quote symbol.
    /// @param payment: Flow token vault containing the service fee.
    /// @return The `ReferenceData` containing the requested data.
    ///
    access(all) fun getReferenceData (baseSymbol: String, quoteSymbol: String, payment: @{FungibleToken.Vault}): ReferenceData {



        pre {
            payment.balance >= BandOracle.fee : "Insufficient balance"
        }
        //THIS IS MOCKED
        //500000000000000000
        if baseSymbol=="FLOW" {
            BandOracle.payments.deposit(from: <- payment)
            return ReferenceData(rate:500000000000000000, baseTimestamp:0, quoteTimestamp:0)
        }


        if (BandOracle._getRefData(symbol: baseSymbol) != nil && BandOracle._getRefData(symbol: quoteSymbol) != nil){
            let baseRefData = BandOracle._getRefData(symbol: baseSymbol)!
            let quoteRefData = BandOracle._getRefData(symbol: quoteSymbol)!
            BandOracle.payments.deposit(from: <- payment)
            return BandOracle.calculateReferenceData (baseRefData: baseRefData, quoteRefData: quoteRefData)
        } else {
            panic("Cannot get a quote for the requested symbol pair.")
        }
    }

    /// Turn scientific notation numbers as `UInt256` multiplied by e8 into `UFix64`
    /// fixed point numbers. Exceptionally large integer rates may lose some precision
    /// when converted to a decimal number.
    ///
    /// @param rate: The symbol rate as an integer.
    /// @return The symbol rate as a decimal.
    ///
    access(all) view fun e18ToFixedPoint (rate: UInt256): UFix64 {
        return  (
            UFix64(
                rate / BandOracle.e18
            ) 
            + 
            (
                UFix64(
                    (rate 
                    / 
                    BandOracle.e9) 
                    % 
                    BandOracle.e9
                )
                /
                UFix64(BandOracle.e9)
            ) 
        )
    }

    init() {
        self.OracleAdminStoragePath = /storage/BandOracleAdmin
        self.RelayStoragePath = /storage/BandOracleRelay
        self.FeeCollectorStoragePath = /storage/BandOracleFeeCollector
        self.dataUpdaterBasePath = "BandOracleDataUpdater_"
        self.account.storage.save(<- create BandOracleAdmin(), to: self.OracleAdminStoragePath)
        self.symbolsRefData = {}
        self.relayersCapabilityID = {}
        self.payments <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        self.fee = 0.0
        self.e18 = 1_000_000_000_000_000_000
        self.e9 = 1_000_000_000
        // Create a relayer on the admin account so the relay methods are never accessed directly.
        // The admin could decide to build a transaction borrowing the whole BandOracleAdmin
        // resource and call updateData methods bypassing relayData methods but we are explicitly
        // discouraging that by giving the admin a regular relay resource on contract deployment.
        let oracleAdminRef = self.account.storage.borrow<&{OracleAdmin}>(from: BandOracle.OracleAdminStoragePath)
        ?? panic("Can't borrow a reference to the Oracle Admin")
        let updaterCapability = self.account.capabilities.storage.issue<&{BandOracle.DataUpdater}>(BandOracle.OracleAdminStoragePath)
        let relayer <- BandOracle.createRelay(updaterCapability: updaterCapability)
        self.account.storage.save(<- relayer, to: BandOracle.RelayStoragePath)
    }
}
