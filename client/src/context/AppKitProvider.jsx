import PropTypes from "prop-types";
import { createWeb3Modal } from "@web3modal/wagmi/react";
import { defaultWagmiConfig } from "@web3modal/wagmi/react/config";

import { cookieStorage, createStorage, WagmiProvider } from "wagmi";
import { base, baseSepolia, mainnet, sepolia } from "wagmi/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { initWeb3InboxClient } from "@web3inbox/react";

// 0. Setup queryClient
const queryClient = new QueryClient();

// 1. Get projectId from https://cloud.walletconnect.com
const projectId = import.meta.env.VITE_APPKIT_PROJECT_ID;

// 2. Create wagmiConfig
const metadata = {
  name: "Duber",
  description: "A web3 uber clone",
  url: "https://amb-duber.vercel.app", // origin must match your domain & subdomain
  icons: ["https://avatars.githubusercontent.com/u/37784886"],
};

const chains = [baseSepolia, base];
const config = defaultWagmiConfig({
  chains,
  enableCoinbase: true,
  coinbasePreference: "all",
  projectId,
  metadata,
  storage: createStorage({ storage: cookieStorage }),
  auth: {
    email: true, // default to true
    socials: ["google", "x", "discord", "apple", "farcaster"],
    showWallets: false, // default to true
    walletFeatures: true, // default to true
  },
});

// 3. Create modal
createWeb3Modal({
  metadata,
  wagmiConfig: config,
  projectId,
  enableSwaps: true,
  enableOnramp: true,
  enableAnalytics: true, // Optional - defaults to your Cloud configuration
});

// W3Inbox Setup
const appDomain = import.meta.env.VITE_APPKIT_PROJECT_DOMAIN;
initWeb3InboxClient({
  projectId,
  domain: appDomain,
  allApps: true,
  logLevel: "info",
  // allApps: import.meta.env.MODE !== "production",
});

export default function AppKitProvider({ children }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  );
}

AppKitProvider.propTypes = {
  children: PropTypes.any,
};
