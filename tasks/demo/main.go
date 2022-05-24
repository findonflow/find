package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowEmulator().Start()
	/*
		o := overflow.NewOverflowMainnet().Start()
	*/

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

	o.TransactionFromFile("setup_find_market_1").
		SignProposeAndPayAsService().
		RunPrintEventsFull()

	//link in the server in the versus client
	o.TransactionFromFile("setup_find_market_2").
		SignProposeAndPayAs("find").
		Args(o.Arguments().Account("account")).
		RunPrintEventsFull()

	//we advance the clock
	o.TransactionFromFile("testClock").SignProposeAndPayAs("find").
		Args(o.Arguments().UFix64(1.0)).
		RunPrintEventsFull()

	o.SimpleTxArgs("adminSetupMarketOptionsTypes", "find", o.Arguments())

	/*
		o.TransactionFromFile("createProfile").
			SignProposeAndPayAsService().
			Args(o.Arguments().String("find")).
			RunPrintEventsFull()
	*/

	/*
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

		o.TransactionFromFile("listForSale").SignProposeAndPayAs("user1").
			Args(o.Arguments().String("user1").UFix64(10.0)).
			RunPrintEventsFull()

		o.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			Args(o.Arguments().String("user1").UFix64(10.0)).
			RunPrintEventsFull()

		o.ScriptFromFile("getStatus").
			Args(o.Arguments().String("user2")).
			Run()

		/*
			o.TransactionFromFile("buyAddon").SignProposeAndPayAs("user1").
				Args(o.Arguments().String("user1").String("forge").UFix64(50.0)).
				RunPrintEventsFull()

			o.TransactionFromFile("mintDandy").
				SignProposeAndPayAs("user1").
				Args(o.Arguments().String("user1")).
				RunPrintEventsFull()

			var id uint64 = 83
			o.ScriptFromFile("dandyViews").
				Args(o.Arguments().String("user1").UInt64(id)).
				Run()

			o.ScriptFromFile("view").Args(o.Arguments().String("user1").PublicPath("findDandy").UInt64(id).String("A.f8d6e0586b0a20c7.MetadataViews.Display")).Run()
			//	o.ScriptFromFile("dandy").Args(o.Arguments().String("user1").UInt64(id).String("AnyStruct{A.f8d6e0586b0a20c7.MetadataViews.Royalty}")).Run()

			/*
						o.TransactionFromFile("mintArtifact").SignProposeAndPayAs("user2").StringArgument("user1").RunPrintEventsFull()

				<<<<<<< HEAD
							g.TransactionFromFile("mintArt").
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
							g.ScriptFromFile("find-collection").AccountArgument("user2").Run()

							fmt.Println("find.xyz/user2/artifacts")
							g.ScriptFromFile("find-ids-profile").AccountArgument("user2").StringArgument("artifacts").Run()

							fmt.Println("find.xyz/user2/artifacts/1")
							g.ScriptFromFile("find-schemes").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).Run()

							fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.CreativeWork")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.FindViews.CreativeWork").Run()

							fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7..Royalties")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.MetadataViews.Royalties").Run()

							fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.MinterPlatform")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.MinterPlatform").Run()

							fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.Profiles")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Profiles").Run()

							fmt.Println("find.xyz/user2/artifacts/1/String")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("String").Run()

							fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.Media")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.FindViews.Media").Run()

							fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.SerialNumber")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.FindViews.SerialNumber").Run()

							fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.Artifact.Minter")
							g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Minter").Run()

							g.ScriptFromFile("find-full").AccountArgument("user2").Run()
							g.ScriptFromFile("find-list").AccountArgument("user2").Run()
				=======
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

						fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.CreativeWork")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.FindViews.CreativeWork").Run()

						fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.MetadataViews.Royalties")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.MetadataViews.Royalties").Run()

						fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.MinterPlatform")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.MinterPlatform").Run()

						fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.Profiles")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Profiles").Run()

						fmt.Println("find.xyz/user2/artifacts/1/String")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("String").Run()

						fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.Media")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.FindViews.Media").Run()

						fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.FindViews.SerialNumber")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.FindViews.SerialNumber").Run()

						fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.Artifact.Minter")
						o.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Minter").Run()

						o.ScriptFromFile("find-full").AccountArgument("user2").Run()
						o.ScriptFromFile("find-list").AccountArgument("user2").Run()
				>>>>>>> main
	*/

}
