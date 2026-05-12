# PalmAura App Store Review Checklist

## Positioning

- Category: Entertainment
- Secondary category: Lifestyle
- First app description lines:

```text
PalmAura offers symbolic palm readings for entertainment and self-reflection.
It is not medical, legal, financial, psychological, or life-critical advice.
```

## Risk scan commands

Run before submission:

```bash
rg -i "diagnos|disease|illness|fertility|pregnan|death|will die|lifespan" ios/ landing/ backend/
rg -i "guarantee|will become|destined to|fate is fixed|predict the future" ios/ landing/ backend/
rg -i "medical advice|legal advice|financial advice|psychological advice" ios/ landing/ backend/
```

Expected: matches only in guardrails/disclaimers explaining what PalmAura does not do.

## Privacy questionnaire target

- Device ID: collected for rate limiting / analytics if enabled
- Usage data: collected if analytics enabled
- Photos: not stored by PalmAura; transmitted to AI provider for real-time processing
- Tracking: no, unless ad/third-party tracking is later added

## Required screenshots

- Disclaimer
- Onboarding
- Photo capture
- Result screen
- Share card
