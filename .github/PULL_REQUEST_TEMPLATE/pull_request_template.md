---
name: PR checklist for feature dev
about: Use this template to generate a checklist to comply with PR etiquette
title: "[PR Checklist] "
labels: enhancement
assignees: ''

---

## Describe the feature, fix or addition you are working on
_\<General info here...\>_
_\<Have you introduced new nf-core modules? ...\>_
_\<Have you added a test/ stub command? ...\>_

---
- [ ] [**Minimalism**] Every PR to dev should be a minimal functional upgrade, i.e. a PR should not contain more than the functionally required code for one particular addition or fix.
- [ ] [**Review**] PRs should always be reviewed by at least one project maintainer. Never force push to main branch!
- [ ] [**Reproducibility**] PRs need to provide a command/description to reproduce their functionality. Ideally, they also provide evidence that they are functional (e.g. screenshots, log, ...)
- [ ] [**Contribution**] Tag corresponding issues in the PR if relevant. Leave a short and precise comment in the CHANGELOG.md about your changes.
- [ ] [**Cleaning**] Delete the PR-branch if no longer required.
