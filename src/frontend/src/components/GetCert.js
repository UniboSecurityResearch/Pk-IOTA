import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";

function GetBookingByAdd({ setMessage }) {
  const [add, setAdd] = useState("");
  const onGetBookingByAddHandler = async () => {
    const accounts = await web3.eth.getAccounts();

    setMessage("Waiting on transaction success...");

    const booking = await scbackend.methods.getBookingByAdd(add).call({
        from: accounts[0]
    });

    setMessage("Booking data: Address: "+add+" \
    start Date: "+booking[0]+"   \
    end Date: "+booking[1]+" \
    city: "+booking[2]+" \
    payment: "+booking[3]);
  };

  return (
    <div>
      <h4>Ready to check if your booking is really inside the blockchain?</h4>
      <label htmlFor="enter-value">Insert your Ethereum Address:</label>
        <input
          id="add-value"
          value={add}
          onChange={(event) => setAdd(event.target.value)}
        /><br></br>
      <button class="button" onClick={onGetBookingByAddHandler}>Get Booking data</button>
    </div>
  );
}

export default GetBookingByAdd;
