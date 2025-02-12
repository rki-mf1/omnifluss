# Architectural Decision Record
The goal of an Architectural Decision Record (ADR) is to document an individual decision that has led to the current software architecture.
ADRs record architectural decisions in
- plain markdown text files
- its own file per dision
- consecutively indexed record files, pathogen abbreviation, and a self-contained short title (e.g. `004_HIV_variantCaller.md`)
- files as part of the source code repository, thus being subject to version control

> [!IMPORTANT]
> We add ADRs via Pull Requests and store them at `<PROJECT_DIR>/docs/adr/<ID>_<pathogen>_<title>.md`

An ADR is also a platform to discuss and record ongoing architectural decision-making if required.
Please use the **template below** for your ADR content and PR

```
## Title
Brief description of the decision.

## Context
Description of the context in which the decision was made, including technological, political, or social conditions.
The wording is neutral and describes the factual circumstances.

## Decision
Describes the decision made in the previously outlined context.
The wording is active and describes what will be done: “We will…”.

## Status
- [ ] proposed
- [ ] accepted
- [ ] deprecated
- [ ] superseded (via ADR#)

## Consequences
Describes the resulting state after the decision. Both positive and negative consequences are listed.
```
