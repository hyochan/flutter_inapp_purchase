import type { ReactNode } from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Heading from "@theme/Heading";

import styles from "./index.module.css";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  const logoUrl = useBaseUrl("/img/logo.png");
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <div className={styles.heroContent}>
          <div className={styles.heroText}>
            <Heading as="h1" className="hero__title">
              {siteConfig.title}
            </Heading>
            <p className={styles.heroSubtitle}>{siteConfig.tagline}</p>
            <div className={styles.buttons}>
              <Link
                className="button button--primary button--lg"
                to="/docs/intro"
              >
                Get Started - 5min ⏱️
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs/getting-started/installation"
              >
                Installation Guide
              </Link>
            </div>
            <p className={styles.heroSponsor}>
              <strong>Our Sponsors</strong>
              <br />
              Flutter In-App Purchase is part of the{" "}
              <Link to="https://www.openiap.dev/">OpenIAP ecosystem</Link>{" "}
              standardizing in-app purchases across platforms, OS, and
              frameworks. If these libraries power your products, please
              consider sponsoring ongoing development via{" "}
              <Link to="https://www.openiap.dev/sponsors">
                openiap.dev/sponsors
              </Link>
              .
            </p>
          </div>
          <div className={styles.heroImageWrapper}>
            <div className={styles.heroImageSpacer} />
            <div className={styles.heroImageColumn}>
              <img
                src={logoUrl}
                alt="flutter_inapp_purchase Logo"
                className={styles.heroImg}
              />
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title}`}
      description="Description will go into a meta tag in <head />"
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
