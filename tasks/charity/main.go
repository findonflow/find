package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowMainNet()
	g.TransactionFromFile("mintCharity").
		SignProposeAndPayAs("find-admin").
		StringArgument("Christmas Tree 2021").
		StringArgument("ipfs://QmYGZXq39Ugazm9dwHz71fWCgxCf1Yub82y1kz3zkzQMyE").
		StringArgument("ipfs://QmXs9pejWe1opmDpRdS5cY6Uh7XTb1XApQQ3Dmt61ZwpKx").
		StringArgument("https://find.xyz/neo-x-flowverse-community-charity-tree").
		StringArgument(`This NFT is from the Neo x FlowVerse Charity Fundraiser 2021.
It is a 1/1 NFT that was auctioned off with all of the proceeds going to “Women for Afghan Women”.
The owner of this NFT is a legend for helping to make the world a better place!`).
		RawAccountArgument("0x7a1d854cbd4f84b9").
		Run()

}
