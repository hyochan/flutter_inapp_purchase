import type { SidebarsConfig } from "@docusaurus/plugin-content-docs";

const sidebars: SidebarsConfig = {
  docsSidebar: [
    "intro",
    {
      type: "category",
      label: "Getting Started",
      collapsed: false,
      items: [
        "getting-started/installation",
      ],
    },
    {
      type: "category",
      label: "Guides",
      items: [
        "guides/purchases",
        "guides/lifecycle",
        "guides/subscription-offers",
        "guides/subscription-validation",
        "guides/offer-code-redemption",
        "guides/alternative-billing",
        "guides/error-handling",
        "guides/troubleshooting",
        "guides/faq",
        "guides/support",
      ],
    },
    {
      type: "category",
      label: "Migration",
      items: [
        "migration/from-v6",
        "migration/from-v5",
      ],
    },
    {
      type: "category",
      label: "API Reference",
      link: {
        type: "doc",
        id: "api/index",
      },
      items: [
        "api/types",
        "api/core-methods",
        "api/listeners",
        "api/error-codes",
      ],
    },
    {
      type: "category",
      label: "Examples",
      items: [
        "examples/purchase-flow",
        "examples/subscription-flow",
        "examples/available-purchases",
        "examples/offer-code",
        "examples/alternative-billing",
      ],
    },
    {
      type: "doc",
      id: "sponsors",
      label: "Sponsors",
    },
  ],
};

export default sidebars;
