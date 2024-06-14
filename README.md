# NFTLoan Smart Contract

NFTLoan is a Solidity smart contract that allows users to take out loans backed by NFTs. The contract enables the creation of loans, the provision of collateral, the funding of loans by lenders, the repayment of loans, and the extension of loan durations.

## Features

- **Loan Creation**: Users can create new loans by specifying the amount and maximum number of lenders.
- **Collateral Provision**: Borrowers can provide NFTs as collateral for the loans.
- **Loan Funding**: Lenders can fund loans and earn interest on their funds.
- **Loan Repayment**: Borrowers can repay loans along with the calculated interest.
- **Loan Extension**: Borrowers can extend the loan duration by paying an additional fee.

## Events

- `LoanCreated`: Emitted when a new loan is created.
- `LoanFilled`: Emitted when a loan is fully funded.
- `LoanRepaid`: Emitted when a loan is repaid.
- `CollateralSeized`: Emitted when collateral is seized for non-repayment.
- `CollateralReturned`: Emitted when collateral is returned to the borrower.
- `LoanExtended`: Emitted when the loan duration is extended.

## Structures

- **Lender**: Stores lender details.
- **Collateral**: Stores NFT collateral details.
- **Loan**: Stores loan details.

## Main Functions

### Loan Creation and Management

- `createLoan`: Creates a new loan.
- `provideCollateral`: Provides collateral for a loan.
- `fundLoan`: Funds a loan.
- `repayLoan`: Repays a loan.
- `extendLoanDuration`: Extends the loan duration.

### Collateral Management

- `seizeCollateral`: Seizes collateral if the loan is not repaid on time.
- `reclaimCollateral`: Reclaims collateral if the loan is not funded.
- `cancelLoan`: Cancels an unfunded loan.

### Utilities

- `getCollateralCount`: Gets the number of collaterals for a loan.
- `getLenderCount`: Gets the number of lenders for a loan.
- `calculateInterestRate`: Calculates the interest rate based on elapsed time using exponential growth.
- `exp`: Calculates the exponential of a number (e^x).

## Interest Rate Curve

The interest rate for the loans is calculated using an exponential growth model. The interest rate increases over time, creating a steeper curve as the loan duration progresses. This ensures that loans are repaid in a timely manner, with increasing penalties for delays. 

### Key Points:

- **Exponential Growth**: The interest rate grows exponentially with time, meaning the longer the duration, the higher the interest.
- **Extension Penalty**: Extending a loan duration incurs an additional interest rate penalty, making the curve even steeper.
- **Calculation**: The `calculateInterestRate` function uses a higher adjustment factor for extensions, reflecting a sharper increase in interest.

## Deployment

To deploy this contract, use your preferred tool (such as Remix, Hardhat, or Truffle) and ensure you have the Solidity compiler version ^0.8.26 installed.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
