# Frontend application - IIoT Certificate Management with IOTA

Example of frontend application which connects to the smart contract to use the OCSP features and manage certificates.<br>
**This work with nodejs version 22.0.0** !! Use n ( _npm install -g n_ ) to select the rigth version ( _sudo n 22.0.0_ )
<br>
<br>
**Currently, the interaction with the IOTA blockchain does not work properly using web3 version 4+; therefore, this project use the legacy version of web3 1.10.4 and web3-utils 1.10.4 (and also web3 v 1.2.11 seems to be working fine).**

## Instructions

### 1. Deployment
  First of all, **deploy the smart contract** that you can find in the folder ../contracts (you can deploy the contract with the online tool _Remix_, for example) for EMV version shangai.

### 2. Configure the env
  Once the smart contract is deployed, take the address where it is deployed and insert it inside the **.env** file at the property "**REACT_APP_SCBACKEND_ADDRESS**". <br>

  Moreover, you need to take the _**ABI code**_ of the contract (for example, in _Remix_ is easy to take it from the interface: follow the instruction of the tool). Insert the ABI code inside the abi.txt file. (for now, insert the abi code also inside the ./src/scbackend.js, in the apposite variable).

### 3. Run npm
  Run **npm install**, to install the necessary dependencies of the project. <br>
  Run **npm start**, to run the frontend. It should automatically open the browser at _localhost:3000_. If not, open it manually.

### 4. Create / Load the wallet
  This project **does not** use Mematask plugin, as it only works with https json-rpc, but the management of events needs wss interactions. So, the Metamask plugin is not needed, but you need to create and load a personal wallet prior to use the smart contract interactions. Use the apposite form to create a wallet the first time and save it with a password; then you can load the wallet. 
  
  The following times, you only need to load the wallet.

At this point, you are ready to go!
