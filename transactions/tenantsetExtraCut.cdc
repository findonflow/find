import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketCutStruct from "../contracts/FindMarketCutStruct.cdc"

transaction(ftTypes: [String], category: String, cuts: [FindMarketCutStruct.ThresholdCut]){
    prepare(account: auth(BorrowValue) &Account){

        let types : [Type] = []
        for t in ftTypes {
            types.append(CompositeType(t)!)
        }

        let allCuts = FindMarketCutStruct.Cuts(cuts:cuts)

        let clientRef = account.storage.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")
        clientRef.setExtraCut(types: types, category: category, cuts: allCuts)
    }
}

