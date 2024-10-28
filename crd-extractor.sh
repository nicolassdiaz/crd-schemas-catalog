#!/bin/bash

# Check for required tools
for cmd in git yq; do
    command -v $cmd &> /dev/null || { echo "Error: $cmd not installed."; exit 1; }
done

# Define directories
OUTPUT_DIR="./"
TEMP_BASE_DIR="./temp_repos"
mkdir -p "$OUTPUT_DIR" "$TEMP_BASE_DIR"

# List of CRD sources
# Format: "https://github.com/org/repo-name/tree/tag/crds-folder"
SOURCES=(
    "https://github.com/GoogleCloudPlatform/k8s-config-connector/tree/v1.124.0/crds"
    "https://github.com/argoproj/argo-workflows/tree/release-3.6/manifests/base/crds/full"
)

# Function to generate the output filename
generate_output_filename() {
    local crd_file=$1
    local group=$(yq e '.spec.group' "$crd_file" 2>/dev/null)
    [[ -z "$group" || "$group" == "null" ]] && return
    local kind=$(yq e '.spec.names.kind' "$crd_file" 2>/dev/null)
    local version=$(yq e '.spec.versions[0].name' "$crd_file" 2>/dev/null)
    [[ -n "$kind" && -n "$version" ]] && echo "${group}/${kind}_${version}.json" | tr '[:upper:]' '[:lower:]'
}

# Function to fetch CRDs and convert to JSON schema
generate_json_schema() {
    local full_url=$1
    [[ $full_url =~ github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+) ]] || return 1
    local org_name="${BASH_REMATCH[1]}" repo_name="${BASH_REMATCH[2]}" tag="${BASH_REMATCH[3]}" crd_folder="${BASH_REMATCH[4]}"
    local repo_url="https://github.com/$org_name/$repo_name"
    local tag_dir="$OUTPUT_DIR/$repo_name/$tag"
    local temp_repo_dir="$TEMP_BASE_DIR/${repo_name}_${tag}"
    mkdir -p "$tag_dir" "$temp_repo_dir"

    echo "Cloning $repo_name repository"
    echo "Git Tag: $tag"
    # Clone repository
    if ! git clone --quiet --depth 1 --branch $tag --single-branch --no-tags $repo_url "$temp_repo_dir" 2>/dev/null; then
        echo "Error: Failed to clone $repo_url"
        return 1
    fi
    [ -d "$temp_repo_dir/$crd_folder" ] || { echo "Error: $crd_folder not found."; return 1; }

    echo "Processing CRDs from $repo_name"
    # Process YAML files
    local processed=0
    while IFS= read -r crd_file; do
        yq e '.kind == "CustomResourceDefinition"' "$crd_file" &>/dev/null || continue
        output_file=$(generate_output_filename "$crd_file")
        [ -z "$output_file" ] && continue
        output_path="$tag_dir/$output_file"
        mkdir -p "$(dirname "$output_path")"
        # Extract openAPIV3Schema and convert to JSON
        yq e '.spec.versions[].schema.openAPIV3Schema' "$crd_file" -o=json > "$output_path"
        [ -s "$output_path" ] && ((processed++)) || rm -f "$output_path"
    done < <(find "$temp_repo_dir/$crd_folder" -name "*.yaml")
    echo "Processed $processed CRDs from $repo_name"

    # Clean up
    rm -rf "$temp_repo_dir"
}

# Process each source
for source in "${SOURCES[@]}"; do
    echo "Processing source: $source"
    generate_json_schema "$source" || echo "Error processing: $source"
    echo "----------------------------------------"
done

# Final cleanup
rm -rf "$TEMP_BASE_DIR"
echo "All JSON schemas generated in $OUTPUT_DIR"

# Example command to validate a Kubernetes manifest with kubeconform
# kubeconform -schema-location "$OUTPUT_DIR/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json" your-manifest-file.yaml
