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
	g := overflow.NewOverflowMainnet().Config("flow.json", "../../.flow-deploy.json").Start()

	res, err := g.ParseAllWithConfig(false, []string{}, []string{})
	if err != nil {
		panic(err)
	}

	contracts := res.Networks[g.Network].Contracts

	accountOnMainnet, err := g.Services.Accounts.Get(g.Account("find").Address())
	if err != nil {
		panic(err)
	}
	mainnetContracts := accountOnMainnet.Contracts

	for name, contract := range *contracts {
		code, found := mainnetContracts[name]

		contractBytes := []byte(contract)
		if found && bytes.Equal(code, contractBytes) {
			continue
		}

		fileName := fmt.Sprintf("deploy/%s.cdc", name)
		//		err := os.WriteFile(fileName, contractBytes, 0644)
		if err != nil {
			panic(err)
		}

		hexCode := hex.EncodeToString(contractBytes)
		if found {

			codeAsText := string(code)
			edits := myers.ComputeEdits(span.URIFromPath(fileName), codeAsText, contract)
			diff := fmt.Sprint(gotextdiff.ToUnified("deployed", "changes", codeAsText, edits))

			fmt.Println("DIFF of " + name)
			fmt.Println(diff)

			err := os.WriteFile(fmt.Sprintf("deploy/%s.diff", name), []byte(diff), 0644)
			if err != nil {
				panic(err)
			}
			fmt.Println("Update not possible yet")
			/*
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
			*/

		} else {

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
}

/*

flow transactions build updateContract.cdc \
  --arg String:Versus \
  --arg String:$(xxd -plain --cols 99999 versus/Versus.cdc) \
  --network mainnet \
  --proposer contract-admin \
  --proposer-key-index 2 \
  --authorizer 0xd796ff17107bbff6 \
  --authorizer contract-admin \
  --payer contract-admin \
  -x payload \
  --save deploy-Versus.rlp

// 2. Dev signs

flow transactions sign deploy-Versus.rlp \
  --signer temp \
  --filter payload \
  --save deploy-Versus-signed.rlp

// 3. We sign

flow transactions sign deploy-Versus-signed.rlp \
  --signer contract-admin \
  --filter payload \
  --save deploy-Versus-sendable.rlp

// 4. Albert sends

flow transactions send-signed --network mainnet deploy-Versus-sendable.rlp
*/
