pragma solidity ^0.4.13;

import "./libs/Models.sol";
import "./ManagerToken.sol";

contract GenesisVisionPlatform {

    uint256 constant startLevel = 1;
    address contractOwner;
    address genesisVisionAdmin;

    mapping (string => Models.Exchange) exchanges;
    mapping (string => Models.InvestmentProgram) investmentPrograms;

    event NewExchange(string exchangeId);
    event NewInvestmentProgram(string investmentProgramId, string exchangeId);
    event InvestmentProgramUpdated(string investmentProgramId);
    event InvestmentProgramLevelRaised(string programId);

    modifier ownerOnly() {
        require(msg.sender == contractOwner);
        _;
    }

    modifier gvAdminAndOwnerOnly() {
        require(msg.sender == genesisVisionAdmin || msg.sender == contractOwner);
        _;
    }
    
    function GenesisVisionPlatform() public {
        contractOwner = msg.sender;
    }

    function setGenesisVisionAdmin(address admin) public ownerOnly() {
        genesisVisionAdmin = admin;
    }

    function registerExchange(string id, string name) public gvAdminAndOwnerOnly() {
        require(bytes(exchanges[id].id).length == 0);
        exchanges[id] = Models.Exchange(id, name);
        emit NewExchange(id);
    }

    function getExchange(string exchangeId) public constant returns (string, string) {
        return (exchanges[exchangeId].id, exchanges[exchangeId].name);
    }

    function createInvestmentProgram(string tokenName, string tokenSymbol, string id, string exchangeId, string ipfsHash) public gvAdminAndOwnerOnly() {
        require(bytes(investmentPrograms[id].id).length == 0);
        require(bytes(exchanges[exchangeId].id).length != 0);
        address managerToken = new ManagerToken(this, tokenName, tokenSymbol);
        investmentPrograms[id] = Models.InvestmentProgram(managerToken, id, exchangeId, ipfsHash, startLevel);
        emit NewInvestmentProgram(id, exchangeId);
    }

    function getInvestmentProgram(string programId) public constant returns (address, string, string, string, uint256) {
        return (investmentPrograms[programId].token, investmentPrograms[programId].id , investmentPrograms[programId].exchangeId, investmentPrograms[programId].ipfsHash, investmentPrograms[programId].level);
    }

    function raiseLevelInvestmentProgram(string programId, uint256 tokenCount) public{
        ManagerToken managerToken = ManagerToken(investmentPrograms[programId].token);
        managerToken.raiseLimit(tokenCount);
        investmentPrograms[programId].level += 1;
        emit InvestmentProgramLevelRaised(programId);
    }

    function updateInvestmentProgramHistoryIpfsHash(string programId, string ipfsHash) public gvAdminAndOwnerOnly() {
        investmentPrograms[programId].ipfsHash = ipfsHash;
        emit InvestmentProgramUpdated(programId);
    }

    function transferManagerToken(string programId, address receiver, uint256 tokenCount) public gvAdminAndOwnerOnly() {
        ManagerToken managerToken = ManagerToken(investmentPrograms[programId].token);
        require(managerToken.transfer(receiver,tokenCount) == true);
    }

} 
  