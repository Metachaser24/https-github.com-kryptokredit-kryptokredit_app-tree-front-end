// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Invoice.sol";
import "./Verify.sol";
import "./Admin.sol";
import "./IValidator.sol";

contract InvoiceFactory is NFTInvoice, VerifySignature, AdminOnly {
    uint256 public invoiceCount = 0; // To keep track of the number of invoices
    mapping(address => bool) public whitelist;
    IValidatorNFT public validatorContract;
    event AddressAdded(address indexed account);
    event AddressRemoved(address indexed account);

    mapping(uint256 => Invoice) public invoices; // To store the details of each invoice
    mapping(uint256 => Request) public requests;

    struct Request {
        uint256 id;
        uint256 fee;
        uint256 amount;
        uint256 creationDate;
        uint256 dueDate;
        bool paid;
        bool tokenIssued;
        address invoicer;
        address payer;
        bytes invoicerSignature;
        bytes payerSignature;
    }

    struct Invoice {
        uint256 id;
        uint256 fee;
        uint256 amount;
        uint256 creationDate;
        uint256 dueDate;
        bool paid;
        bool tokenIssued;
        address invoicer;
        address payer;
        address validatorAddress;
        bytes invoicerSignature;
        bytes payerSignature;
        bytes validatorSignature;
    }

    struct GoodToken {
        uint256 id;
        bool minted;
    }

    struct BadToken {
        uint256 id;
        bool minted;
    }

    event InvoiceCreated(
        uint256 id,
        uint256 fee,
        uint256 amount,
        uint256 dueDate,
        bool paid,
        address invoicer,
        address payer
    );

    event InvoicePaid(
        uint256 id,
        bool paid,
        uint256 dueDate,
        uint256 date,
        address payer,
        address invoicer,
        bool paidLate
    );

    event InvoiceUpdated(
        uint256 id,
        uint256 date,
        uint256 fee,
        uint256 amount,
        uint256 dueDate
    );

    event NewRequest(
        uint256 id,
        uint256 date,
        uint256 fee,
        uint256 amount,
        uint256 dueDate,
        address invoicer,
        address payer
    );

    event Decline(
        uint256 id,
        uint256 date,
        uint256 fee,
        uint256 amount,
        uint256 dueDate,
        address invoicer,
        address payer
    );

    event InvoicerSigned(uint256 id, bytes signature);
    event ValidatorSigned(uint256 id, bytes signature);
    event PayerSigned(uint256 id, bytes signature);

    event TokenIssued(uint256 id, uint256 tokenId, uint256 date);

    constructor() {}

    modifier amountNotZero(uint256 _amount) {
        require(_amount > 0, "Amount cannot be 0");
        _;
    }

    modifier isTheFuture(uint256 _dueDate) {
        require(_dueDate > block.timestamp, "Due date must be in the future");
        _;
    }

    modifier validID(uint256 _id) {
        require(_id > 0 && _id <= invoiceCount, "Invalid invoice ID");
        _;
    }

    modifier onlyPayer(uint256 _id) {
        require(
            msg.sender == invoices[_id].payer,
            "Only payer can sign the invoice"
        );
        _;
    }

    modifier onlyInvoicer(uint256 _id) {
        require(
            msg.sender == invoices[_id].invoicer,
            "Only invoicer can sign the invoice"
        );
        _;
    }

    modifier OnlyValidator(uint256 _id) {
        require(
            msg.sender == invoices[_id].validatorAddress,
            "Only invoicer can sign the invoice"
        );
        _;
    }

    modifier paid(uint256 _id) {
        require(!invoices[_id].paid, "Invoice already paid");
        _;
    }

    modifier payerSigned(uint256 _id) {
        require(
            keccak256(bytes(invoices[_id].payerSignature)) !=
                keccak256(hex"00"),
            "Payer signature is missing"
        );
        _;
    }

    modifier onlyNotWhitelisted(address account) {
        require(!whitelist[account], "Account is already whitelisted");
        _;
    }

    modifier onlyWhitelisted(address account) {
        require(whitelist[account], "Account is not whitelisted");
        _;
    }

function updateValidatorContract(IValidatorNFT _validatorContract) public onlyAdmin {
    validatorContract = _validatorContract;
}

    function addAddressToWhitelist(address account) public onlyAdmin {
        whitelist[account] = true;
        emit AddressAdded(account);
    }

    function addAddressesToWhitelist(address[] memory accounts)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            addAddressToWhitelist(accounts[i]);
        }
    }

    function removeAddressFromWhitelist(address account) public onlyAdmin {
        whitelist[account] = false;
        emit AddressRemoved(account);
    }

    function createInvoice(
        uint256 _amount,
        uint256 _dueDate,
        address _payer,
        address _validator,
        uint256 _fee
    ) public amountNotZero(_amount) isTheFuture(_dueDate) returns (uint256) {
        invoiceCount++;
        invoices[invoiceCount] = Invoice(
            invoiceCount,
            _fee,
            _amount,
            block.timestamp,
            _dueDate,
            false,
            false,
            msg.sender,
            _payer,
            _validator,
            "",
            "",
            ""
        );
        return invoiceCount;
    }

    function signInvoiceInvoicer(uint256 _id, bytes memory _invoicerSignature)
        public
        validID(_id)
        onlyInvoicer(_id)
    {
        Invoice storage invoice = invoices[_id];
        require(
            block.timestamp <= invoice.creationDate + 86400,
            "Time to sign has passed"
        );
        invoices[_id].invoicerSignature = _invoicerSignature;
        emit InvoicerSigned(_id, _invoicerSignature);
    }

    function signInvoicePayer(uint256 _id, bytes memory _payerSignature)
        public
        validID(_id)
        onlyPayer(_id)
    {
        Invoice storage invoice = invoices[_id];
        require(
            block.timestamp <= invoice.creationDate + 86400,
            "Time to sign has passed"
        );
        invoices[_id].payerSignature = _payerSignature;
        emit PayerSigned(_id, _payerSignature);
    }

    function signInvoiceValidator(uint256 _id, bytes memory _validatorSignature)
        public
        validID(_id)
        OnlyValidator(_id)
    {
        Invoice storage invoice = invoices[_id];
        require(
            block.timestamp <= invoice.creationDate + 86400,
            "Time to sign has passed"
        );
        uint256 validatorStake = IValidatorNFT(validatorContract).getStake(
            msg.sender
        );
        require(
            validatorStake >= invoice.amount / 100,
            "Validator stake is insufficient"
        );
        invoices[_id].validatorSignature = _validatorSignature;
        emit ValidatorSigned(_id, _validatorSignature);
    }

    function verifySignatures(uint256 _id)
        public
        view
        validID(_id)
        returns (bool)
    {
        bytes memory sig1 = invoices[_id].invoicerSignature;
        bytes memory sig2 = invoices[_id].payerSignature;
        require(keccak256(sig1) != bytes32(0), "Sig1 is not stored");
        require(keccak256(sig2) != bytes32(0), "Sig2 is not stored");
        return true;
    }

    function mintTheInvoice(uint256 _id, string memory uri)
        public
        validID(_id)
        onlyInvoicer(_id)
    {
        Invoice storage invoice = invoices[_id];
        require(
            verifySignatures(_id) == true,
            "Both signatures are not there yet"
        );

        require(
            verify(
                invoice.invoicer,
                invoice.invoicer,
                invoice.payer,
                invoice.amount,
                invoice.dueDate,
                _id,
                invoice.invoicerSignature
            ) == true,
            "Not the correct signature 1"
        );

        require(
            verify(
                invoice.payer,
                invoice.invoicer,
                invoice.payer,
                invoice.amount,
                invoice.dueDate,
                _id,
                invoice.payerSignature
            ) == true,
            "Not the correct signature 2"
        );
        safeMint(invoice.invoicer, uri);
        emit InvoiceCreated(
            _id,
            invoices[_id].fee,
            invoice.amount,
            invoice.dueDate,
            false,
            invoice.invoicer,
            msg.sender
        );
    }

    function payInvoice(uint256 _id)
        public
        payable
        validID(_id)
        paid(_id)
        onlyPayer(_id)
    {
        require(msg.value == invoices[_id].amount, "Incorrect payment amount");
        // Calculate the late fee if payment is made after the due date
        uint256 lateFee = 0;
        payable(invoices[_id].invoicer).transfer(msg.value + lateFee);
        if (block.timestamp > invoices[_id].dueDate) {
            lateFee = (invoices[_id].amount * invoices[_id].fee) / 100;
        }

        invoices[_id].paid = true;
        invoices[_id].tokenIssued = false;
        _safeTransfer(invoices[_id].invoicer, msg.sender, _id, new bytes(0));

        emit InvoicePaid(
            _id,
            true,
            invoices[_id].dueDate,
            block.timestamp,
            invoices[_id].payer,
            invoices[_id].invoicer,
            block.timestamp > invoices[_id].dueDate
        );
    }

    function requestRenegotiation(
        uint256 _id,
        uint256 _newAmount,
        uint256 _newFee,
        uint256 _newDate,
        bytes memory _payerSignature
    ) public validID(_id) onlyPayer(_id) paid(_id) amountNotZero(_newAmount) {
        address invocier = invoices[_id].invoicer;
        requests[_id] = Request(
            _id,
            _newFee,
            _newAmount,
            block.timestamp,
            _newDate,
            false,
            false,
            invocier,
            msg.sender,
            "",
            _payerSignature
        );
        emit NewRequest(
            _id,
            block.timestamp,
            _newFee,
            _newAmount,
            _newDate,
            invocier,
            msg.sender
        );
    }

    function declineRenegotiation(uint256 _id)
        public
        validID(_id)
        onlyInvoicer(_id)
    {
        requests[_id] = Request(
            _id,
            0,
            0,
            0,
            0,
            false,
            false,
            msg.sender,
            invoices[_id].payer,
            "",
            ""
        );
        emit Decline(
            _id,
            block.timestamp,
            invoices[_id].fee,
            invoices[_id].amount,
            invoices[_id].dueDate,
            invoices[_id].invoicer,
            invoices[_id].payer
        );
    }

    function acceptRenegotiation(uint256 _id, bytes memory _invoicerSignature)
        public
        validID(_id)
        onlyInvoicer(_id)
        payerSigned(_id)
    {
        Request storage request = requests[_id];
        require(
            block.timestamp <= request.creationDate + 86400,
            "Time to sign has passed"
        );
        require(verifySignatures(_id) == true, "Need 2 signatures");
        require(
            verify(
                request.invoicer,
                request.invoicer,
                request.payer,
                request.amount,
                request.dueDate,
                _id,
                _invoicerSignature
            ) == true,
            "Not the correct signature 1"
        );
        require(
            verify(
                request.payer,
                request.invoicer,
                request.payer,
                request.amount,
                request.dueDate,
                _id,
                request.payerSignature
            ) == true,
            "Not the correct signature 2"
        );
        invoices[_id] = Invoice(
            _id,
            requests[_id].fee,
            requests[_id].amount,
            invoices[_id].creationDate,
            requests[_id].dueDate,
            false,
            false,
            msg.sender,
            requests[_id].payer,
            invoices[_id].validatorAddress,
            _invoicerSignature,
            requests[_id].payerSignature,
            ""
        );

        emit InvoiceUpdated(
            _id,
            block.timestamp,
            requests[_id].fee,
            requests[_id].amount,
            requests[_id].dueDate
        );
    }

    function closeDeal(uint256 _id) public onlyInvoicer(_id) validID(_id) {
        Invoice storage invoice = invoices[_id];
        require(!invoice.paid, "Invoice paid");
        require(verifySignatures(_id) == true, "Need 2 signatures");

        require(
            verify(
                invoice.invoicer,
                invoice.invoicer,
                invoice.payer,
                invoice.amount,
                invoice.dueDate,
                _id,
                invoice.invoicerSignature
            ) == true,
            "Not the correct signature 1"
        );

        require(
            verify(
                invoice.payer,
                invoice.invoicer,
                invoice.payer,
                invoice.amount,
                invoice.dueDate,
                _id,
                invoice.payerSignature
            ) == true,
            "Not the correct signature 2"
        );

        require(
            verify(
                invoice.validatorAddress,
                invoice.invoicer,
                invoice.payer,
                invoice.amount,
                invoice.dueDate,
                _id,
                invoice.validatorSignature
            ) == true,
            "Not the correct signature 3"
        );

        _safeTransfer(invoices[_id].invoicer, msg.sender, _id, new bytes(0));
        emit InvoicePaid(
            _id,
            true,
            invoices[_id].dueDate,
            block.timestamp,
            invoices[_id].payer,
            invoices[_id].invoicer,
            block.timestamp > invoices[_id].dueDate
        );
    }

    function getInvoice(uint256 _id)
        public
        view
        returns (
            uint256 id,
            uint256 fee,
            uint256 amount,
            uint256 creationDate,
            uint256 dueDate,
            bool paidd,
            bool tokenIssued,
            address invoicer,
            address payer,
            bytes memory invoicerSignature,
            bytes memory payerSignature
        )
    {
        require(_id > 0 && _id <= invoiceCount, "Invalid invoice ID");
        Invoice storage invoice = invoices[_id];
        id = invoice.id;
        fee = invoice.fee;
        amount = invoice.amount;
        creationDate = invoice.creationDate;
        dueDate = invoice.dueDate;
        paidd = invoice.paid;
        tokenIssued = invoice.tokenIssued;
        invoicer = invoice.invoicer;
        payer = invoice.payer;
        invoicerSignature = invoice.invoicerSignature;
        payerSignature = invoice.payerSignature;
    }
}
