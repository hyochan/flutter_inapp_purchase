import React from "react";

interface IapKitBannerProps {
  style?: React.CSSProperties;
}

export default function IapKitBanner({ style }: IapKitBannerProps) {
  const handleClick = async () => {
    try {
      await fetch(
        "https://www.hyo.dev/api/ad-banner/cmjf0l1x30001249hbi91aop6",
        {
          method: "POST",
          mode: "no-cors",
        }
      );
    } catch (error) {
      // Silently ignore errors
    }
  };

  return (
    <div
      style={{
        marginTop: 24,
        marginBottom: 24,
        textAlign: "center",
        ...style,
      }}
    >
      <a
        href="https://iapkit.com"
        target="_blank"
        rel="noopener noreferrer"
        onClick={handleClick}
      >
        <img
          src={require("@site/static/img/iapkit-banner.gif").default}
          alt="IapKit - Fraud-proof your in-app purchases"
          style={{
            objectFit: "cover",
            border: "none",
          }}
        />
      </a>
    </div>
  );
}
