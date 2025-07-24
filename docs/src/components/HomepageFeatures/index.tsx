import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  emoji: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Easy to Use',
    emoji: '⚡',
    description: (
      <>
        flutter_inapp_purchase was designed from the ground up to be easily installed and 
        used to get your in-app purchases up and running quickly.
      </>
    ),
  },
  {
    title: 'Focus on What Matters',
    emoji: '💎',
    description: (
      <>
        flutter_inapp_purchase lets you focus on your app logic, and we'll handle the purchase flows. 
        Go ahead and implement your store with confidence.
      </>
    ),
  },
  {
    title: 'Cross-Platform',
    emoji: '📱',
    description: (
      <>
        Works seamlessly on both iOS and Android with unified APIs. 
        Write once, purchase everywhere with consistent behavior.
      </>
    ),
  },
  {
    title: 'Unified API Spec',
    emoji: '🔧',
    description: (
      <>
        99% API compatibility with <a href="https://github.com/hyochan/expo-iap" target="_blank" rel="noopener noreferrer">expo-iap</a> and other cross-platform solutions. 
        Easy migration and familiar patterns for developers.
      </>
    ),
  },
  {
    title: 'Modern & Reliable',
    emoji: '🛡️',
    description: (
      <>
        Built with the latest StoreKit 2 and Billing Client v8 APIs. 
        Battle-tested by thousands of apps in production.
      </>
    ),
  },
  {
    title: 'Open Source',
    emoji: '🌟',
    description: (
      <>
        Completely open source with active community support. 
        Join us in making in-app purchases better for everyone.
      </>
    ),
  },
];

function Feature({title, emoji, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <div className={styles.featureEmoji} role="img" aria-label={title}>
          {emoji}
        </div>
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
