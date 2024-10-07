import web3 from "./web3";

//Lbrary with some functons to manage the wallets

const createAccount = (password) => {
  var account = web3.eth.accounts.create();
  console.log(account.address);
  console.log(account.privateKey);
  var acc = web3.eth.accounts.wallet.add(account);
  console.log(acc);
  var result = web3.eth.accounts.wallet.save(password);
  return result;
}

const loadAccount = (password) => {
   return web3.eth.accounts.wallet.load(password);
}


const getBalance = (ethAddress = null) => {
  return new Promise((resolve, reject) => {
    if (!web3.utils.isAddress(ethAddress)) {
      console.log('WalletService', 'getBalance', 'not a valid address');

      return reject({
        errorCode: 400,
        error: `${ethAddress} is not a valid address`
      });
    }

    web3.eth.getBalance(ethAddress, web3.eth.defaultBlock, (error, result) => {
      if (error) {
        console.log('WalletService', 'getBalance', error);

        return reject({
          errorCode: 500,
          error: error.message
        });
      }

      return resolve({
        ethAddress,
        balance: web3.utils.fromWei(result)
      });
    });
  });
};

const transaction = ({ privateKey, destination, amount }) => {
  return new Promise((resolve, reject) => {
    let account = null;

    if (
      !privateKey ||
      !amount ||
      !destination ||
      !(amount > 0) ||
      !web3.utils.isAddress(destination)
    ) {
      console.log(
        'WalletService',
        'transaction',
        'invalid transaction parameters'
      );

      reject({
        errorCode: 400,
        error: 'invalid transaction parameters'
      });
    }

    try {
      account = web3.eth.accounts.privateKeyToAccount(privateKey);
    } catch (error) {
      console.log(
        'WalletService',
        'transaction',
        'could not match private key to an account'
      );

      reject({
        errorCode: 400,
        error: 'could not match private key to an account'
      });
    }

    account
      .signTransaction({
        to: destination,
        value: web3.utils.toWei(amount, 'ether'),
        gas: 4700000
      })
      .then(
        transaction => {
          web3.eth
            .sendSignedTransaction(transaction.rawTransaction)
            .once('transactionHash', hash => {
              resolve({
                TxHash: hash
              });
            })
            .once('receipt', receipt =>
              console.log('WalletService', 'transaction', 'receipt', receipt)
            )
            .on('error', error => {
              console.log('WalletService', 'transaction', error.message);

              reject({
                errorCode: 500,
                error: error.message
              });
            });
        },
        error => {
          console.log('WalletService', 'transaction', error.message);

          reject({
            errorCode: 500,
            message: error.message
          });
        }
      );
  });
};

export { createAccount, loadAccount, getBalance, transaction };