import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/__docusaurus/debug',
    component: ComponentCreator('/__docusaurus/debug', '5ff'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/config',
    component: ComponentCreator('/__docusaurus/debug/config', '5ba'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/content',
    component: ComponentCreator('/__docusaurus/debug/content', 'a2b'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/globalData',
    component: ComponentCreator('/__docusaurus/debug/globalData', 'c3c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/metadata',
    component: ComponentCreator('/__docusaurus/debug/metadata', '156'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/registry',
    component: ComponentCreator('/__docusaurus/debug/registry', '88c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/routes',
    component: ComponentCreator('/__docusaurus/debug/routes', '000'),
    exact: true
  },
  {
    path: '/blog',
    component: ComponentCreator('/blog', '939'),
    exact: true
  },
  {
    path: '/blog/archive',
    component: ComponentCreator('/blog/archive', '182'),
    exact: true
  },
  {
    path: '/blog/authors',
    component: ComponentCreator('/blog/authors', '0b7'),
    exact: true
  },
  {
    path: '/blog/authors/hyochan',
    component: ComponentCreator('/blog/authors/hyochan', 'c05'),
    exact: true
  },
  {
    path: '/blog/flutter-iap-6.0.0-release',
    component: ComponentCreator('/blog/flutter-iap-6.0.0-release', '4c4'),
    exact: true
  },
  {
    path: '/blog/tags',
    component: ComponentCreator('/blog/tags', '287'),
    exact: true
  },
  {
    path: '/blog/tags/billing-client-v-8',
    component: ComponentCreator('/blog/tags/billing-client-v-8', '948'),
    exact: true
  },
  {
    path: '/blog/tags/flutter',
    component: ComponentCreator('/blog/tags/flutter', 'f35'),
    exact: true
  },
  {
    path: '/blog/tags/in-app-purchase',
    component: ComponentCreator('/blog/tags/in-app-purchase', '5d3'),
    exact: true
  },
  {
    path: '/blog/tags/release',
    component: ComponentCreator('/blog/tags/release', '6d5'),
    exact: true
  },
  {
    path: '/blog/tags/storekit-2',
    component: ComponentCreator('/blog/tags/storekit-2', '360'),
    exact: true
  },
  {
    path: '/markdown-page',
    component: ComponentCreator('/markdown-page', '3d7'),
    exact: true
  },
  {
    path: '/docs',
    component: ComponentCreator('/docs', 'c85'),
    routes: [
      {
        path: '/docs',
        component: ComponentCreator('/docs', '13c'),
        routes: [
          {
            path: '/docs',
            component: ComponentCreator('/docs', 'fa0'),
            routes: [
              {
                path: '/docs/api/',
                component: ComponentCreator('/docs/api/', 'b31'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/api/classes/flutter-inapp-purchase',
                component: ComponentCreator('/docs/api/classes/flutter-inapp-purchase', 'd87'),
                exact: true
              },
              {
                path: '/docs/api/classes/iap-item',
                component: ComponentCreator('/docs/api/classes/iap-item', 'fcd'),
                exact: true
              },
              {
                path: '/docs/api/classes/purchase-item',
                component: ComponentCreator('/docs/api/classes/purchase-item', 'c14'),
                exact: true
              },
              {
                path: '/docs/api/core-methods',
                component: ComponentCreator('/docs/api/core-methods', '493'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/api/error-codes',
                component: ComponentCreator('/docs/api/error-codes', '755'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/api/flutter-inapp-purchase',
                component: ComponentCreator('/docs/api/flutter-inapp-purchase', 'e25'),
                exact: true
              },
              {
                path: '/docs/api/listeners',
                component: ComponentCreator('/docs/api/listeners', '3a0'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/api/methods/finish-transaction',
                component: ComponentCreator('/docs/api/methods/finish-transaction', '951'),
                exact: true
              },
              {
                path: '/docs/api/methods/get-available-purchases',
                component: ComponentCreator('/docs/api/methods/get-available-purchases', '993'),
                exact: true
              },
              {
                path: '/docs/api/methods/get-products',
                component: ComponentCreator('/docs/api/methods/get-products', '05b'),
                exact: true
              },
              {
                path: '/docs/api/methods/init-connection',
                component: ComponentCreator('/docs/api/methods/init-connection', '155'),
                exact: true
              },
              {
                path: '/docs/api/methods/request-purchase',
                component: ComponentCreator('/docs/api/methods/request-purchase', '36d'),
                exact: true
              },
              {
                path: '/docs/api/methods/request-subscription',
                component: ComponentCreator('/docs/api/methods/request-subscription', '24b'),
                exact: true
              },
              {
                path: '/docs/api/methods/validate-receipt',
                component: ComponentCreator('/docs/api/methods/validate-receipt', '378'),
                exact: true
              },
              {
                path: '/docs/api/overview',
                component: ComponentCreator('/docs/api/overview', '5d7'),
                exact: true
              },
              {
                path: '/docs/api/types',
                component: ComponentCreator('/docs/api/types', '773'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/api/types/error-codes',
                component: ComponentCreator('/docs/api/types/error-codes', '47b'),
                exact: true
              },
              {
                path: '/docs/api/types/product-type',
                component: ComponentCreator('/docs/api/types/product-type', 'c29'),
                exact: true
              },
              {
                path: '/docs/api/types/purchase-state',
                component: ComponentCreator('/docs/api/types/purchase-state', 'c7c'),
                exact: true
              },
              {
                path: '/docs/api/use-iap',
                component: ComponentCreator('/docs/api/use-iap', 'c6e'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/examples/basic-store',
                component: ComponentCreator('/docs/examples/basic-store', 'b8a'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/examples/complete-implementation',
                component: ComponentCreator('/docs/examples/complete-implementation', 'fac'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/examples/subscription-store',
                component: ComponentCreator('/docs/examples/subscription-store', '612'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/faq',
                component: ComponentCreator('/docs/faq', '489'),
                exact: true
              },
              {
                path: '/docs/getting-started/android-setup',
                component: ComponentCreator('/docs/getting-started/android-setup', '8b2'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/getting-started/installation',
                component: ComponentCreator('/docs/getting-started/installation', 'f1f'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/getting-started/ios-setup',
                component: ComponentCreator('/docs/getting-started/ios-setup', 'cf8'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/getting-started/quickstart',
                component: ComponentCreator('/docs/getting-started/quickstart', '748'),
                exact: true
              },
              {
                path: '/docs/getting-started/setup-android',
                component: ComponentCreator('/docs/getting-started/setup-android', 'fa7'),
                exact: true
              },
              {
                path: '/docs/getting-started/setup-ios',
                component: ComponentCreator('/docs/getting-started/setup-ios', '2d1'),
                exact: true
              },
              {
                path: '/docs/guides/basic-setup',
                component: ComponentCreator('/docs/guides/basic-setup', 'bc8'),
                exact: true
              },
              {
                path: '/docs/guides/error-handling',
                component: ComponentCreator('/docs/guides/error-handling', 'de1'),
                exact: true
              },
              {
                path: '/docs/guides/faq',
                component: ComponentCreator('/docs/guides/faq', '113'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/guides/lifecycle',
                component: ComponentCreator('/docs/guides/lifecycle', '9fb'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/guides/offer-code-redemption',
                component: ComponentCreator('/docs/guides/offer-code-redemption', '0c3'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/guides/products',
                component: ComponentCreator('/docs/guides/products', '87e'),
                exact: true
              },
              {
                path: '/docs/guides/purchases',
                component: ComponentCreator('/docs/guides/purchases', 'f35'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/guides/receipt-validation',
                component: ComponentCreator('/docs/guides/receipt-validation', 'e5c'),
                exact: true
              },
              {
                path: '/docs/guides/subscriptions',
                component: ComponentCreator('/docs/guides/subscriptions', '70a'),
                exact: true
              },
              {
                path: '/docs/guides/testing',
                component: ComponentCreator('/docs/guides/testing', 'baa'),
                exact: true
              },
              {
                path: '/docs/guides/troubleshooting',
                component: ComponentCreator('/docs/guides/troubleshooting', 'b6c'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/intro',
                component: ComponentCreator('/docs/intro', '058'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/migration/from-expo-iap',
                component: ComponentCreator('/docs/migration/from-expo-iap', '3ae'),
                exact: true
              },
              {
                path: '/docs/migration/from-v5',
                component: ComponentCreator('/docs/migration/from-v5', 'e8d'),
                exact: true,
                sidebar: "docsSidebar"
              },
              {
                path: '/docs/troubleshooting',
                component: ComponentCreator('/docs/troubleshooting', '53f'),
                exact: true
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '/',
    component: ComponentCreator('/', 'e5f'),
    exact: true
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
