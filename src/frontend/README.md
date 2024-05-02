# Frontend application

Example of frontend application which connects to the smart contract to use the OCSP features and manage certificates.
**This work with nodejs version 10.24.1** !! Use n ( _npm install -g n_ ) to select the rigth version ( _n 10.24.1_ )

## Instructions

### 1. Deployment
  First of all, **deploy the smart contract** that you can find in the folder ../contracts (you can deploy the contract with the online tool _Remix_, for example).

### 2. Configure the env
  Once the smart contract is deployed, take the address where it is deployed and insert it inside the **.env** file at the property "**REACT_APP_SCBACKEND_ADDRESS**". <br>

  Moreover, you need to take the _**ABI code**_ of the contract (for example, in _Remix_ is easy to take it from the interface: follow the instruction of the tool). Insert  the ABI code inside the abi.txt file. (for now, insert the abi code also inside the ./src/scbackend.js, in the apposite variable).

### 3. Run npm
  Run **npm install**, to install the necessary dependencies of the project. <br>
  Run **npm start**, to run the frontend. It should automatically open the browser at _localhost:3000_. If not, open it manually.
