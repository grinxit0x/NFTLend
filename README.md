# NFTLoan Smart Contract

The NFTLoan smart contract allows users to create, fund, and manage loans backed by NFTs. Borrowers can provide NFTs as collateral, and lenders can fund these loans with the potential of earning interest. The contract includes functionalities for creating loans, extending loan durations, and managing collateral.

## Features

- **Loan Creation:** Borrowers can create loans specifying the loan amount and maximum number of lenders.
- **Collateral Management:** Borrowers can provide NFTs as collateral for their loans.
- **Loan Funding:** Lenders can fund loans and earn interest on their contributions.
- **Loan Repayment:** Borrowers can repay loans along with interest.
- **Loan Extension:** Borrowers can extend the duration of their loans with an increased interest rate.
- **Collateral Seizure:** Lenders can seize collateral if the loan is not repaid on time.
- **Withdraw Funds Before Loan is Filled:** Lenders can withdraw their funds before the loan is filled.
- **Interest Calculation:** The contract calculates interest using an exponential growth model, with an option for steeper growth when extending the loan duration.

## Contract Structure

### Variables and Structures

- `address public goon`: Contract owner.
- `uint256 public creationFee`: Fee for creating a loan.
- `uint256 public minInterestRate`: Minimum interest rate for loans.
- `uint256 public maxInterestRate`: Maximum interest rate for loans.
- `uint256 public baseExtendFee`: Base fee for extending the loan duration.
- `uint256 public maxLoanExtensionDuration`: Maximum loan extension duration (default 2 years).

### Structs

- `struct Lender`: Stores lender details.
- `struct Collateral`: Stores NFT collateral details.
- `struct Loan`: Stores loan details.

### Events

- `BaseExtendFeeSet`: Emitted when the base extend fee is set.
- `CollateralReturned`: Emitted when collateral is returned to the borrower.
- `CollateralSeized`: Emitted when collateral is seized.
- `FeeSet`: Emitted when the creation fee is set.
- `FundsWithdrawn`: Emitted when funds are withdrawn from the contract.
- `LoanCreated`: Emitted when a loan is created.
- `LoanDurationSet`: Emitted when the loan duration is set.
- `LoanExtended`: Emitted when a loan duration is extended.
- `LoanFilled`: Emitted when a loan is filled.
- `LoanMaxExtensionDurationSet`: Emitted when the maximum loan extension duration is set.
- `LoanRepaid`: Emitted when a loan is repaid.
- `MaxInterestRateSet`: Emitted when the maximum interest rate is set.
- `MaxLendersSet`: Emitted when the maximum number of lenders is set.
- `MaxLoansExtensionDurationSet`: Emitted when the maximum loan extension duration is set for all loans.
- `MinInterestRateSet`: Emitted when the minimum interest rate is set.

### Modifiers

- `onlyGoon`: Restricts access to the contract owner.
- `onlyBorrower`: Restricts access to the borrower of a loan.
- `onlyLenders`: Restricts access to the lenders of a loan.

### Functions

1. **Administrative Functions**
   - `constructor`
   - `setFee`
   - `setBaseExtendFee`
   - `setMaxLoansExtensionDuration`
   - `setLoanMaxExtensionDuration`
   - `withdrawFunds`
   - `setLoanDuration`
   - `setMaxLenders`
   - `setMinInterestRate`
   - `setMaxInterestRate`
   - `setPriceFeed`

2. **Main Loan Functions**
   - `createLoan`
   - `provideCollateral`
   - `fundLoan`
   - `repayLoan`
   - `extendLoanDuration`

3. **Collateral Management**
   - `seizeCollateral`
   - `cancelLoan`

4. **Lender Management**
   - `withdrawFundsBeforeLoanFilled`

5. **Utility Functions**
   - `findLenderIndex`
   - `getCollateralCount`
   - `getLenderCount`
   - `calculateInterestRate`
   - `calculateExtendFee`
   - `exp`

## Interest Calculation

The interest rate is calculated based on the elapsed time using an exponential growth model. When extending the loan duration, the interest rate grows more steeply to incentivize timely repayments.

```solidity
function calculateInterestRate(
    uint256 loanId,
    uint256 additionalTime,
    bool isExtension
) internal view returns (uint256) {
    Loan storage loan = loans[loanId];
    uint256 elapsedTime = block.timestamp - (loan.loanEndTime - loan.loanDuration);
    uint256 duration = isExtension ? loan.loanDuration + additionalTime : loan.loanDuration;

    if (elapsedTime >= duration) {
        return maxInterestRate + (isExtension ? 2 : 0);
    }

    uint256 adjustmentFactor = isExtension ? 2e18 : 1.5e18;
    uint256 elapsedRatio = (elapsedTime * 1e18) / duration;
    uint256 exponentialGrowth = exp((elapsedRatio * adjustmentFactor) / 1e18);

    uint256 interestRate = minInterestRate +
        (((maxInterestRate + (isExtension ? 2 : 0)) - minInterestRate) * (exponentialGrowth - 1)) /
        (exp(adjustmentFactor) - 1);
    return interestRate;
}

function exp(uint256 x) internal pure returns (uint256) {
    uint256 sum = 1e18;
    uint256 term = 1e18;

    for (uint256 i = 1; i < 10; i++) {
        term = (term * x) / (i * 1e18);
        sum += term;
    }

    return sum;
}
```

## constructor def values (for testing purposes)

uint256 _defaultLoanDuration = 30 * 24 * 60 * 60; // 30 days in seconds, 2592000 seconds
uint256 _minInterestRate = 5; // 5%
uint256 _maxInterestRate = 20; // 20%
uint256 _creationFee = 10000000000000000; // 0.01 ETH in wei
uint256 _baseExtendFee = 5000000000000000; // 0.005 ETH in wei

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

This README should provide a comprehensive overview of your `NFTLoan` contract, including its features, contract structure, and detailed descriptions of each function and variable.