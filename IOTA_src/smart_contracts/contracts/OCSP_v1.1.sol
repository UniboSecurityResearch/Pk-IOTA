pragma solidity >=0.4.25 <0.4.26;
pragma experimental ABIEncoderV2;

contract sc_backend {
    //Indirizzo del backend che ha fatto il deploy dello sc
    address public backend;

    //Struttura certificato
    struct Certificate {
        string certificate;
        uint256 expireDate;
        bool revoked;
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

    //Evento di revoca di un certificato
    event revokedCertificate(string certificate, uint256 expireDate, uint256 id);
    
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

    //TODO: aggiungere restricted
    function revokeCertificateByID(uint id) public {
        certificates[id].revoked = true;
        emit revokedCertificate(certificates[id].certificate, certificates[id].expireDate, id);
    }

    //TODO: aggiungere resticted
    function revokeCertificate(string certificateString) public {
        for(uint256 i = 0; i <= certificateIDs.length; i++){
            if(keccak256(abi.encodePacked((certificates[i].certificate))) == keccak256(abi.encodePacked((certificateString)))){
                revokeCertificateByID(i);
                //break;
            }
        }
    }
    
    function createStruct(string certificate, uint256 expireDate) public {
        Certificate cert = certificates[certificateIDincr];
        cert.certificate = certificate;
        cert.expireDate = expireDate;
        cert.revoked = false; //not revoked
        certificateIDs.push(certificateIDincr) -1;
    }
    
    function getAllCertificates() public view returns (uint[]) {
        uint[] memory certificateIDs_valid = new uint[](certificateIDs.length+1);
        uint j = 0;
        for(uint256 i = 0; i <= certificateIDs.length; i++){
            if(certificates[i].expireDate > block.timestamp && certificates[i].revoked == false){
                certificateIDs_valid[j] = i;
                j++;
            }
        }
        return certificateIDs_valid;
    }

    function time() public view returns (uint){
        return block.timestamp;
    }
    
    function getCertificateByID(uint id) public view returns (string,uint256,bool) {
        return (certificates[id].certificate, certificates[id].expireDate, certificates[id].revoked);
    }

    function getCertificatesNumber() public view returns (uint256) {
        return certificateIDs.length;
    }
    
    modifier restricted() {
        require(msg.sender == backend);
        _;
    }
}