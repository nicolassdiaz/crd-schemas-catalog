# Kubernetes CRD JSON Schema Extractor

Generate JSON schemas from Kubernetes Custom Resource Definitions (CRDs) for use with kubeconform.

## Table of Contents
- [Description](#description)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Adding Additional Sources](#adding-additional-sources)
- [Using with kubeconform in GitLab CI](#using-with-kubeconform-in-gitlab-ci)
- [Output Structure](#output-structure)
- [Changelog](#changelog)
- [Contributing](#contributing)

## Description

The `crd-extractor.sh` script automates the process of:
1. Cloning Kubernetes project repositories
2. Extracting CRDs from these repositories
3. Converting CRDs to JSON schemas
4. Organizing JSON schemas into a coherent directory structure

The resulting JSON schemas can be used by kubeconform to validate Kubernetes manifests, ensuring that custom resources comply with their respective CRD definitions.

## Requirements

- bash
- git
- [yq](https://github.com/mikefarah/yq)

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/k8s-crd-json-schema-extractor.git
   ```
2. Make the script executable:
   ```
   chmod +x crd-extractor.sh
   ```

## Usage

Run the script:
```
./crd-extractor.sh
```
JSON schemas will be generated in the output directory (by default, the current directory).

## Adding Additional Sources

To add support for additional Kubernetes projects:

1. Open `crd-extractor.sh` in a text editor.
2. Locate the `SOURCES` array:
   ```bash
   SOURCES=(
       "https://github.com/GoogleCloudPlatform/k8s-config-connector/tree/v1.124.0/crds"
       "https://github.com/argoproj/argo-workflows/tree/release-3.6/manifests/base/crds/full"
   )
   ```
3. Add a new entry:
   ```bash
   "https://github.com/[org-name]/[repo-name]/tree/[tag]/[path-to-crds]"
   ```
4. Save the changes and run the script.

Example:
```bash
"https://github.com/istio/istio/tree/1.17.2/manifests/charts/base/crds"
```

Remember to update the Changelog section when adding support for new projects.

## Using with kubeconform in GitLab CI

Add this stage to your `.gitlab-ci.yml`:

```yaml
stages:
  - validate

validate_helm_charts:
  stage: validate
  script:
    - helm template my-release repo/my-awesome-chart -f values-production.yaml | kubeconform -schema-location /path/to/generated/schemas/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' -verbose
```

Replace `/path/to/generated/schemas` with the actual path in your CI environment.

## Output Structure

The JSON schemas are organized as follows:

```
./
├── [repo-name]/
│   └── [tag]/
│       └── [group]/
│           └── [kind]_[version].json
```

## Changelog

### v1.0.0 (2024-10-22)

#### Added
- Support for [Google Cloud Config Connector](https://github.com/GoogleCloudPlatform/k8s-config-connector)
  - Version: v1.124.0
  - CRDs location: `/crds`
- Support for [Argo Workflows](https://github.com/argoproj/argo-workflows)
  - Version: release-3.6
  - CRDs location: `/manifests/base/crds/full`

#### Notes
- Initial release of the CRD JSON Schema Extractor
- Includes support for two major Kubernetes-related projects
- Generates JSON schemas compatible with kubeconform

## Contributing

Contributions are welcome! Please feel free to submit a merge request.