
# python-template

Template for python projects
Mainly based on [goodresearch ](https://goodresearch.dev).

## Usage
Run the setup script once when creating a new repository from this template:

```
./setup.sh [PACKAGE_NAME]
```

The script initialises the repository for your project. It renames the template package directory, updates the package name in `setup.py`, `pyproject.toml`, and `pixi.toml`, and can remove itself before creating the first git commit.

During setup it asks for the Pixi environment choices:

- Python version, defaulting to `3.11`
- Pixi platforms, defaulting to `linux-64`
- Whether to install PyTorch
- Whether PyTorch should use CUDA/GPU in the default environment, defaulting to yes when PyTorch is selected
- CUDA version, defaulting to `12.0`
- Whether to run `pixi install`
- Whether to create the initial git commit

If you choose PyTorch with GPU support, the generated `pixi.toml` keeps CUDA/PyTorch in the default environment. If you choose CPU PyTorch or no PyTorch, the CUDA dependencies and system requirements are left out.

## Project structure

```
| -- configs
| -- data
| -- logs
| -- results
| -- scripts
| -- tests
-- .gitignore
-- pixi.toml
-- pyproject.toml
-- README.md
```

- **data:** Large files such as datasets and generated artifacts.
- **logs:** Raw logs from experiments and runs.
- **results:** Curated outputs, visualisations, reports, or notebooks that explain experiments.
- **configs:** Configuration files for experiments, models, or robot setups.
- **scripts:** Self-contained scripts that usually perform one task and can be changed with arguments.
- **tests:** Tests for project functionality and small interactive checks.
