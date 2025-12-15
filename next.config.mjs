/** @type {import('next').NextConfig} */
const nextConfig = {
    eslint: {
        ignoreDuringBuilds: true,
    },
    typescript: {
        ignoreBuildErrors: true,
    },
    webpack: (config, { isServer }) => {
        if (!isServer) {
            // Don't bundle these packages for client-side
            config.resolve.fallback = {
                ...config.resolve.fallback,
                electron: false,
                fs: false,
                net: false,
                tls: false,
            };
        }
        return config;
    },
};

export default nextConfig;
