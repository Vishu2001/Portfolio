import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Build a self-contained server (.next/standalone/server.js) with only the files it
  // needs. The Docker image runs that instead of shipping all of node_modules.
  output: "standalone",
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
