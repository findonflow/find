package main

import "github.com/bjartek/overflow"

func main() {

	o := overflow.NewOverflowMainnet().Start()

	o.TransactionFromFile("mintCharity").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().
			String("Christmas Tree 2021").
			String("ipfs://QmYGZXq39Ugazm9dwHz71fWCgxCf1Yub82y1kz3zkzQMyE").
			String("ipfs://QmXs9pejWe1opmDpRdS5cY6Uh7XTb1XApQQ3Dmt61ZwpKx").
			String("https://find.xyz/neo-x-flowverse-community-charity-tree").
			String(`This NFT is from the Neo x FlowVerse Charity Fundraiser 2021.
It is a 1/1 NFT that was auctioned off with all of the proceeds going to “Women for Afghan Women”.
The owner of this NFT is a legend for helping to make the world a better place!`).
			RawAccount("0x7a1d854cbd4f84b9")).
		Run()

}
