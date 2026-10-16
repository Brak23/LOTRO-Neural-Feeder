# LOTRO prototype changelog

## 0.1.0

- Added read-only environment and executable preflight with PE architecture, hash, OS/GPU inventory, and labeled renderer configuration hint.
- Added conservative disabled configuration templates and documentation of current capabilities and pending evidence.
- Added offline ZIP packaging, per-file SHA-256 verification, diagnostic log collection, and preview-first restoration for future package-owned files.
- Pinned official build dependencies and added offline script checks to branch CI while retaining upstream build targets.
- No LOTRO rendering hook, shader replacement, game installation, neural consumer, or NVIDIA runtime was added.
