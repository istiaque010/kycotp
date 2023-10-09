// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './userRegistration.sol';

contract KYC {
    address public owner;
    userRegistration addUserReg;

    
    enum KYCStatus { Pending, Approved, Rejected }
    enum OTPStatus { Pending, Approved}
    
    struct KYCRequest {
        address userAddress;
        string userName;
        string id;
        string phoneNum;
        string identificationDocument;
        KYCStatus status;
        
        OTPStatus otpstatus; // for OTP
        uint256 otpExpirationTime; // New field for OTP expiration time
        uint256 OTP; // New field for OTP
    }
    
    mapping(address => KYCRequest) public kycRequests;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }


     modifier onlyRegisteredUser() {
        require(addUserReg.isUserRegistered(msg.sender), "Only registered user can request verification for KYC");
        _;
    }

    constructor(address _addUserReg) {
        owner = msg.sender;
        addUserReg=userRegistration(_addUserReg); //convert the address and set the address for userRegistration
    }

    function submitKYCRequest(string memory _userName, string memory _id, string memory _phoneNum, string memory _identificationDocument) external onlyRegisteredUser{
        require(kycRequests[msg.sender].userAddress == address(0), "KYC request already submitted");

         // Generate a random 6-digit OTP
        uint256 otp = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 1000000;
        uint256 otpExpirationTime = block.timestamp + 2 minutes; // OTP expires in 2 minutes
        
        kycRequests[msg.sender] = KYCRequest({
            userAddress: msg.sender,
            userName: _userName,
            id:_id,
            phoneNum:_phoneNum,
            identificationDocument: _identificationDocument,
            status: KYCStatus.Pending,
            otpstatus:OTPStatus.Pending,
            otpExpirationTime: otpExpirationTime,
            OTP: otp
        });
    }
    
    
    // Function for users to verify their KYC using OTP
    function verifyOTP(uint256 _otp) external {
        KYCRequest storage request = kycRequests[msg.sender];
        require(request.status == KYCStatus.Pending, "KYC request is not pending");
        require(block.timestamp <= request.otpExpirationTime, "OTP has expired");
        require(request.OTP == _otp, "Invalid OTP");

        kycRequests[msg.sender].otpstatus = OTPStatus.Approved;
    }



    // Function to approve KYC with verified OTP
    function verifyKYCWithOTP(address _userAddress) external onlyOwner {
        KYCRequest storage request = kycRequests[_userAddress];
        require(request.status == KYCStatus.Pending, "KYC request is not pending");
        require(request.otpstatus == OTPStatus.Approved, "OTP verification is not completed");

        kycRequests[_userAddress].status = KYCStatus.Approved;
    }

    
    function rejectKYC(address _userAddress) external onlyOwner {
        kycRequests[_userAddress].status = KYCStatus.Rejected;
    }

    function regenerateOTP() external {
        KYCRequest storage request = kycRequests[msg.sender];
        require(request.status == KYCStatus.Pending, "KYC request is not pending");
        require(block.timestamp > request.otpExpirationTime, "OTP has not expired");

        uint256 otp = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 1000000;
        uint256 otpExpirationTime = block.timestamp + 2 minutes;

        kycRequests[msg.sender].OTP = otp;
        kycRequests[msg.sender].otpExpirationTime = otpExpirationTime;
        kycRequests[msg.sender].otpstatus = OTPStatus.Pending;
    }


    // Function to get KYC information for a specific user address
    function getKYCInfo(address _userAddress) external view onlyOwner returns (KYCRequest memory) {
        return kycRequests[_userAddress];
    }

    
    function getKYCStatus(address _userAddress) external view returns (KYCStatus) {
        return kycRequests[_userAddress].status;
    }

    function isKYCapproved(address _userAddress) external view returns (bool) {

        KYCStatus currentKYCstatus= kycRequests[_userAddress].status;
        if(currentKYCstatus==KYCStatus.Approved)
           return  true;
        else 
           return false;
    }
    
    // Function to get a user's own OTP
    function getOwnOTP() external view returns (uint256) {
        KYCRequest storage request = kycRequests[msg.sender];
        return request.OTP;
    }


}