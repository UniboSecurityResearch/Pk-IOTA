import React, { useState } from "react";
import web3 from "../web3";
import * as Wallet from "../wallet";

function WalletForm({ setMessage,  setLoaded}) {
  const [pwd, setPWD] = useState("");
  const [pwd2, setPWD2] = useState("");
  const onCreate = async (event) => {
    event.preventDefault();

    try {
      console.log(pwd);
      var res = Wallet.createAccount(pwd);
      if(res)
      {
        setMessage("OK: new wallet created");
      }
      else {
        setMessage("ERROR: can't create wallet");
      }
      
      setPWD("");
    } catch (err) {
      console.log(err)
    }
  };
  const onLoad = async (event) => {
    event.preventDefault();

    try {
      var wallet = Wallet.loadAccount(pwd2);/*
      web3.eth.accounts.wallet.add("0x590182b315de1ca09ace079090d499e6e3b7dbbef9eb0aaa604916a6bec77a20");
      const account = web3.eth.accounts.privateKeyToAccount("0x590182b315de1ca09ace079090d499e6e3b7dbbef9eb0aaa604916a6bec77a20");*/
      web3.eth.defaultAccount = wallet[0].address;
      console.log(wallet);
      setMessage("Wallet successfully loaded, address: " +  web3.eth.defaultAccount);
      const bal = await web3.eth.getBalance(wallet[0].address);
      console.log("Balance of the personal wallet: " + web3.utils.fromWei(bal, "ether") + "SMR");
      //await window.ethereum.enable();
      setLoaded(true);
      setPWD2("");
    } catch (err) {
      console.log(err)
    }
  };

  return (
  <div>
    <form onSubmit={onCreate}>
      <h4>This is the form to save and load the wallet, to be done as first step</h4>
      <p>You have to create the wallet the first time:</p>
      <div>
        <label htmlFor="enter-value">Insert the password of the wallet you want to create:</label>
        <input
          pwd="pass-value"
          value={pwd}
          onChange={(event) => setPWD(event.target.value)}
        /><br></br>
      </div>
      <button className="button" type="submit">Create and Save Wallet</button>
    </form><br></br>
    <form onSubmit={onLoad}>
      <div>
        <label htmlFor="enter-value">Insert the password of the wallet to be loaded (previously created):</label>
        <input
          pwd2="pass2-value"
          value={pwd2}
          onChange={(event) => setPWD2(event.target.value)}
        />
      </div>
      <button className="button" type="submit">Load wallet</button>
    </form><br></br>
  </div> 
  );
}

export default WalletForm;
