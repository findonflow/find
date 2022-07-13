package main

import (
	"bytes"
	"fmt"
	"os"

	"github.com/bjartek/overflow/overflow"
	"github.com/hexops/gotextdiff"
	"github.com/hexops/gotextdiff/myers"
	"github.com/hexops/gotextdiff/span"
)

func main() {
	g := overflow.NewOverflowMainnet().Start()

	res, err := g.ParseAllWithConfig(false, []string{}, []string{})
	if err != nil {
		panic(err)
	}

	contracts := res.Networks[g.Network].Contracts

	account, _ := g.AccountE("find")
	accountOnMainnet, err := g.Services.Accounts.Get(account.Address())
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
		err := os.WriteFile(fileName, contractBytes, 0644)
		if err != nil {
			panic(err)
		}
		if found {

			codeAsText := string(code)
			edits := myers.ComputeEdits(span.URIFromPath(fileName), codeAsText, contract)
			diff := fmt.Sprint(gotextdiff.ToUnified("deployed", "changes", codeAsText, edits))

			err := os.WriteFile(fmt.Sprintf("deploy/%s.diff", name), []byte(diff), 0644)
			if err != nil {
				panic(err)
			}

		}
	}

}
