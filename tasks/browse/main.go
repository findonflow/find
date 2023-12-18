package main

import (
	"github.com/bjartek/overflow"
)

func main() {

	address := "0x8bf9ecc3a2b8d7af"
	o := overflow.Overflow(overflow.WithNetwork("testnet"))

	result := o.Script("getFindPaths", overflow.WithArg("user", address))

	if result.Err != nil {
		panic(result.Err)
	}

	result.Print()

	var res Result
	err := result.MarshalAs(&res)
	if err != nil {
		panic(err)
	}

	//access(all) main(address: Address, targetPaths: [String]): {String : Report}{
	ids := o.Script("getNFTIDs", overflow.WithArg("address", address), overflow.WithArg("targetPaths", res.Paths))

	ids.Print()

}

type Result struct {
	Paths []string `json:"paths"`
}
