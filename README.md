# AgentLeash 🐕‍🦺

**A wallet for AI agents that can't be talked into misbehaving.**

AI agents that hold money are one prompt injection away from losing it. AgentLeash puts the rules on-chain: spend limits, a recipient allowlist, expiry and a kill switch. The AI can't override them, because Arbitrum enforces them, not the model.

## Live on Arbitrum Sepolia
- AgentLeash: `0x313856e11c3dd317c19c9FF8B95623c05Bf673d6`
- TestUSDC: `0x98B2feAf9ee9FAbA8f1812c3001e343679A73928`

## Demo page
1. Legitimate $3 payment to an approved API: succeeds
2. Prompt-injected attempt to send funds to an attacker: blocked
3. $9 overspend: blocked, with a plain-English reason

## How it works
- `AgentLeash.sol`: per-payment limit, rolling daily limit, recipient allowlist, expiry, owner kill switch
- Custom revert errors double as human-readable explanations in the UI
- 8 Foundry tests cover the attack, limits, expiry, pause and access control

## Run it
~~~
forge test -vv
python3 -m http.server 8000
~~~
Then open http://localhost:8000/demo.html

## Roadmap
- Plain-English rules compiled to on-chain policy
- Robinhood Chain support
- Multi-agent budgets and spend analytics
