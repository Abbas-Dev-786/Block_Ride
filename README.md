# 🚗 Decentralized Ride Sharing Platform

A decentralized ride-sharing platform that connects riders and drivers without the need for a middleman. Built during the BuildOn Hackathon by QuickNode to revolutionize transportation by utilizing blockchain for secure and trustless payments.

![MochiMochimochiGIF (2)](https://github.com/user-attachments/assets/facb2478-167a-42b3-985d-143b7ce1dbbc)

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Challenges](#challenges)
- [License](#license)

## 🌟 Features

- **Decentralized Payment**: Payments are processed securely via smart contracts.
- **Driver and Rider Matching**: Efficient matching system to connect drivers and riders.
- **Fare Calculation**: Automatic fare calculation based on distance.
- **Hybrid Model**: Combines decentralized technology with a centralized UX for best performance.

## 🏗 Architecture

```mermaid
sequenceDiagram
    participant R as Rider
    participant D as Driver
    participant UI as Frontend
    participant QF as QuickNode Functions
    participant QS as QuickNode Streams
    participant SC as Smart Contracts
    participant DB as Cache/Storage

    %% Ride Request Flow
    Note over R,SC: 1. Ride Request Flow
    R->>UI: Request Ride
    UI->>QF: Trigger ride request function
    QF->>DB: Store ride details
    QF->>SC: Create ride request
    SC-->>QS: Emit RideRequested event
    QS->>QF: Trigger driver matching function
    QF->>D: Notify nearby drivers

    %% Ride Acceptance Flow
    Note over D,SC: 2. Ride Acceptance Flow
    D->>UI: Accept ride
    UI->>QF: Process acceptance
    QF->>SC: Update ride status
    SC-->>QS: Emit RideAccepted event
    QS->>QF: Trigger ride start function
    QF->>R: Notify rider
    QF->>DB: Update ride status

    %% Ride Progress Flow
    Note over R,DB: 3. Ride Progress Flow
    D->>UI: Update location
    UI->>QF: Process location update
    QF->>DB: Store location
    QF->>R: Send real-time updates

    %% Ride Completion Flow
    Note over D,SC: 4. Ride Completion Flow
    D->>UI: Complete ride
    UI->>QF: Process completion
    QF->>SC: Trigger payment
    SC-->>QS: Emit PaymentComplete event
    QS->>QF: Trigger completion function
    QF->>DB: Update ride status
    QF->>R: Request rating
```

## 💻 Tech Stack

### Blockchain & Web3
- Ethereum Smart Contracts (Solidity)
- QuickNode RPC, Streams & Functions
- Hardhat Development Environment
- Wagmi for Web3 interactions

### Backend
- Supabase
- PostgreSQL Database
- QuickNode Add-ons
- JWT Authentication

### Frontend
- React.js
- Redux Toolkit
- TailwindCSS
- Wallet Connect
- Quicknode

## ✨ Features

### Smart Contract Features
- Secure escrow system for ride payments
- Platform fee integration
- Role-based access control

### QuickNode Integration
- **Streams**
  - Real-time ride status updates
  - Payment confirmation notifications
  - Driver location tracking
  
- **Functions**
  - Automated ride matching
  - Price calculation
  - Rating system
  
- **Add-ons**
  - Token balances tracking
  - NFT integration for loyalty programs
  - Transaction monitoring

### Application Features
- User authentication & profiles
- Real-time ride tracking
- In-app wallet integration
- Rating & review system

## 📝 Prerequisites

- Node.js >= 16.0.0
- PostgreSQL >= 14
- QuickNode Account
- MetaMask or Web3 Wallet
- Yarn or npm

## 📖 Challenges
- Integrating QuickNode's Streams and Functions for real-time data was challenging.
- Designing a seamless UX while maintaining decentralized principles required a hybrid model.

## 🛠 Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ride-sharing-dapp.git
cd ride-sharing-dapp
```

2. Install root dependencies:
```bash
yarn install
```

3. Install workspace dependencies:
```bash
yarn workspaces run install
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Built with ❤️ by Abbas Bhanpura wala
