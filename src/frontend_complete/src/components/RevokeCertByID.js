import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";

function RevokeCertByID({ setMessage }) {
  const [id, setId] = useState(0);
  const onSubmit = async (event) => {
    event.preventDefault();

    try {
      setMessage("Waiting on transaction success...");
      await scbackend.methods.revokeCertificateByID(id).send({
        from: web3.eth.defaultAccount,
        gas: '1000000',
    });
/* [OLD CODE]
      await scbackend.methods.book().send({
        from: accounts[0],
        value: web3.utils.toWei(enterValue, "ether"),
      });*/
      setMessage("Revoke sent");
      setId(0);
    } catch (err) {
      setMessage("ERROR (did you remember to previously load the wallet?)");
      console.log(err)
    }
  };
  
  return (
    <form onSubmit={onSubmit}>
      <h4>Form to revoke a certificate by the ID on the IOTA blockchain</h4>
      <div>
        <label htmlFor="id-value">Insert the certificate ID:</label>
        <input
          id="id-value"
          value={id}
          onChange={(event) => setId(event.target.value)}
        /><br></br>
      </div>
      <br></br>
      <button className="button revoke" type="submit">REVOKE by id</button>
    </form>
  );
}

export default RevokeCertByID;
