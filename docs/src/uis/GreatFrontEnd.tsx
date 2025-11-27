import React from "react";

interface GreatFrontEndProps {
  link?: string;
  title?: string;
  style?: React.CSSProperties;
}

export default function GreatFrontEnd({
  link = "https://www.greatfrontend.com?fpr=hyo73",
  title,
  style,
}: GreatFrontEndProps) {
  return (
    <div
      style={{
        marginTop: 24,
        marginBottom: 24,
        textAlign: "center",
        ...style,
      }}
    >
      <a href={link} target="_blank" rel="noopener noreferrer">
        <img
          src={require("@site/static/img/greatfrontend-js.gif").default}
          alt="GreatFrontEnd"
          style={{
            maxWidth: "100%",
            height: "auto",
            border: "none",
          }}
        />
      </a>
      {title && (
        <a
          href={link}
          target="_blank"
          rel="noopener noreferrer"
          style={{
            display: "block",
            fontSize: "0.85rem",
            color: "var(--ifm-color-emphasis-600)",
            textDecoration: "none",
            transition: "color 0.2s",
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.color = "var(--ifm-color-primary)";
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.color = "var(--ifm-color-emphasis-600)";
          }}
        >
          {title}
        </a>
      )}
    </div>
  );
}
