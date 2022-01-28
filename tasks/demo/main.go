package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowInMemoryEmulator().Start()

	//first step create the adminClient as the fin user
	o.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//link in the server in the versus client
	o.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		Args(o.Arguments().Account("find")).
		RunPrintEventsFull()

	//set up fin network as the fin user
	o.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//we advance the clock
	o.TransactionFromFile("clock").SignProposeAndPayAs("find").
		Args(o.Arguments().UFix64(1.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("createProfile").
		SignProposeAndPayAs("user1").
		Args(o.Arguments().String("User1")).
		RunPrintEventsFull()

	o.TransactionFromFile("createProfile").
		SignProposeAndPayAs("user2").
		Args(o.Arguments().String("User2")).
		RunPrintEventsFull()

	o.TransactionFromFile("createProfile").
		SignProposeAndPayAsService().
		Args(o.Arguments().String("Find")).
		RunPrintEventsFull()

	o.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find").
		Args(o.Arguments().String("Find")).
		RunPrintEventsFull()

	o.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		Args(o.Arguments().Account("user1").UFix64(100.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		Args(o.Arguments().String("user1").UFix64(5.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		Args(o.Arguments().Account("user2").UFix64(100.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("mintFlow").
		SignProposeAndPayAsService().
		Args(o.Arguments().Account("user2").UFix64(100.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("sendFT").
		SignProposeAndPayAs("user2").
		Args(o.Arguments().Account("user2").UFix64(100.0).String("fusd")).
		RunPrintEventsFull()

	o.TransactionFromFile("renew").
		SignProposeAndPayAs("user1").
		Args(o.Arguments().String("user1").UFix64(5.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("listForSale").SignProposeAndPayAs("user1").
		Args(o.Arguments().String("user1").UFix64(10.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("bid").
		SignProposeAndPayAs("user2").
		Args(o.Arguments().String("user1").UFix64(10.0)).
		RunPrintEventsFull()

	o.ScriptFromFile("address_status").
		Args(o.Arguments().Account("user2")).
		Run()

	o.TransactionFromFile("buyAddon").SignProposeAndPayAs("user2").
		Args(o.Arguments().String("user1").String("artifact").UFix64(50.0)).
		RunPrintEventsFull()

	/*
		o.TransactionFromFile("mintArtifact").SignProposeAndPayAs("user2").StringArgument("user1").RunPrintEventsFull()

		o.TransactionFromFile("mintArt").
			SignProposeAndPayAs("find").
			AccountArgument("user1").
			StringArgument("Kinger9999").
			StringArgument("Bull").
			StringArgument("Teh crypto bull").
			AccountArgument("user2").
			StringArgument("image/jpeg").
			UFix64Argument("0.05").
			UFix64Argument("0.025").
			StringArgument("http://bull-address-here").
			RunPrintEventsFull()

		fmt.Println("find.xyz/user2")
		o.ScriptFromFile("find-collection").AccountArgument("user2").Run()

		fmt.Println("find.xyz/user2/artifacts")
		o.ScriptFromFile("find-ids-profile").AccountArgument("user2").StringArgument("artifacts").Run()

		fmt.Println("find.xyz/user2/artifacts/1")
		o.ScriptFromFile("find-schemes").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).Run()

		fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.CreativeWork")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.CreativeWork").Run()

		fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Royalties")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.Royalties").Run()

		fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.MinterPlatform")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.MinterPlatform").Run()

		fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Profiles")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Profiles").Run()

		fmt.Println("find.xyz/user2/artifacts/1/String")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("String").Run()

		fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Media")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.Media").Run()

		fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Editioned")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.Editioned").Run()

		fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.Artifact.Minter")
		o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Minter").Run()

		o.ScriptFromFile("find-full").AccountArgument("user2").Run()
		o.ScriptFromFile("find-list").AccountArgument("user2").Run()
	*/

}
