import type { SidebarsConfig } from "@docusaurus/plugin-content-docs";

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: "doc",
      id: "intro",
      label: "Introduction",
    },
    {
      type: "category",
      label: "Getting Started",
      items: [
        "getting-started/installation",
        "getting-started/ios-setup",
        {
          type: "category",
          label: "Android Setup",
          link: { type: "doc", id: "getting-started/android-setup" },
          items: ["getting-started/setup-horizon"],
        },
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
        "migration/from-v7",
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
      id: "guides/ai-assistants",
      label: "AI Assistants",
    },
    {
      type: "doc",
      id: "sponsors",
      label: "Sponsors",
    },
  ],
};

export default sidebars;
