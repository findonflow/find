
import Admin from "../contracts/Admin.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction() {

	prepare(admin:AuthAccount) {

		let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		let data : {UInt64 : MetadataViews.Trait} = {
														3 : MetadataViews.Trait(name: "knees", value: "knee pad", displayType: "string", rarity: nil), 
														4 : MetadataViews.Trait(name: "toes", value: "flowverse socks", displayType: "string", rarity: MetadataViews.Rarity(score: nil, max: nil, description: "Legendary"))
													}

		client.addForgeContractData(forgeType : Type<@ExampleNFT.Forge>(), 
									data: data) 

	}

}
