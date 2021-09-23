import React, { useState, useRef } from "react";
import * as fcl from "@onflow/fcl";
import * as t from "@onflow/types";
import {PublicLease} from "./PublicLease";
import { scripts } from 'find-flow-contracts';

export function Search() {
  const [nameStatus, setNameStatus] = useState(null);
 	const form = useRef(null);
  const handleSubmit = async (e) => {
    e.preventDefault();
    const { name } = form.current;
    if (!name.value) {
			console.log("specify a name")
			return
    }
		const response = await fcl.send([
            fcl.script(scripts.name_status),
            fcl.args([fcl.arg(name.value, t.String)]),
        ]);
        const nameStatus= await fcl.decode(response);
			  console.log(nameStatus)
				setNameStatus(nameStatus)
   };

  if(nameStatus === null)  { 
		 return (
    <div className="fixed flex h-screen items-center justify-center left-0 top-0 w-screen z-50 py-12">
      <div className="absolute bg-black-600 bg-opacity-90 h-full left-0 top-0 w-full" />
      <div
        className="bg-cream-500 flex flex-col items-center max-w-full px-10 sm:px-20 py-8 rounded-2xl w-128 z-10 modal-scroll"
      >
          <>
            <h4 className="font-black font-inktrap mt-8 text-xl">
					    Search for a name
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
              <button text="Confirm" onClick={handleSubmit} >Search</button>
            </div>
          </>
      </div>
    </div>
  );
  } else {

		if(nameStatus.status==="free") {
			return <div>REGISTR</div>
		}

	return <div>
		<div> Show the profile { JSON.stringify(nameStatus.profile, null, 2) }</div>
		<PublicLease lease={nameStatus.lease} />
		</div>
	}

}
