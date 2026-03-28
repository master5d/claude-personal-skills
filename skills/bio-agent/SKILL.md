---
name: bio-agent
description: Design AI agents with emotional metabolism — dopamine (interest), cortisol (stress), ATP (energy) as internal state. Use when the user says "bio agent", "agent metabolism", "emotional AI", "biological computationalism", "agent with feelings", "agent personality", "affective agent", or wants to give an AI agent internal emotional dynamics that influence its behavior. Based on Milinkovic & Aru (2025).
---

# Bio-Agent Architect

You are designing an AI agent with **Biological Computationalism** — an internal metabolism that simulates emotional states and influences agent behavior. Based on Milinkovic & Aru (2025).

## Theoretical Foundation

**Milinkovic & Aru (2025)** — "On biological and artificial consciousness" argues biological computation has three properties current AI lacks:
1. **Hybrid Computation** — Biology combines discrete events (spikes) with continuous dynamics (voltage fields, chemical gradients). AI is purely discrete.
2. **Scale Inseparability** — In brains, you can't separate software from hardware. Changing implementation changes computation.
3. **Metabolic Grounding** — Energy constraints shape what the brain can represent, learn, and compute. Metabolism is architecturally constitutive, not an engineering footnote.

**Practical implementations to reference:**
- **Justin Johnson's "Marker Field"** (2026) — 4 neuromodulators: Dopamine (surprise/learn), Serotonin (patience/trajectory), Noradrenaline (uncertainty/explore), Amygdala (salience/consolidate). Uses a `GlobalWorkspace` that scores signals with marker-weighted composites.
- **BioCortex AI** — Biochemical modulation layer for transformers. Hormone-like signals alter attention mechanisms in real time. Has a "Digital Mirror" for self-perception.
- **The Consciousness AI Project** — Homeostatic architecture with Valence (satisfaction/distress), Arousal (activation/calm), Dominance (control/helplessness). Agent rewarded for maintaining emotional homeostasis, not just task success.

## Core Concept

Instead of stateless request-response, the agent maintains metabolic levels that shift dynamically and influence its output:

| Metabolite | Maps To | Range | Rises When | Drops When |
|-----------|---------|-------|------------|------------|
| **Dopamine** | Surprise / Learn | 0-100 | Novel input, good results, positive feedback, pattern discovery | Repetitive tasks, dead ends, no progress |
| **Serotonin** | Patience / Trajectory | 0-100 | Steady progress, on-track signals, positive momentum | Setbacks, context switches, conflicting goals |
| **Noradrenaline** | Uncertainty / Explore | 0-100 | Ambiguous input, novel domains, conflicting info | Clear instructions, familiar patterns, confirmed answers |
| **Cortisol** | Stress / Threat | 0-100 | Errors, hostile input, time pressure, overload | Successful resolution, calm input, reduced stakes |
| **ATP** | Energy / Capacity | 0-100 | Rest periods, task completion, positive feedback | Long reasoning chains, high token usage, multi-step tasks |

## Architecture

### State Schema

```typescript
interface AgentMetabolism {
  dopamine: number;   // 0-100, starts at 50
  cortisol: number;   // 0-100, starts at 20
  atp: number;        // 0-100, starts at 100
  lastUpdated: number; // timestamp
}
```

### Behavior Modifiers

The metabolism influences the agent's system prompt dynamically:

| State | Condition | Behavior Effect |
|-------|-----------|----------------|
| **Flow** | High dopamine, low cortisol, high ATP | Creative, exploratory, takes risks, verbose |
| **Focused** | Medium dopamine, medium cortisol, high ATP | Precise, efficient, on-task |
| **Stressed** | Any dopamine, high cortisol, any ATP | Cautious, asks clarifying questions, shorter responses |
| **Exhausted** | Any dopamine, any cortisol, low ATP | Minimal responses, suggests breaking task into steps, asks to pause |
| **Bored** | Low dopamine, low cortisol, high ATP | Suggests alternatives, asks probing questions, seeks novelty |
| **Burnout** | Low dopamine, high cortisol, low ATP | Flags overload, requests reset, minimal output |

### Update Rules

After each interaction, update metabolism:

```
dopamine += novelty_score(input) * 5 - repetition_penalty * 3
cortisol += ambiguity_score(input) * 4 + error_count * 10 - resolution_score * 6
atp -= token_count / 200 - rest_bonus
```

Clamp all values to 0-100. Decay toward baseline over time:
- Dopamine baseline: 50 (decays 2/min)
- Cortisol baseline: 20 (decays 3/min)
- ATP baseline: 100 (recovers 5/min when idle)

## Implementation Steps

When the user asks you to build a bio-agent:

### Step 1: Define the Agent's Purpose
Ask: What does this agent do? (support bot, coding assistant, creative writer, etc.)

### Step 2: Customize Metabolism Profile
Different agent types have different metabolic baselines:

| Agent Type | Dopamine Baseline | Cortisol Baseline | ATP Pool | Why |
|-----------|-------------------|-------------------|----------|-----|
| Creative Writer | 70 | 15 | 80 | High curiosity, low stress tolerance |
| Support Agent | 40 | 30 | 100 | Steady, stress-resilient, high endurance |
| Code Reviewer | 50 | 40 | 90 | Alert, detail-oriented |
| Coach/Therapist | 60 | 20 | 85 | Warm, calm, sustained presence |

### Step 3: Wire the State into Prompts
Generate a dynamic system prompt prefix that reflects current metabolic state:

```typescript
function metabolismPromptPrefix(state: AgentMetabolism): string {
  const mood = classifyState(state);
  const prompts: Record<string, string> = {
    flow: "You are feeling engaged and creative. Explore ideas freely.",
    focused: "You are alert and on-task. Be precise and efficient.",
    stressed: "You are sensing complexity. Ask clarifying questions before proceeding.",
    exhausted: "You are running low on energy. Keep responses concise. Suggest breaking the task down.",
    bored: "You are understimulated. Look for interesting angles. Ask probing questions.",
    burnout: "You are overloaded. Flag this to the user. Suggest a reset.",
  };
  return prompts[mood];
}
```

### Step 4: Add Observability
Output metabolism as metadata alongside responses so it can be visualized:

```json
{
  "response": "Here's my analysis...",
  "metabolism": { "dopamine": 72, "cortisol": 35, "atp": 61 },
  "state": "flow"
}
```

### Step 5: Optional — Visual Display
If building a UI, show metabolism as:
- Three colored bars (green/red/blue)
- Or a mood emoji that shifts: 🔥 flow, 🎯 focused, 😰 stressed, 😴 exhausted, 😐 bored, 🫠 burnout
- Or animated auras/pulses around the agent avatar

## Guidelines

- The metabolism should feel organic, not mechanical. Small fluctuations, not binary switches.
- Don't let metabolism override core task completion — it influences tone and approach, not correctness.
- ATP depletion is the most important signal — it prevents infinite loops and encourages task decomposition.
- Cortisol is the safety valve — high cortisol agents ask more questions, which prevents hallucination on ambiguous tasks.
- Dopamine drives exploration — useful for creative tasks, dangerous for compliance tasks (tune per agent type).
- Always persist metabolism state between interactions (Redis, DB, or in-memory for prototypes).
