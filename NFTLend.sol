// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTLoan is ReentrancyGuard {
    // Contract owner
    address public goon;
    // Fee for creating a loan
    uint256 public creationFee;
    // Minimum interest rate for loans
    uint256 public minInterestRate;
    // Maximum interest rate for loans
    uint256 public maxInterestRate;

    uint256 public extendFee = 0.1 ether; // Tarifa para extender el plazo

    // Lender structure to store lender details
    struct Lender {
        address lender;
        uint256 amount;
    }

    // Collateral structure to store NFT details
    struct Collateral {
        address nftAddress;
        uint256 tokenId;
    }

    // Loan structure to store loan details
    struct Loan {
        address borrower;
        uint256 loanAmount;
        uint256 loanDuration;
        uint256 loanEndTime;
        uint256 maxLenders;
        bool loanFilled;
        bool loanRepaid;
        Lender[] lenders;
        uint256 totalLentAmount;
        Collateral[] collaterals;
    }

    // Loan counter to track the number of loans
    uint256 public loanCounter;
    // Default loan duration
    uint256 public defaultLoanDuration;
    // Mapping to store loans by their ID
    mapping(uint256 => Loan) public loans;

    // Events to log important actions
    event LoanCreated(
        uint256 loanId,
        address borrower,
        uint256 loanAmount,
        uint256 loanDuration
    );
    event LoanFilled(uint256 loanId);
    event LoanRepaid(uint256 loanId);
    event CollateralSeized(
        uint256 loanId,
        address indexed lender,
        address nftAddress,
        uint256 tokenId
    );
    event CollateralReturned(
        uint256 loanId,
        address nftAddress,
        uint256 tokenId
    );
    event LoanExtended(
        uint256 loanId,
        uint256 newDuration,
        uint256 newInterestRate
    );

    // Modifier to restrict access to the contract owner
    modifier onlyGoon() {
        require(msg.sender == goon, "Only goon can call this function");
        _;
    }

    // Modifier to restrict access to the borrower of a loan
    modifier onlyBorrower(uint256 loanId) {
        require(
            msg.sender == loans[loanId].borrower,
            "Only borrower can call this function"
        );
        _;
    }

    // Modifier to restrict access to the lenders of a loan
    modifier onlyLenders(uint256 loanId) {
        bool isLender = false;
        for (uint256 i = 0; i < loans[loanId].lenders.length; i++) {
            if (loans[loanId].lenders[i].lender == msg.sender) {
                isLender = true;
                break;
            }
        }
        require(isLender, "Only lenders can call this function");
        _;
    }

    // Constructor to initialize the contract with default values
    constructor(
        uint256 _defaultLoanDuration,
        uint256 _minInterestRate,
        uint256 _maxInterestRate,
        uint256 _creationFee
    ) {
        defaultLoanDuration = _defaultLoanDuration;
        minInterestRate = _minInterestRate;
        maxInterestRate = _maxInterestRate;
        creationFee = _creationFee;
        goon = msg.sender;
    }

    // Function to set the creation fee
    function setFee(uint256 newFee) public onlyGoon {
        creationFee = newFee;
    }

    // Function to withdraw funds from the contract
    function withdrawFunds(address payable to, uint256 amount)
        public
        onlyGoon
        nonReentrant
    {
        require(
            amount <= address(this).balance,
            "Insufficient contract balance"
        );
        to.transfer(amount);
    }

    // Function to set the loan duration
    function setLoanDuration(uint256 loanId, uint256 newLoanDuration)
        public
        onlyGoon
    {
        loans[loanId].loanDuration = newLoanDuration;
    }

    // Function to set the maximum number of lenders for a loan
    function setMaxLenders(uint256 loanId, uint256 newMaxLenders)
        public
        onlyGoon
    {
        loans[loanId].maxLenders = newMaxLenders;
    }

    // Function to set the minimum interest rate
    function setMinInterestRate(uint256 newMinInterestRate) public onlyGoon {
        minInterestRate = newMinInterestRate;
    }

    // Function to set the maximum interest rate
    function setMaxInterestRate(uint256 newMaxInterestRate) public onlyGoon {
        maxInterestRate = newMaxInterestRate;
    }

    // Function to create a new loan
    function createLoan(uint256 loanAmount, uint256 maxLenders) public payable {
        require(msg.value >= creationFee, "Insufficient fee");

        loanCounter++;
        Loan storage newLoan = loans[loanCounter];
        newLoan.borrower = msg.sender;
        newLoan.loanAmount = loanAmount;
        newLoan.loanDuration = defaultLoanDuration;
        newLoan.maxLenders = maxLenders;

        emit LoanCreated(
            loanCounter,
            msg.sender,
            loanAmount,
            defaultLoanDuration
        );
    }

    // Function for the borrower to provide collateral for the loan
    function provideCollateral(
        uint256 loanId,
        address nftAddress,
        uint256 tokenId
    ) public onlyBorrower(loanId) nonReentrant {
        require(
            !loans[loanId].loanFilled,
            "Cannot provide collateral after loan is filled"
        );
        IERC721(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        loans[loanId].collaterals.push(Collateral(nftAddress, tokenId));
    }

    // Function for lenders to fund the loan
    function fundLoan(uint256 loanId) public payable nonReentrant {
        Loan storage loan = loans[loanId];
        require(!loan.loanFilled, "Loan is already filled");
        require(msg.value > 0, "Funding amount must be greater than zero");
        require(
            loan.lenders.length < loan.maxLenders,
            "Maximum number of lenders reached"
        );

        loan.lenders.push(Lender(msg.sender, msg.value));
        loan.totalLentAmount += msg.value;

        if (loan.totalLentAmount >= loan.loanAmount) {
            loan.loanFilled = true;
            loan.loanEndTime = block.timestamp + loan.loanDuration;
            payable(loan.borrower).transfer(loan.totalLentAmount);
            emit LoanFilled(loanId);
        }
    }

    // Function for the borrower to repay the loan
    function repayLoan(uint256 loanId)
        public
        payable
        onlyBorrower(loanId)
        nonReentrant
    {
        Loan storage loan = loans[loanId];
        require(loan.loanFilled, "Loan is not filled yet");
        require(block.timestamp <= loan.loanEndTime, "Loan duration has ended");
        require(!loan.loanRepaid, "Loan is already repaid");

        uint256 interestRate = calculateInterestRate(loanId, 0, false);
        uint256 totalRepayment = loan.loanAmount +
            ((loan.loanAmount * interestRate) / 100);
        require(msg.value == totalRepayment, "Incorrect repayment amount");

        // Iteration and repayment using assembly for gas optimization
        assembly {
            let lendersSlot := add(loan.slot, 8) // Load the lenders array slot
            let lendersLen := sload(lendersSlot) // Load the length of the lenders array
            let i := 0

            for {

            } lt(i, lendersLen) {
                i := add(i, 1)
            } {
                let lenderSlot := add(
                    keccak256(add(lendersSlot, 0x20), 0x20),
                    mul(i, 2)
                )
                let lenderAddress := sload(lenderSlot) // Load lender address
                let lenderAmount := sload(add(lenderSlot, 1)) // Load lender amount

                let repayment := add(
                    lenderAmount,
                    div(mul(lenderAmount, interestRate), 100)
                ) // Calculate repayment
                let success := call(gas(), lenderAddress, repayment, 0, 0, 0, 0) // Transfer repayment

                if iszero(success) {
                    revert(0, 0)
                }
            }
        }

        loan.loanRepaid = true;
        emit LoanRepaid(loanId);

        // Return collaterals to borrower
        uint256 collateralsLength = loan.collaterals.length;
        for (uint256 i = 0; i < collateralsLength; i++) {
            Collateral storage collateral = loan.collaterals[i];
            IERC721(collateral.nftAddress).safeTransferFrom(
                address(this),
                loan.borrower,
                collateral.tokenId
            );
            emit CollateralReturned(
                loanId,
                collateral.nftAddress,
                collateral.tokenId
            );
        }
    }

    // Function to extend the loan duration
    function extendLoanDuration(uint256 loanId, uint256 additionalTime)
        public
        payable
        onlyBorrower(loanId)
        nonReentrant
    {
        require(msg.value >= extendFee, "Insufficient fee");
        Loan storage loan = loans[loanId];
        require(loan.loanFilled, "Loan is not filled yet");
        require(block.timestamp <= loan.loanEndTime, "Loan duration has ended");
        require(
            loan.loanDuration + additionalTime <= 12 * 30 days,
            "Cannot extend beyond 12 months"
        );

        loan.loanDuration += additionalTime;
        loan.loanEndTime += additionalTime;

        uint256 newInterestRate = calculateInterestRate(
            loanId,
            additionalTime,
            true
        );
        emit LoanExtended(loanId, loan.loanDuration, newInterestRate);
    }

    // Function for lenders to seize collateral if the loan is not repaid on time
    function seizeCollateral(uint256 loanId)
        public
        onlyLenders(loanId)
        nonReentrant
    {
        Loan storage loan = loans[loanId];
        require(!loan.loanRepaid, "Loan is already repaid");
        require(
            block.timestamp > loan.loanEndTime,
            "Loan duration has not ended"
        );

        uint256 remainingCollaterals = loan.collaterals.length;
        for (uint256 i = 0; i < loan.lenders.length; i++) {
            uint256 lenderShare = (loan.lenders[i].amount *
                remainingCollaterals) / loan.totalLentAmount;
            for (
                uint256 j = 0;
                j < lenderShare && loan.collaterals.length > 0;
                j++
            ) {
                Collateral memory collateral = loan.collaterals[
                    loan.collaterals.length - 1
                ];
                IERC721(collateral.nftAddress).safeTransferFrom(
                    address(this),
                    loan.lenders[i].lender,
                    collateral.tokenId
                );
                emit CollateralSeized(
                    loanId,
                    loan.lenders[i].lender,
                    collateral.nftAddress,
                    collateral.tokenId
                );
                loan.collaterals.pop();
            }
        }
    }

    // Function for the borrower to cancel the loan if it is not filled
    function cancelLoan(uint256 loanId)
        public
        onlyBorrower(loanId)
        nonReentrant
    {
        Loan storage loan = loans[loanId];
        require(!loan.loanFilled, "Cannot cancel a filled loan");
        require(!loan.loanRepaid, "Cannot cancel a repaid loan");

        for (uint256 i = 0; i < loan.collaterals.length; i++) {
            IERC721(loan.collaterals[i].nftAddress).safeTransferFrom(
                address(this),
                loan.borrower,
                loan.collaterals[i].tokenId
            );
            emit CollateralReturned(
                loanId,
                loan.collaterals[i].nftAddress,
                loan.collaterals[i].tokenId
            );
        }

        delete loans[loanId];
    }

    // Function for lenders to withdraw their funds before the loan is filled
    function withdrawFundsBeforeLoanFilled(uint256 loanId) public nonReentrant {
        Loan storage loan = loans[loanId];
        require(
            !loan.loanFilled,
            "Cannot withdraw funds after the loan is filled"
        );

        uint256 lenderIndex = findLenderIndex(loanId, msg.sender);
        require(
            lenderIndex < loan.lenders.length,
            "You are not a lender for this loan"
        );

        uint256 amount = loan.lenders[lenderIndex].amount;

        // Remove lender from lenders array
        for (uint256 i = lenderIndex; i < loan.lenders.length - 1; i++) {
            loan.lenders[i] = loan.lenders[i + 1];
        }
        loan.lenders.pop();

        loan.totalLentAmount -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Internal function to find lender index
    function findLenderIndex(uint256 loanId, address lenderAddress)
        internal
        view
        returns (uint256)
    {
        Loan storage loan = loans[loanId];
        for (uint256 i = 0; i < loan.lenders.length; i++) {
            if (loan.lenders[i].lender == lenderAddress) {
                return i;
            }
        }
        revert("Lender not found");
    }

    // Function to get the number of collaterals for a loan
    function getCollateralCount(uint256 loanId) public view returns (uint256) {
        return loans[loanId].collaterals.length;
    }

    // Function to get the number of lenders for a loan
    function getLenderCount(uint256 loanId) public view returns (uint256) {
        return loans[loanId].lenders.length;
    }

    // Internal function to calculate the interest rate based on the elapsed time using exponential growth
    function calculateInterestRate(
        uint256 loanId,
        uint256 additionalTime,
        bool isExtension
    ) internal view returns (uint256) {
        Loan storage loan = loans[loanId];
        uint256 elapsedTime = block.timestamp -
            (loan.loanEndTime - loan.loanDuration);
        uint256 duration = isExtension
            ? loan.loanDuration + additionalTime
            : loan.loanDuration;

        if (elapsedTime >= duration) {
            return maxInterestRate + (isExtension ? 2 : 0); // Incrementa el interés en 2 puntos para extensiones
        }

        uint256 adjustmentFactor = isExtension ? 2e18 : 1.5e18; // Factor ajustado para una curva más pronunciada si es extensión
        uint256 elapsedRatio = (elapsedTime * 1e18) / duration;
        uint256 exponentialGrowth = exp(
            (elapsedRatio * adjustmentFactor) / 1e18
        );

        uint256 interestRate = minInterestRate +
            (((maxInterestRate + (isExtension ? 2 : 0)) - minInterestRate) *
                (exponentialGrowth - 1)) /
            (exp(adjustmentFactor) - 1);
        return interestRate;
    }

    // Helper function to calculate the exponential of a number (e^x)
    function exp(uint256 x) internal pure returns (uint256) {
        uint256 sum = 1e18; // The sum of the series, starting with the 0th term: 1
        uint256 term = 1e18; // The value of each term in the series, starting with the 0th term: 1

        for (uint256 i = 1; i < 10; i++) {
            term = (term * x) / (i * 1e18); // Calculate the next term in the series
            sum += term; // Add the term to the sum
        }

        return sum;
    }
}
