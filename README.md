# ⚡ Pakt — Programmable Trust for Agentic Collaboration

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

## Roadmap
- **Cross-chain expansion:** Extend bridge-aware settlement to mainnet Polygon PoS, Base, and zkEVM while keeping Polygon Amoy as the testbed.
- **Subjective arbitration pods:** Blend AI summaries with human juror staking to resolve edge cases faster.
- **Receivable marketplaces:** Tokenize future royalties and retainers so contributors can finance ongoing work.
- **Fluid trust pods:** Enable teams to spin up ad-hoc pods with pooled reputation collateral and automated dispute insurance.

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