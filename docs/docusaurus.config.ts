import { themes as prismThemes } from "prism-react-renderer";
import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: "Flutter In-App Purchase",
  tagline: "A Flutter plugin for in-app purchases on iOS and Android",
  favicon: "img/favicon.ico",

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: "https://hyochan.github.io",
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: "/flutter_inapp_purchase/",

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: "hyochan", // Usually your GitHub org/user name.
  projectName: "flutter_inapp_purchase", // Usually your repo name.

  onBrokenLinks: "warn",
  onBrokenMarkdownLinks: "warn",

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  presets: [
    [
      "classic",
      {
        docs: {
          routeBasePath: "/",
          sidebarPath: "./sidebars.ts",
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            "https://github.com/hyochan/flutter_inapp_purchase/tree/main/docs/",
          versions: {
            current: {
              label: "8.2 (Current)",
              path: "",
            },
          },
          lastVersion: "current",
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ["rss", "atom"],
            xslt: true,
          },
          editUrl:
            "https://github.com/hyochan/flutter_inapp_purchase/tree/main/docs/",
          onInlineTags: "warn",
          onInlineAuthors: "warn",
          onUntruncatedBlogPosts: "warn",
        },
        theme: {
          customCss: "./src/css/custom.css",
        },
      } satisfies Preset.Options,
    ],
  ],

  themes: [
    [
      require.resolve("@easyops-cn/docusaurus-search-local"),
      {
        hashed: true,
        language: ["en"],
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
        indexDocs: true,
        indexBlog: true,
        indexPages: false,
        docsRouteBasePath: "/",
      },
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: "img/logo.png",
    navbar: {
      title: "flutter_inapp_purchase",
      logo: {
        alt: "flutter_inapp_purchase Logo",
        src: "img/logo.png",
      },
      items: [
        {
          type: "docsVersionDropdown",
          position: "left",
          dropdownActiveClassDisabled: true,
        },
        {
          type: "docSidebar",
          sidebarId: "docsSidebar",
          position: "left",
          label: "Docs",
        },
        {
          to: "/blog",
          label: "Blog",
          position: "left",
        },
        {
          href: "https://github.com/hyochan/flutter_inapp_purchase",
          label: "GitHub",
          position: "right",
        },
        {
          href: "https://pub.dev/packages/flutter_inapp_purchase",
          label: "Pub",
          position: "right",
        },
        {
          href: "https://x.com/hyochan",
          label: "X",
          position: "right",
        },
      ],
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Docs",
          items: [
            {
              label: "Getting Started",
              to: "/getting-started/installation",
            },
            {
              label: "API Reference",
              to: "/api/",
            },
          ],
        },
        {
          title: "Community",
          items: [
            {
              label: "Stack Overflow",
              href: "https://stackoverflow.com/questions/tagged/flutter-inapp-purchase",
            },
            {
              label: "GitHub Issues",
              href: "https://github.com/hyochan/flutter_inapp_purchase/issues",
            },
            {
              label: "Slack",
              href: "https://hyo.dev/joinSlack",
            },
          ],
        },
        {
          title: "More",
          items: [
            {
              label: "GitHub",
              href: "https://github.com/hyochan/flutter_inapp_purchase",
            },
            {
              label: "Pub.dev",
              href: "https://pub.dev/packages/flutter_inapp_purchase",
            },
          ],
        },
      ],
      copyright: `Copyright © 2025 hyochan.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ["dart", "kotlin", "swift"],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
