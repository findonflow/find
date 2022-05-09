package main

import (
	"github.com/bjartek/overflow/overflow"
	"github.com/onflow/cadence"
)

func main() {

	o := overflow.NewOverflowMainnet().Start()

	/*
		//first step create the adminClient as the fin user
		g.TransactionFromFile("setup_fin_1_create_client").
			SignProposeAndPayAs("find-admin").
			RunPrintEventsFull()
	*/

	//link in the server in the versus client
	o.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAs("find").
		Args(o.Arguments().Account("find-admin")).
		RunPrintEventsFull()

		/*
			//set up fin network as the fin user
			g.TransactionFromFile("setup_fin_3_create_network").
				SignProposeAndPayAs("find-admin").
				RunPrintEventsFull()
		*/

	o.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find").
		Args(o.Arguments().String("find")).
		RunPrintEventsFull()

	findLinks := cadence.NewArray([]cadence.Value{
		cadence.NewDictionary([]cadence.KeyValuePair{
			{Key: NewCadenceSting("title"), Value: NewCadenceSting("twitter")},
			{Key: NewCadenceSting("type"), Value: NewCadenceSting("twitter")},
			{Key: NewCadenceSting("url"), Value: NewCadenceSting("https://twitter.com/findonflow")},
		})})

	o.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().String("ReservedNames")).
		RunPrintEventsFull()

	o.TransactionFromFile("editProfile").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().
			String("ReservedFindNames").
			String(`The names owned by this profile are reservd by .find. In order to aquire a name here you have to:

Prices:
 - 3 letter name  500 FUSD
 - 4 letter name  100 FUSD
 - 5+ letter name   5 FUSD

1. make an offer for that name with the correct price (see above) 
2. go into the find discord and let the mods know you have made the bid

`).
			String("https://find.xyz/find.png").
			StringArray("find").
			Boolean(false).
			Argument(findLinks)).
		RunPrintEventsFull()

	o.TransactionFromFile("editProfile").
		SignProposeAndPayAs("find").
		Args(o.Arguments().
			String("find").
			String(`.find will allow you to find people and NFTS on flow!`).
			String("https://find.xyz/find.png").
			StringArray("find").
			Boolean(true).
			Argument(findLinks)).
		RunPrintEventsFull()

	o.TransactionFromFile("registerAdmin").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().StringArray("find").Account("find")).
		RunPrintEventsFull()

	o.TransactionFromFile("registerAdmin").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().StringArray("reserved-names").Account("find-admin")).
		RunPrintEventsFull()

}

func NewCadenceSting(value string) cadence.String {
	result, err := cadence.NewString(value)
	if err != nil {
		panic(err)
	}

	return result
}
