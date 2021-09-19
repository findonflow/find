import React, { useRef} from "react";
import * as fcl from "@onflow/fcl";
import * as t from "@onflow/types";

import { tx } from "./transaction";
import { transactions } from 'find-flow-contracts'


export function Register() {
  const form = useRef(null);
  const handleSubmit = async (e) => {
    e.preventDefault();
    const { name } = form.current;
    if (!name.value) {
			console.log("specify a name")
			return
    }
    try {
      await tx(
        [
          fcl.transaction(transactions.register),
          fcl.args([
            fcl.arg(name.value, t.String)
          ]),
          fcl.proposer(fcl.currentUser().authorization),
          fcl.payer(fcl.currentUser().authorization),
          fcl.authorizations([fcl.currentUser().authorization]),
          fcl.limit(9999),
        ],
        {
          onStart() {
            form.current.reset();
						console.log("start")
          },
          onSubmission() {
						console.log("submitted")
          },
          async onSuccess(status) {
						console.log("success")
            const event = document.createEvent("Event");
            event.initEvent("bid", true, true);
            document.dispatchEvent(event);
          },
          async onError(error) {
            if (error) {
              const { message } = error;
							console.log(message)
            }
          },
        }
      );
    } catch (e) {
      console.log(e);
    }
  };
  return (
    <div className="fixed flex h-screen items-center justify-center left-0 top-0 w-screen z-50 py-12">
      <div className="absolute bg-black-600 bg-opacity-90 h-full left-0 top-0 w-full" />
      <div
        className="bg-cream-500 flex flex-col items-center max-w-full px-10 sm:px-20 py-8 rounded-2xl w-128 z-10 modal-scroll"
      >
          <>
            <h4 className="font-black font-inktrap mt-8 text-xl">
					    Register your name
            </h4>
           <form
              ref={form}
              onSubmit={handleSubmit}
              className="mt-3 w-full relative"
            >
              <input
                type="string"
                placeholder="name"
                name="name"
                className="bg-white border border-regGrey outline-none placeholder-black-200 px-4 py-3 rounded text-black-500 w-full no-show-drop"
              />
              <p className="mt-2 text-xs">
								minimum 3 characters
             </p>
               </form>
            <div className="flex justify-between mt-12 w-full">
              <button text="Confirm" onClick={handleSubmit} >Register</button>
            </div>
          </>
      </div>
    </div>
  );
}

