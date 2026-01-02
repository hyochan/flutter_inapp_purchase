---
sidebar_position: 11
title: AI Assistants
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# AI Assistants

<IapKitBanner />

flutter_inapp_purchase provides AI-optimized documentation files designed for AI coding assistants like Cursor, GitHub Copilot, Claude, and ChatGPT.

## AI-Optimized Documentation

| File | Description | Size |
|:-----|:------------|:-----|
| [llms.txt](https://hyochan.github.io/flutter_inapp_purchase/llms.txt) | Quick reference with core APIs, common patterns, and essential types | ~300 lines |
| [llms-full.txt](https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt) | Complete API documentation, all types, error codes, and implementation patterns | ~1000 lines |

## How to Use with AI Assistants

### Cursor

1. Open Cursor Settings (Cmd/Ctrl + ,)
2. Navigate to **Features** > **Docs**
3. Click **Add new doc**
4. Add: `https://hyochan.github.io/flutter_inapp_purchase/llms.txt`
5. For complete reference, also add: `https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt`

Now you can reference the docs in Cursor chat with `@flutter_inapp_purchase`.

### GitHub Copilot

Reference the documentation URL in your prompt:

```
Using the flutter_inapp_purchase package documented at
https://hyochan.github.io/flutter_inapp_purchase/llms.txt,
help me implement subscription purchases.
```

Or add to your `.github/copilot-instructions.md`:

```markdown
## flutter_inapp_purchase Reference
For in-app purchase implementation, refer to:
- Quick reference: https://hyochan.github.io/flutter_inapp_purchase/llms.txt
- Full API: https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt
```

### Claude / ChatGPT

Copy the content from the documentation files and paste it into your conversation, or reference the URLs directly:

**Quick Reference:**
```
Please read https://hyochan.github.io/flutter_inapp_purchase/llms.txt
and help me implement in-app purchases in my Flutter app.
```

**Full API Reference:**
```
Using the flutter_inapp_purchase documentation at
https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt,
show me how to handle subscription upgrades.
```

### Direct URL Access

You can access the documentation files directly:

- **Quick Reference:** https://hyochan.github.io/flutter_inapp_purchase/llms.txt
- **Full API Reference:** https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt

## What's Included

### llms.txt (Quick Reference)

- Project overview and installation
- Quick start guide
- Core API reference (connection, products, purchases)
- Key types (ProductQueryType, Purchase, PurchaseState, ErrorCode)
- Common usage patterns
- Error handling basics
- Platform requirements
- Essential links

### llms-full.txt (Complete Reference)

- Full installation and setup guide
- Complete API documentation with all parameters
- Detailed type definitions for all classes and enums
- Complete error code list with descriptions
- Platform-specific APIs (iOS and Android)
- Advanced implementation patterns
- Subscription management
- Alternative billing
- Purchase verification
- Troubleshooting guide

## Example Prompts

Here are some effective prompts to use with AI assistants:

### Getting Started

```
I'm new to flutter_inapp_purchase. Using the documentation at
https://hyochan.github.io/flutter_inapp_purchase/llms.txt,
help me set up basic in-app purchases in my Flutter app.
```

### Purchase Flow

```
Using flutter_inapp_purchase, implement a complete purchase flow
that handles success, errors, and pending transactions.
Reference: https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt
```

### Subscriptions

```
Help me implement subscription management using flutter_inapp_purchase,
including checking active subscriptions and handling renewals.
See: https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt
```

### Error Handling

```
Using the flutter_inapp_purchase error codes, implement comprehensive
error handling for purchase failures.
Docs: https://hyochan.github.io/flutter_inapp_purchase/llms.txt
```

### Platform-Specific Features

```
Show me how to use iOS-specific features like promotional offers
and code redemption with flutter_inapp_purchase.
Full API: https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt
```

### Alternative Billing

```
Implement Android alternative billing using flutter_inapp_purchase.
Reference: https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt
```

## Tips for Better Results

1. **Start with llms.txt** for quick questions and common tasks
2. **Use llms-full.txt** for detailed implementation or platform-specific features
3. **Be specific** about which platform (iOS/Android) you're targeting
4. **Mention OpenIAP** if you need spec-compliant implementations
5. **Reference error codes** by name for precise error handling help
6. **Include your Flutter/Dart version** for version-specific guidance

## Feedback

If you find issues with the AI documentation or have suggestions for improvement:

- **Open an Issue:** [GitHub Issues](https://github.com/hyochan/flutter_inapp_purchase/issues)
- **Start a Discussion:** [GitHub Discussions](https://github.com/hyochan/openiap.dev/discussions)

Your feedback helps us improve the AI-friendly documentation for everyone.
