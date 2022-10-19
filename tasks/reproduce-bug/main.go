package main

import (
	"fmt"

	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(
		WithNetwork("testing"),
		WithFlowForNewUsers(100.0),
	)

	o.Script("reproduce-bug").
		Print()

	fmt.Println("The keys returned as shown above.")
	fmt.Println("Keys returned are different between 2 versions of overflow (i.e. 2 versions of onflow/cadence)")
	fmt.Println("If you are on overflow@v1.0.0 , run make update-overflow and run this task again.")

}
