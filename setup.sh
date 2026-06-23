#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
  echo "Usage: ./setup.sh [PACKAGE_NAME]"
  echo
  echo "Initialise this template as a new Python project."
}

prompt_default() {
  local prompt="$1"
  local default="$2"
  local value

  read -r -p "$prompt [$default]: " value
  printf "%s" "${value:-$default}"
}

prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local suffix value

  if [[ "$default" == "y" ]]; then
    suffix="[Y/n]"
  else
    suffix="[y/N]"
  fi

  while true; do
    read -r -p "$prompt $suffix " value
    value="${value:-$default}"
    case "$value" in
      y|Y|yes|YES|Yes) return 0 ;;
      n|N|no|NO|No) return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

valid_package_name() {
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

normalise_python_spec() {
  local version="$1"

  if [[ "$version" == *"*"* || "$version" == *"<"* || "$version" == *">"* || "$version" == *"="* ]]; then
    printf "%s" "$version"
  else
    printf "%s.*" "$version"
  fi
}

normalise_platforms() {
  local raw="${1//,/ }"
  local platforms=()
  local platform

  for platform in $raw; do
    platforms+=("\"$platform\"")
  done

  local IFS=", "
  printf "%s" "${platforms[*]}"
}

cuda_build_tag() {
  local version="$1"

  if [[ "$version" != *.* ]]; then
    version="${version}.0"
  fi

  printf "%s" "${version//./}"
}

write_pixi_toml() {
  local package_name="$1"
  local python_spec="$2"
  local platform_list="$3"
  local include_pytorch="$4"
  local use_cuda="$5"
  local cuda_version="$6"
  local cuda_major="${cuda_version%%.*}"
  local cuda_build

  cuda_build="$(cuda_build_tag "$cuda_version")"

  {
    printf "[workspace]\n"
    printf "channels = [\"conda-forge\"]\n"
    printf "description = \"Add a short description here\"\n"
    printf "name = \"%s\"\n" "$package_name"
    printf "platforms = [%s]\n" "$platform_list"
    printf "version = \"0.1.0\"\n"
    printf "\n"
    printf "[tasks]\n"
    printf "develop = {cmd = [\"nvim\", \".\"]}\n"
    printf "\n"
    printf "[pypi-options]\n"
    printf "no-build-isolation = []\n"
    printf "\n"

    if [[ "$use_cuda" == "true" ]]; then
      printf "[system-requirements]\n"
      printf "cuda = \"%s\"\n" "$cuda_version"
      printf "\n"
    fi

    printf "[dependencies]\n"

    if [[ "$use_cuda" == "true" ]]; then
      printf "cuda = {version = \"%s.*\"}\n" "$cuda_major"
    fi

    if [[ "$include_pytorch" == "true" && "$use_cuda" == "true" ]]; then
      printf "pytorch = {version = \">=2.4.0,<3\", build = \"*cuda%s*\"}\n" "$cuda_build"
      printf "torchvision = \">=0.19.1,<0.20\"\n"
    elif [[ "$include_pytorch" == "true" ]]; then
      printf "pytorch = \">=2.4.0,<3\"\n"
      printf "torchvision = \">=0.19.1,<0.20\"\n"
    fi

    printf "python = \"%s\"\n" "$python_spec"
    printf "setuptools = \">42\"\n"
    printf "pip = \">=24.3.1,<25\"\n"
    printf "ruff = \">=0.7.2,<0.8\"\n"
    printf "pyright = \">=1.1.388,<2\"\n"
    printf "hatch = \">=1.13.0,<2\"\n"
    printf "\n"
    printf "[pypi-dependencies]\n"
    printf "%s = {path = \".\", editable = true}\n" "$package_name"
  } > pixi.toml
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

new_name="${1:-}"

while [[ -z "$new_name" ]]; do
  new_name="$(prompt_default "Package name" "my_project")"
done

if ! valid_package_name "$new_name"; then
  echo "Package name must be a valid Python module name, for example: my_project"
  exit 1
fi

if [[ ! -d "{{python_template}}" ]]; then
  echo "Could not find the {{python_template}} package directory."
  exit 1
fi

if [[ -e "$new_name" ]]; then
  echo "Target package directory already exists: $new_name"
  exit 1
fi

python_version="$(prompt_default "Python version" "3.11")"
python_spec="$(normalise_python_spec "$python_version")"
platform_input="$(prompt_default "Pixi platforms, comma or space separated" "linux-64")"
platform_list="$(normalise_platforms "$platform_input")"

include_pytorch=false
use_cuda=false
cuda_version="12.9"

if prompt_yes_no "Install PyTorch" "y"; then
  include_pytorch=true

  if prompt_yes_no "Use CUDA/GPU PyTorch in the default Pixi environment" "y"; then
    use_cuda=true
    cuda_version="$(prompt_default "CUDA version" "12.0")"
  fi
fi

mv "{{python_template}}" "$new_name"
sed -i -e "s/name = 'src'/name = '${new_name}'/" setup.py
sed -i -e "s/name = \"src\"/name = \"${new_name}\"/" pyproject.toml
write_pixi_toml "$new_name" "$python_spec" "$platform_list" "$include_pytorch" "$use_cuda" "$cuda_version"

if command -v pixi >/dev/null 2>&1 && prompt_yes_no "Run pixi install now" "n"; then
  pixi install
fi

if prompt_yes_no "Remove setup.sh from the initialised project" "y"; then
  rm -- "$(basename "${BASH_SOURCE[0]}")"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && prompt_yes_no "Create initial git commit" "y"; then
  git add .

  if git diff --cached --quiet; then
    echo "No changes staged for commit."
  elif ! git commit -m "initial commit"; then
    echo "Initial commit failed. Check your git configuration and commit manually."
  fi
fi
