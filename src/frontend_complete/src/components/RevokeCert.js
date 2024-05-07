import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";

function RevokeCert({ setMessage }) {
  const [certificate, setCertificate] = useState("");
  const onSubmit = async (event) => {
    event.preventDefault();

    try {
      setMessage("Waiting on transaction success...");
      await scbackend.methods.revokeCertificate(certificate).send({
        from: web3.eth.defaultAccount,
        gas: '1000000',
    });
/* [OLD CODE]
      await scbackend.methods.book().send({
        from: accounts[0],
        value: web3.utils.toWei(enterValue, "ether"),
      });*/
      setMessage("Revoke sent");
      setCertificate("");
    } catch (err) {
      setMessage("ERROR (did you remember to previously load the wallet?)");
      console.log(err)
    }
  };
  
  return (
    <form onSubmit={onSubmit}>
      <h4>Form to revoke a certificate on the IOTA blockchain</h4>
      <div>
        <label htmlFor="certificate-value">Insert the certificate data:</label>
        <input
          id="certificate-value"
          value={certificate}
          onChange={(event) => setCertificate(event.target.value)}
        /><br></br>
      </div>
      <br></br>
      <button className="button revoke" type="submit">REVOKE</button>
    </form>
  );
}

export default RevokeCert;
