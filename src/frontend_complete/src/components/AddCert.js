import React, { useState } from "react";
import web3 from "../web3";
import scbackend from "../scbackend";

function AddCert({ setMessage }) {
  const [expireDate, setExpireDate] = useState(0);
  const [certificate, setCertificate] = useState("");
  const onSubmit = async (event) => {
    event.preventDefault();

    try {
      setMessage("Waiting on transaction success...");
      await scbackend.methods.addCertificate(certificate,expireDate).send({
        from: web3.eth.defaultAccount,
        gas: '1000000',
    });
/* [OLD CODE]
      await scbackend.methods.book().send({
        from: accounts[0],
        value: web3.utils.toWei(enterValue, "ether"),
      });*/
      setMessage("Certificate sent");
      setCertificate("");
      setExpireDate(0);
    } catch (err) {
      setMessage("ERROR (did you remember to previously load the wallet?)");
      console.log(err)
    }
  };
  
  return (
    <form onSubmit={onSubmit}>
      <h4>Form to send a certificate to the IOTA blockchain</h4>
      <div>
        <label htmlFor="enter-value">Insert the expire date:</label>
        <input
          id="expireDate-value"
          value={expireDate}
          onChange={(event) => setExpireDate(event.target.value)}
        /><br></br>
        <label htmlFor="enter-value">Insert the certificate data:</label>
        <input
          id="certificate-value"
          value={certificate}
          onChange={(event) => setCertificate(event.target.value)}
        /><br></br>
      </div>
      <br></br>
      <button className="button" type="submit">ADD</button>
    </form>
  );
}

export default AddCert;
