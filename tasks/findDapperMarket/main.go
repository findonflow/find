package main

import (
	. "github.com/bjartek/overflow/v2"
	"github.com/findonflow/find/findGo"
)

func main() {

	o := Overflow(WithNetwork("mainnet"), WithGlobalPrintOptions())

	ot := findGo.OverflowUtils{
		O: o,
	}

	ot.UpgradeFindDapperTenantSwitchboard()

}
