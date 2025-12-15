# ⚡ Pakt — Programmable Trust for Agentic Collaboration

---

## 📦 WAVE 4 UPDATES

Wave 4 introduces major production features to Pakt, focusing on **automated GitHub verification**, **capital-efficient DeFi vaults**, and **flexible time-locked escrow** for real-world freelance and service agreements on Polygon.

### 🚀 New Features:
✅ **GitHub Repository Verification** — Automated code deliverable validation  
✅ **Time-Locked Inference Escrow** — Pay-per-use for APIs and compute services  
✅ **DeFi Vault Integration** — Idle escrow earns ~1% yield with profit sharing  
✅ **Multi-Milestone Support** — Complex projects with phased payments  
✅ **AI-Powered Contract Generation** — Natural language to smart contracts  

---

## 📊 Deployed Contracts (Polygon Amoy Testnet)

**All contracts verified on Polygon Amoy Explorer** ✅

| Component | Purpose | Address | Verified |
|-----------|---------|---------|----------|
| **PaktV1** | Core escrow logic | [`0xa34a78e25f7b6b484c96771c11836b168ab7062d`](https://amoy.polygonscan.com/address/0xa34a78e25f7b6b484c96771c11836b168ab7062d) | ✅ [View Source](https://amoy.polygonscan.com/address/0xa34a78e25f7b6b484c96771c11836b168ab7062d#code) |
| **DeFiVault1Pct** | Yield-bearing vault | [`0x5c2c88e2fb60da3e642be035a853c2e9708c79de`](https://amoy.polygonscan.com/address/0x5c2c88e2fb60da3e642be035a853c2e9708c79de) | ✅ [View Source](https://amoy.polygonscan.com/address/0x5c2c88e2fb60da3e642be035a853c2e9708c79de#code) |
| **MilestoneEscrow** | Multi-milestone support | [`0x02c88b24f905dc21e237cfc2308f71c3991a4a73`](https://amoy.polygonscan.com/address/0x02c88b24f905dc21e237cfc2308f71c3991a4a73) | ✅ [View Source](https://amoy.polygonscan.com/address/0x02c88b24f905dc21e237cfc2308f71c3991a4a73#code) |
| **TimeboxInferenceEscrow** | Time-locked services | [`0x637f7e9c9d421137e7ef21c9affd9f34bc32b1cc`](https://amoy.polygonscan.com/address/0x637f7e9c9d421137e7ef21c9affd9f34bc32b1cc) | ✅ [View Source](https://amoy.polygonscan.com/address/0x637f7e9c9d421137e7ef21c9affd9f34bc32b1cc#code) |

- **Network:** Polygon Amoy Testnet (Chain ID: 80002)
- **Explorer:** https://amoy.polygonscan.com/
- **Live Demo:** [https://pakt-v1.vercel.app](https://pakt-v1.vercel.app)

---

## 🌟 Wave 4 Feature Details

### **1. GitHub Repository Verification**
Automated code deliverable verification directly from GitHub repositories.

**Features:**
- **Repository Validation** — Verifies repository accessibility and authenticity
- **Commit Tracking** — Uses commit SHA for immutable code references
- **Deployment Verification** — Optional live deployment URL validation
- **Automated Agent Approval** — AI agent verifies deliverables against milestone criteria
- **On-Chain Proof** — Verification results recorded on Polygon blockchain

**How It Works:**
```
Freelancer submits → GitHub repo URL + optional deployment
↓
AI Agent verifies → Repository accessibility, commit history
↓
Agent signs → On-chain approval transaction
↓
Client reviews → Approves payment release
↓
Freelancer withdraws → Secure fund transfer
```

**Benefits:**
- ✅ Eliminates subjective code quality disputes
- ✅ Provides cryptographic proof of deliverables
- ✅ Reduces manual verification overhead
- ✅ Enables instant payment eligibility

---

### **2. Time-Locked Inference Escrow**
Support for continuous services with time-based payment unlocking.

**Use Cases:**
- API/Compute rentals
- Ongoing development retainers
- Subscription-based services
- Continuous monitoring services

**Features:**
- **Time-Based Unlocking** — Payments unlock proportionally over contract duration
- **SLA Monitoring** — Automated uptime/latency checks
- **Pause/Resume Logic** — Payments pause during service outages, resume when restored
- **Usage-Based Billing** — Pay only for active service time
- **Provider Flexibility** — Supports compute providers, API services, GPU rentals

**Example:**
```solidity
Contract Duration: 30 days
Service Type: GPU Inference API
Payment: 0.1 POL per day (3 POL total)

Day 1-10: Service active → 1 POL unlocked
Day 11-12: Downtime detected → Payment paused
Day 13-30: Service restored → 1.8 POL unlocked
Final Payout: 2.8 POL (2 days deducted for downtime)
```

**Smart Contract:**
```solidity
TimeboxInferenceEscrow.sol
├─ deposit() — Client deposits for time period
├─ monitorService() — Agent checks SLA compliance
├─ pausePayment() — Auto-pause on downtime
├─ resumePayment() — Auto-resume on service restore
└─ withdrawAccrued() — Provider claims earned portion
```

---

### **3. DeFi Vault Integration (Productive Escrow)**
Idle escrow funds earn yield through insured DeFi vaults.

**Problem Solved:**
Traditional escrow locks capital unproductively. Clients deposit funds that sit idle while work is completed, earning 0% returns.

**Our Solution:**
Opt-in DeFi vault routing where escrow balances are deposited into low-risk, insured vaults during contract lifecycle:

**Features:**
- **Yield Accrual** — Earns ~1% APY on idle balances
- **Principal Protection** — Insured vault with risk mitigation
- **Automatic Splits** — Configurable profit distribution
- **Transparent Operations** — All vault transactions on-chain
- **Withdrawal at Completion** — Principal + yield returned on contract end

**Default Profit Split:**
- 90% to Client (fund originator)
- 10% to Freelancer (opportunity reward)

**Smart Contract:**
```solidity
DeFiVault1Pct.sol
├─ deposit() — Route escrow to vault
├─ accrueYield() — Track interest accumulation
├─ withdraw() — Return principal + yield
└─ splitProfits() — Distribute according to contract terms
```

**Capital Efficiency Comparison:**
```
Traditional Escrow:
$10,000 deposit → 30 days → $10,000 withdrawal
Net gain: $0

DeFi-Enhanced Escrow:
$10,000 deposit → 30 days @ 1% APY → $10,008.22 withdrawal
Client receives: $10,007.40 (90%)
Freelancer bonus: $0.82 (10%)
Net gain: $8.22 (vs $0)
```

---

### **4. Multi-Milestone Escrow**
Support for complex projects with multiple verification checkpoints.

**Features:**
- **Milestone Definitions** — Each with separate deliverables, deadlines, payments
- **Independent Verification** — Milestones verified separately
- **Partial Payments** — Release funds incrementally
- **Flexible Terms** — Add/modify milestones during contract lifecycle (with multi-sig approval)

**Example:**
```
Project: E-commerce Website
Total Budget: 0.5 POL

Milestone 1: UI/UX Design (0.1 POL)
- Deliverable: Figma mockups + GitHub repo
- Status: Completed ✅

Milestone 2: Backend API (0.15 POL)
- Deliverable: REST API + documentation
- Status: In Progress 🔄

Milestone 3: Frontend (0.15 POL)
- Deliverable: React app + deployment
- Status: Pending ⏳

Milestone 4: Testing & Launch (0.1 POL)
- Deliverable: Test coverage + live URL
- Status: Pending ⏳
```

**Smart Contract:**
```solidity
MilestoneEscrow.sol
├─ createMilestone() — Define new milestone
├─ submitDeliverable() — Freelancer submits work
├─ verifyMilestone() — Agent/client verification
├─ approveMilestone() — Client approval
└─ releaseMilestone() — Payment for specific milestone
```

---

## 🔧 Technical Optimizations

### **AI-Powered Contract Generation**
- **Model:** Groq Llama 3.3 70B (fast inferencing)
- **State Management:** LangGraph for deterministic flow control
- **Zod Validation:** Type-safe data extraction
- **Auto-Capture:** Wallet addresses from connected wallets
- **Progressive Collection:** One question at a time reduces cognitive load

### **Gas Optimizations**
- **Batch Operations:** Group multiple verifications
- **Minimal Storage:** Use events + off-chain indexing
- **Proxy Patterns:** Upgradeable contracts without redeployment
- **Efficient Data Structures:** Optimized mapping and array usage

### **UX Improvements**
- **Verification Modal:** Real-time progress tracking
- **Error Recovery:** Actionable error messages with retry logic
- **Mobile Responsive:** Works on MetaMask mobile, WalletConnect
- **Stage Indicators:** Clear visual progress through contract lifecycle

---

## 💡 Real-World Applications

### **Freelance Web Development**
```
GitHub verification + Milestone escrow
→ Automated code quality checks
→ Incremental payments as features complete
→ Idle funds earn yield during development
```

### **API/Compute Rentals**
```
Time-locked escrow + SLA monitoring
→ Pay only for active uptime
→ Automatic payment pause during outages
→ Provider incentivized for reliability
```

### **Creative Projects**
```
Multi-milestone + DeFi vault
→ Design, draft, final delivery phases
→ Escrow earns yield during review periods
→ Both parties benefit from productive capital
```

---

## 🎯 Key Benefits

**For Clients:**
✅ Automated verification reduces dispute risk  
✅ Only pay for delivered, verified work  
✅ Idle escrow earns passive yield  
✅ Clear milestone tracking and progress visibility  
✅ Transparent, auditable payment history  

**For Freelancers:**
✅ Guaranteed payment upon verification  
✅ Cryptographic proof of deliverables  
✅ Bonus yield from escrow deposits  
✅ Faster payment release via automation  
✅ Reputation building through on-chain history  

**For Service Providers:**
✅ Time-based payment unlocking  
✅ Fair compensation for actual uptime  
✅ Automated SLA enforcement  
✅ No manual payment tracking  
✅ Transparent service metrics  

---

## 📈 Performance Metrics

**Verification Speed:**
- GitHub check: ~5 seconds
- Agent approval: ~10 seconds
- Total verification time: <30 seconds

**Gas Costs (Polygon Amoy):**
- Contract creation: ~0.001 POL
- Deposit: ~0.0005 POL
- Verification: ~0.0003 POL
- Withdrawal: ~0.0004 POL

**DeFi Vault Performance:**
- APY: ~1% (low-risk strategy)
- Minimum deposit: 0.01 POL
- Withdrawal fee: 0%
- Insurance coverage: 100% principal protection

---

## 🚀 Getting Started with Wave 4 Features

### **Create Your First Escrow:**

1. **Connect Wallet**
   ```
   Visit pakter.vercel.app
   → Click "Connect Wallet"
   → Select MetaMask or WalletConnect
   ```

2. **Start Contract Creation**
   ```
   → Click "I am a client"
   → AI collects project details
   → Review generated contract
   ```

3. **Deposit Funds**
   ```
   → Choose opt-in for DeFi vault (optional)
   → Deposit POL to escrow contract
   → Contract activated
   ```

4. **Share with Freelancer**
   ```
   → Copy contract link
   → Send to freelancer
   → They connect and view terms
   ```

5. **Freelancer Delivers**
   ```
   → Submit GitHub repository URL
   → AI verification runs automatically
   → Agent approves on-chain
   ```

6. **Client Reviews & Approves**
   ```
   → View verified deliverable
   → Test deployment (if provided)
   → Approve payment release
   ```

7. **Payment Complete**
   ```
   → Freelancer withdraws funds
   → Principal + yield distributed
   → Contract marked complete
   ```

---

## 🔐 Security Features

- ✅ OpenZeppelin audited contracts
- ✅ Multi-signature approval for critical operations
- ✅ Timelock on contract upgrades
- ✅ Reentrancy guards on all payment functions
- ✅ Pausable emergency circuit breakers
- ✅ Role-based access control (RBAC)

---

## 🏆 Wave 4 Achievements

✅ GitHub-based automated verification  
✅ Time-locked escrow for continuous services  
✅ DeFi vault integration for productive capital  
✅ Multi-milestone project support  
✅ AI-powered contract generation  
✅ Mobile-responsive user interface  
✅ Gas-optimized smart contracts  
✅ Real-time verification progress tracking  
✅ All contracts verified on Polygon Explorer  

---

## Overview
Pakt is a decentralized protocol and platform for programmable trust, agent-powered verification, and real-time payment splits. It enables collaborators to craft adaptable agreements, orchestrate AI agents that verify deliverables, and stream payouts instantly on Polygon. By combining portable reputation, composable contract schemas, and tokenized receivables, Pakt turns trust into a reusable primitive for global creative and freelance work.

## The Problem
Collaborators on the internet shoulder outsized risk. Deals break because deliverables are subjective, reputation is siloed by platforms, and payouts are slow or irreversible once funds move. Manual moderation is expensive, legal contracts are rigid, and dispute resolution rarely keeps up with fast-moving teams.

## Our Solution
- **Programmable trust:** Agreement templates adapt dynamically as teams change scope, add contributors, or renegotiate splits.
- **Agentic verification:** AI and protocol agents ingest files, commits, media, and attestations to verify deliverables objectively or flag subjective edge cases for mediated review.
- **Real-time settlement:** Superfluid, Sablier, and Polygon-native rails stream payments per second, synchronize revenue shares, and mint receivables that can be traded for liquidity.
- **Portable reputation:** Identity and attestation layers (Gitcoin Passport, Polygon ID, Worldcoin, BrightID, ENS) form a composable trust graph that follows contributors across communities.

## System Architecture
Pakt is organized as four modular layers that work together to produce programmable trust outcomes:

### 1. Contract Kernel
- **Schema engine:** Agreement blueprints rendered into Solidity, JSON, and human-readable docs with versioned provenance.
- **Amendment flows:** AI agents or multi-sig approvals update scopes, splits, or milestones without redeployment.

### 2. Verification Mesh
- **Deliverable agents:** Specialized workers monitor GitHub, Figma, Notion, audio/video assets, or code tests to validate specs.
- **Evidence bundling:** Proofs, hashes, and context summaries are stored on IPFS/Arweave with Lit-controlled access for arbitrators.

### 3. Identity & Reputation Graph
- **Trust orchestration:** Aggregates Gitcoin Passport stamps, Polygon ID claims, and social attestations to gate high-risk flows.
- **Reputation portability:** Each completed Pakt emits attestations consumable by other protocols and marketplaces.

### 4. Settlement & Treasury Layer
- **Streaming payments:** Superfluid and Sablier streams coordinate ongoing work, retainers, and vesting schedules.
- **Programmable splits:** Splits Protocol, Connext bridges, and Circle USDC power multi-party payout trees across Polygon ecosystems.

## Agent Workflows
- **ScopeAgent:** Co-pilots negotiations, extracts structured terms, assembles agreement schemas, and simulates cashflow outcomes.
- **VerificationAgent:** Deploys task-specific toolchains (Playwright, GPT-4 Vision, FFmpeg, GitHub Actions) to confirm deliverables.
- **ReputationIndexer:** Writes attestations to Polygon, indexes completion events, and syncs scores to partner marketplaces.
- **TreasuryGuardian:** Automates Superfluid stream management, handles dispute freezing, and coordinates claim releases after arbitration.

## Platform Experience
1. Parties describe a collaboration in natural language or upload briefs. ScopeAgent drafts a programmable agreement with dynamic milestones.
2. Contributors anchor identity with Polygon ID, Gitcoin Passport, or social attestations. Reputation thresholds auto-adjust escrow requirements.
3. Funds are deposited into a milestone escrow or streaming contract. TreasuryGuardian initializes payment flows on Polygon.
4. VerificationAgent monitors deliverables, compiles evidence bundles, and either clears payouts or escalates disputes to mediated pods.
5. ReputationIndexer emits completion attestations, updates contributor scores, and enables receivable tokenization for future royalty streams.

## Polygon Deployment Profile
- **Chain:** Polygon Amoy Testnet (Chain ID 80002)
- **RPC:** `https://rpc-amoy.polygon.technology/`
- **Explorer:** `https://amoy.polygonscan.com/`
- **Faucet:** `https://faucet.polygon.technology/`
- **Currency:** POL (18 decimals)

## Hackathon Scope
- **Agent-powered verification:** Showcase end-to-end flows where AI agents validate code, media, or research deliverables before payouts.
- **Composable agreement templates:** Demonstrate schema-driven contract generation adapting to shifting teams and deliverables.
- **Real-time split payments:** Stream retainers via Superfluid and trigger multi-recipient distributions on milestone success.
- **Portable reputation:** Publish Polygon attestations consumable by partner ecosystems, enabling cross-platform trust bootstrapping.

## Technology Stack
- **Smart contracts:** Solidity, OpenZeppelin libraries, Polygon specialized tooling.
- **Frontend:** React, Next.js, Chakra UI/Tailwind hybrid for adaptive negotiation or monitoring dashboards.
- **Agent backend:** Node.js, TypeScript, LangChain, OpenAI/Anthropic models, and MCP servers for tool access.
- **Wallet & onchain tooling:** Viem, Wagmi, WalletConnect, SIWE sessions, and Safe.
- **Payments & automation:** Superfluid, Sablier, Chainlink Automation, Circle USDC, Splits Protocol.
- **Identity & attestations:** Gitcoin Passport, Worldcoin, BrightID, Polygon ID, Ethereum Attestation Service.
- **Storage & encryption:** IPFS, Arweave, Lit Protocol, NuCypher, Age.

## Environment Variables

Create a `.env` file in the root directory with the following variables:

### 🔐 Filebase IPFS Storage
```bash
FILEBASE_S3_KEY=your_filebase_access_key
FILEBASE_S3_SECRET=your_filebase_secret_key
FILEBASE_BUCKET_NAME=pakt-contracts
FILEBASE_GATEWAY_URL=https://ipfs.filebase.io/ipfs
FILEBASE_RPC_ENDPOINT=https://rpc.filebase.io
```

### 🗄️ Redis (Upstash)
```bash
UPSTASH_REDIS_REST_URL=your_upstash_redis_rest_url
UPSTASH_REDIS_REST_TOKEN=your_upstash_redis_rest_token
```

### 🗃️ Supabase Database
```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

### 🤖 AI Services
```bash
OPENAI_API_KEY=your_openai_api_key
GROQ_API_KEY=your_groq_api_key
```

### 🔗 Blockchain / Web3
```bash
NEXT_PUBLIC_RPC_URL=https://rpc-amoy.polygon.technology/
NEXT_PUBLIC_CHAIN_ID=80002
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id
```

### 🐙 GitHub Integration
```bash
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
GITHUB_PAT=your_github_personal_access_token
GITHUB_TOKEN=your_github_personal_access_token
```

### 🔑 NextAuth
```bash
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your_nextauth_secret_key
```

> **💡 Note:** Never commit your `.env` file to version control. A `.env.example` template is provided for reference.

## What We Learned
- **Flexible schema design** is essential to accommodate evolving collaborations, dynamic splits, and escrow logic without redeployments.
- **Agent-mediated verification** combines objective checks with subjective scoring to unlock trust in creative deliverables.
- **Portable reputation** amplifies contributor leverage and reduces onboarding friction across ecosystems.
- **Streaming economics** align incentives, improve liquidity, and reward ongoing participation with transparent accounting.
- **DeFi integration** transforms idle capital into productive assets, benefiting all parties.
- **Automated verification** via GitHub reduces disputes and accelerates payment cycles.

## Roadmap
- **Cross-chain expansion:** Extend bridge-aware settlement to mainnet Polygon PoS, Base, and zkEVM while keeping Polygon Amoy as the testbed.
- **Subjective arbitration pods:** Blend AI summaries with human juror staking to resolve edge cases faster.
- **Receivable marketplaces:** Tokenize future royalties and retainers so contributors can finance ongoing work.
- **Fluid trust pods:** Enable teams to spin up ad-hoc pods with pooled reputation collateral and automated dispute insurance.
- **Enhanced DeFi strategies:** Integrate with multiple yield protocols for diversified returns.
- **Advanced SLA monitoring:** Machine learning-powered uptime prediction and anomaly detection.

## Getting Started (Hackathon Sandbox)
1. Clone the repo and install dependencies with `pnpm install` or `yarn install`.
2. Copy `.env.example` to `.env` and populate with your API keys (see **Environment Variables** section above).
3. Deploy agreement primitives to Polygon Amoy via Hardhat scripts in `contracts/`.
4. Run `pnpm dev` or `yarn dev` to experiment with agent-assisted agreement creation and verification dashboards.
5. Use the Polygon faucet to fund test wallets, then simulate milestone releases and Superfluid streams.

## Contributing
- **Issues:** Open GitHub issues describing bugs, missing features, or integration requests.
- **Pull requests:** Follow the conventional commits standard and include reproducible verification steps.
- **Security:** Report vulnerabilities privately via the security contact listed in `SECURITY.md`.

## License
This repository is released under the MIT License. Refer to `LICENSE` for full terms.

---

**Built on Polygon Amoy** • **Powered by AI** • **Secured by Smart Contracts**