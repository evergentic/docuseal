# Evergentic eSign: modified DocuSeal source

This is a modified copy of DocuSeal 3.3.5 (https://github.com/docusealco/docuseal), licensed under
AGPL-3.0 with the Section 7(b) additional term (see `LICENSE` and `LICENSE_ADDITIONAL_TERMS`).
Source for the running service at https://esign.evergentic.ai is this repository.

Changes (see `git diff 3.3.5`): product name "Evergentic eSign", Evergentic logo/favicons/colors,
mail sender default, and a source-code link. The original "Powered by DocuSeal" attribution is
kept in interactive pages and emails, as the additional term requires. No Pro (closed-source)
features are included or unlocked.

Copyright holders of the original work: DocuSeal LLC and contributors.

## 2026-11-21 hardening
- In-container Redis no longer persists to disk (`--save '' --appendonly no --dir /tmp`): persisting into WORKDIR failed with EACCES, after which Redis refused every write (MISCONF) and the mail/webhook job queue stopped. The queue is in-memory by design (no external Redis).
- `/esign-disclosure`: Evergentic's own electronic records and signature disclosure (ESIGN Act, Fla. Stat. 668.50); the signing form links to it instead of docuseal.com.
- `POST /api/templates/pdf`: create a template from a PDF with explicit roles and field areas (token-authenticated, same ability check as the web upload). Open-source code paths only; no Pro feature is included or unlocked.
