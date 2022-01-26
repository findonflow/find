package main

import (
	"bytes"
	"encoding/hex"
	"fmt"
	"os"

	"github.com/bjartek/overflow/overflow"
	"github.com/hexops/gotextdiff"
	"github.com/hexops/gotextdiff/myers"
	"github.com/hexops/gotextdiff/span"
)

//I think we need a name here.
func main() {

	name, ok := os.LookupEnv("contract")
	if !ok {
		fmt.Println("file is not present")
		os.Exit(1)
	}

	g := overflow.NewOverflowMainnet().Config("flow.json", "../../.flow.json").Start()

	res, err := g.ParseAllWithConfig(false, []string{}, []string{})
	if err != nil {
		panic(err)
	}

	contracts := *res.Networks[g.Network].Contracts
	contract := contracts[name]

	accountOnMainnet, err := g.Services.Accounts.Get(g.Account("find").Address())
	if err != nil {
		panic(err)
	}
	mainnetContracts := accountOnMainnet.Contracts

	code, found := mainnetContracts[name]

	contractBytes := []byte(contract)
	if found && bytes.Equal(code, contractBytes) {
		fmt.Println("Contract is the same on mainnet as local copy")
		os.Exit(1)
	}

	fileName := fmt.Sprintf("deploy/%s.cdc", name)
	hexCode := hex.EncodeToString(contractBytes)
	if found {

		codeAsText := string(code)
		edits := myers.ComputeEdits(span.URIFromPath(fileName), codeAsText, contract)
		diff := fmt.Sprint(gotextdiff.ToUnified("deployed", "changes", codeAsText, edits))

		fmt.Println("DIFF of " + name)
		fmt.Println(diff)
		fmt.Println("------------------------")
		fmt.Println(" press any key to update")
		fmt.Scanln()

		//code as Hex
		//update contract
		g.Transaction(`
			transaction(name: String, code: String) {
				prepare(signer: AuthAccount, admin: AuthAccount) {
					signer.contracts.update__experimental(name: name, code: code.decodeHex())
				}
			}`).
			SignProposeAndPayAs("deployer").
			PayloadSigner("find").
			Args(g.Arguments().
				String(name).
				String(hexCode)).
			RunPrintEventsFull()

	} else {

		fmt.Println("------------------------")
		fmt.Println(" press any key to deploy ")
		fmt.Scanln()

		g.Transaction(`
				transaction(name: String, code: String) {
					prepare(signer: AuthAccount, admin: AuthAccount) {
						signer.contracts.add(name: name, code: code.decodeHex())
					}
				}`).
			SignProposeAndPayAs("deployer").
			PayloadSigner("find").
			Args(g.Arguments().
				String(name).
				String(hexCode)).
			RunPrintEventsFull()

	}
}
