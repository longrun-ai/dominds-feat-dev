# Dominds Feature Development

This project serves as an outer rtws (runtime workspace) of Dominds, used to drive feature PR style development of it

## Getting Started

To clone this repository along with its submodule (`dominds`) tracking the latest `main` branch:

```bash
git clone --recurse-submodules --remote-submodules https://github.com/longrun-ai/dominds-feat-dev.git
```

### Submodule Tracking

The `dominds` submodule is configured in `.gitmodules` to track the `main` branch:

- **Clone/Init**: Using `--remote-submodules` during clone or `git submodule update --init --remote` ensures you get the latest commit from the submodule's `main` branch.
- **Update**: To pull the latest changes from the submodule's remote branch at any time:
  ```bash
  git submodule update --remote dominds
  ```
- **Development**: The submodule is set with `update = merge`, which facilitates merging remote changes while you are developing within the submodule directory.
