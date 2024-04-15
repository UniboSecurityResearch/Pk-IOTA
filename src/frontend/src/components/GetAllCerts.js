import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";

function render(text) {
  return (
  <div>
      {text.split("\n").map((i,key) => {
          return <div key={key}>{i}</div>;
      })}
  </div>);
}

function GetAllBookings({ setMessage }) {
  const onGetAllBookingsHandler = async () => {
    const accounts = await web3.eth.getAccounts();
    var bookingsString = "";

    setMessage("Waiting on transaction success...");

    const bookings = await scbackend.methods.getBookingsAll().call({
        from: accounts[0]
    });

    var i = 0;

    for (i = 0; i < bookings.length; i++){
      const booking = await scbackend.methods.getBookingByAdd(bookings[i]).call({
        from: accounts[0]
    });

    
    bookingsString+="Booking data: Address: "+bookings[i]+" \
    start Date: "+booking[0]+"   \
    end Date: "+booking[1]+" \
    city: "+booking[2]+" \
    payment: "+booking[3] + "\n";
   }

    
   setMessage(render(bookingsString));

  };

  return (
    <div>
      <h4>Ready to extract everything?</h4>
      <button class="button" onClick={onGetAllBookingsHandler}>Get All</button>
    </div>
  );
}

export default GetAllBookings;
