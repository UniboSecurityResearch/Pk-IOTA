pragma solidity >=0.4.25 <0.4.26;
pragma experimental ABIEncoderV2;

contract sc_backend {
    //Indirizzo del backend che chiama lo sc
    address public backend;

    //Struttura certificato
    struct Certificate {
        string certificate;
        uint256 expireDate;
    }

    //Array di certificati
    mapping (uint => Certificate) certificates;

    //Array di indici
    uint[] public certificateIDs;
    //si parte da 1
    uint certificateIDincr = 1;
     
    //Evento di ricezione nuovo certificato
    //Address indexed ???
    event sendCertificate(string certificate, uint256 expireDate);
    
    constructor() public {
        //Set dell'address chiamante
        backend = msg.sender;
    }

    function getBackend() public view returns (address) {
        return backend;
    }

    //TODO: aggiungere restricted
    function addCertificate(string certificate, uint256 expireDate) public {
        bool confirm = true;
        uint id = 0;
        //Invio del certificato sulla blockchain
        if(confirm) {
            createStruct(certificate, expireDate);
            id = certificateIDincr;
            certificateIDincr = certificateIDincr + 1;
        }
        emit sendCertificate(certificate, expireDate);
    }
    
    function createStruct(string certificate, uint256 expireDate) public {
        Certificate cert = certificates[certificateIDincr];
        cert.certificate = certificate;
        cert.expireDate = expireDate;
        certificateIDs.push(certificateIDincr) -1;
    }
    
    function getAllCertificates() public view returns (uint[]) {
        return certificateIDs;
    }
    
    function getCertificateByID(uint id) public view returns (string,uint256) {
        return (certificates[id].certificate, certificates[id].expireDate);
    }

    function getCertificatesNumber() public view returns (uint256) {
        return certificateIDs.length;
    }
    
    modifier restricted() {
        require(msg.sender == backend);
        _;
    }
}