import React from "react";
import { IAPKIT_URL, TRACKING_URL } from "../constants";

interface IapKitBannerProps {
  style?: React.CSSProperties;
}

export default function IapKitBanner({ style }: IapKitBannerProps) {
  const handleClick = async () => {
    try {
      await fetch(TRACKING_URL, {
        method: "POST",
        mode: "no-cors",
      });
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
        href={IAPKIT_URL}
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
