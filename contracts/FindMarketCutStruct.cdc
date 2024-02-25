import "FungibleToken"
import "MetadataViews"

access(all) contract FindMarketCutStruct {

    access(all) struct Cuts {
        access(all) let cuts : [{Cut}]
        access(contract) let extra: {String : AnyStruct}

        init(cuts: [{Cut}]) {
            self.cuts = cuts
            self.extra = {}
        }

        access(all) fun getEventSafeCuts() : [EventSafeCut] {
            let cuts : [EventSafeCut] = []
            for c in self.cuts {
                cuts.append(c.getEventSafeCut())
            }
            return cuts
        }
    }

    access(all) struct EventSafeCut {
        access(all) let name: String
        access(all) let description: String
        access(all) let cut: UFix64
        access(all) let receiver: Address
        access(all) let extra: {String : String}

        init(name: String, description: String, cut: UFix64, receiver: Address, extra: {String : String}) {
            self.name = name
            self.description = description
            self.cut = cut
            self.receiver = receiver
            self.extra = extra
        }
    }

    access(all) struct interface Cut {
        access(all) fun getName() : String
        access(all) fun getReceiverCap() : Capability<&{FungibleToken.Receiver}>
        access(all) fun getCut() : UFix64
        access(all) fun getAddress() : Address
        access(all) fun getDescription() : String
        access(all) fun getPayableLogic() : (fun(UFix64) : UFix64?)
        access(all) fun getExtra() : {String : String}

        access(all) fun getRoyalty() : MetadataViews.Royalty {
            let cap = self.getReceiverCap()
            return MetadataViews.Royalty(receiver: cap, cut: self.getCut(), description: self.getName())
        }

        access(all) fun getAmountPayable(_ salePrice: UFix64) : UFix64? {
            if let cut = self.getPayableLogic()(salePrice) {
                return cut
            }
            return nil
        }

        access(all) fun getEventSafeCut() : EventSafeCut {
            return EventSafeCut(
                name: self.getName(),
                description: self.getDescription(),
                cut: self.getCut(),
                receiver: self.getAddress(),
                extra: self.getExtra()
            )
        }
    }

    access(all) struct GeneralCut : Cut {
        // This is the description of the royalty struct
        access(all) let name : String
        access(all) let cap: Capability<&{FungibleToken.Receiver}>
        access(all) let cut: UFix64
        // This is the description to the cut that can be visible to give detail on detail page
        access(all) let description: String
        access(self) let extra : {String : AnyStruct}

        init(name : String, cap: Capability<&{FungibleToken.Receiver}>, cut: UFix64, description: String) {
            self.name = name
            self.cap = cap
            self.cut = cut
            self.description = description
            self.extra = {}
        }

        access(all) fun getReceiverCap() : Capability<&{FungibleToken.Receiver}> {
            return self.cap
        }
        access(all) fun getName() : String {
            return self.name
        }
        access(all) fun getCut() : UFix64 {
            return self.cut
        }
        access(all) fun getAddress() : Address {
            return self.cap.address
        }
        access(all) fun getDescription() : String {
            return self.description
        }
        access(all) fun getExtra() : {String : String} {
            return {}
        }

        access(all) fun getPayableLogic() : (fun(UFix64) : UFix64?) {
            return fun(_ salePrice : UFix64) : UFix64? {
                return salePrice * self.cut
            }
        }
    }

    access(all) struct ThresholdCut : Cut {
        // This is the description of the royalty struct
        access(all) let name : String
        access(all) let address: Address
        access(all) let cut: UFix64
        // This is the description to the cut that can be visible to give detail on detail page
        access(all) let description: String
        access(all) let publicPath: String
        access(all) let minimumPayment: UFix64
        access(self) let extra : {String : AnyStruct}

        init(name : String , address: Address , cut: UFix64 , description: String , publicPath: String, minimumPayment: UFix64) {
            self.name = name
            self.address = address
            self.cut = cut
            self.description = description
            self.publicPath = publicPath
            self.minimumPayment = minimumPayment
            self.extra = {}
        }

        access(all) fun getReceiverCap() : Capability<&{FungibleToken.Receiver}> {
            let pp = PublicPath(identifier: self.publicPath)!
            return getAccount(self.address).capabilities.get<&{FungibleToken.Receiver}>(pp)!
        }
        access(all) fun getName() : String {
            return self.name
        }
        access(all) fun getCut() : UFix64 {
            return self.cut
        }
        access(all) fun getAddress() : Address {
            return self.address
        }
        access(all) fun getDescription() : String {
            return self.description
        }
        access(all) fun getExtra() : {String : String} {
            return {}
        }

        access(all) fun getPayableLogic() : (fun(UFix64) : UFix64?) {
            return fun(_ salePrice : UFix64) : UFix64? {
                let rPayable = salePrice * self.cut
                if rPayable < self.minimumPayment {
                    return self.minimumPayment
                }
                return rPayable
            }
        }
    }
}
