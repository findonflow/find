package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowInMemoryEmulator()
	//g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")

	//first step create the adminClient as the fin user
	g.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//link in the server in the versus client
	g.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		AccountArgument("find").
		RunPrintEventsFull()

	//set up fin network as the fin user
	g.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//we advance the clock
	g.TransactionFromFile("clock").SignProposeAndPayAs("find").UFix64Argument("1.0").RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("user1").
		StringArgument("User1").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("user2").
		StringArgument("User2").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAsService().
		StringArgument("Find").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find").
		StringArgument("Find").
		RunPrintEventsFull()

	g.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		AccountArgument("user1").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
		UFix64Argument("5.0").
		RunPrintEventsFull()

	g.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		AccountArgument("user2").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("mintFlow").
		SignProposeAndPayAsService().
		AccountArgument("user2").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("send").
		SignProposeAndPayAs("user2").
		StringArgument("user1").
		UFix64Argument("13.37").
		RunPrintEventsFull()

	g.TransactionFromFile("renew").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
		UFix64Argument("5.0").
		RunPrintEventsFull()

	g.TransactionFromFile("listForSale").SignProposeAndPayAs("user1").StringArgument("user1").UFix64Argument("10.0").RunPrintEventsFull()

	g.TransactionFromFile("bid").
		SignProposeAndPayAs("user2").
		StringArgument("user1").
		UFix64Argument("10.0").
		RunPrintEventsFull()

	g.ScriptFromFile("address_status").AccountArgument("user2").Run()

	g.TransactionFromFile("buyAddon").SignProposeAndPayAs("user2").StringArgument("user1").StringArgument("artifact").UFix64Argument("50.0").RunPrintEventsFull()

	g.TransactionFromFile("mintArtifact").SignProposeAndPayAs("user2").StringArgument("user1").RunPrintEventsFull()

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

	fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.CreativeWork")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.CreativeWork").Run()

	fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Royalties")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.Royalties").Run()

	fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.MinterPlatform")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.MinterPlatform").Run()

	fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Profiles")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Profiles").Run()

	fmt.Println("find.xyz/user2/artifacts/1/String")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("String").Run()

	fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Media")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.Media").Run()

	fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.TypedMetadata.Editioned")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.Editioned").Run()

	fmt.Println("find.xyz/user2/artifacts/1/A.f8d6e0586b0a20c7.Artifact.Minter")
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(1).StringArgument("A.f8d6e0586b0a20c7.Artifact.Minter").Run()

	g.ScriptFromFile("find-full").AccountArgument("user2").Run()
	g.ScriptFromFile("find-list").AccountArgument("user2").Run()

}
