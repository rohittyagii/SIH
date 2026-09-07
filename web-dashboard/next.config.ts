import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/proxy/:path*",
        destination: `${process.env.NEXT_PUBLIC_API_URL || "https://sainiksaathi-api.onrender.com"}/:path*`,
      },
    ];
  },
};

export default nextConfig;
