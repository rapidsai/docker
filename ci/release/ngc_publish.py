#!/usr/bin/env python3
# NGC Publishing Pipeline Script
# This script generates NGC publishing configuration file and creates a GitLab MR

import argparse
import os
import sys
import yaml
import logging
import subprocess
from datetime import datetime
from typing import Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("ngc_publish")

# GitLab constants
NGC_PUBLISHING_REPO = "ngc/publishing/ngc-publishing-configs"

def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Generate NGC publishing configuration and create GitLab MR")

    parser.add_argument("--rapids-version", required=True, help="RAPIDS version (e.g., 25.04)")
    parser.add_argument("--nspect-id", required=True, help="NSPECT ID from security scanning")
    parser.add_argument("--source-org", default="nvstaging", help="Source organization")
    parser.add_argument("--source-team", default="rapids", help="Source team")
    parser.add_argument("--target-org", default="nvidia", help="Target organization")
    parser.add_argument("--target-team", default="rapidsai", help="Target team")
    parser.add_argument("--searchable", default=True, type=bool, help="Make artifacts searchable")
    parser.add_argument("--public", default=True, type=bool, help="Make artifacts public")
    parser.add_argument("--gitlab-token", required=True, help="GitLab Personal Access Token")
    parser.add_argument("--dry-run", action="store_true", help="Generate config but don't create MR")
    parser.add_argument("--output-dir", default=".", help="Directory to output the YAML file")
    parser.add_argument("--matrix-yaml", default="matrix.yaml", help="Path to matrix.yaml file defining CUDA versions and Python versions")

    return parser.parse_args()

def validate_args(args):
    """Validate the command line arguments"""
    # Check matrix.yaml exists
    if not os.path.exists(args.matrix_yaml):
        logger.error(f"Matrix YAML file not found: {args.matrix_yaml}")
        return False

    # Validate RAPIDS version format
    if not args.rapids_version.replace(".", "").isdigit():
        logger.warning(f"Unusual RAPIDS version format: {args.rapids_version}. Expected format like '25.04'")

    return True

def load_matrix_yaml(matrix_yaml_path):
    """Load the matrix YAML file to get CUDA and Python versions"""
    try:
        with open(matrix_yaml_path, 'r') as f:
            matrix_data = yaml.safe_load(f)
        return matrix_data
    except Exception as e:
        logger.error(f"Error loading matrix YAML: {str(e)}")
        raise

def generate_artifacts_from_matrix(rapids_version, matrix_data):
    """Generate artifact list from matrix data"""
    artifacts = []

    # Extract CUDA and Python versions from matrix
    cuda_versions = matrix_data.get("CUDA_VER", [])
    python_versions = matrix_data.get("PYTHON_VER", [])

    for cuda_ver in cuda_versions:
        # Extract CUDA major.minor only (e.g., 11.8 from 11.8.0)
        cuda_ver_short = ".".join(cuda_ver.split(".")[:2])

        for python_ver in python_versions:
            # Add base container
            artifacts.append({
                "type": "container",
                "source_name": "rapids/base",
                "source_version": f"{rapids_version}-cuda{cuda_ver_short}-py{python_ver}"
            })

            # Add notebooks container
            artifacts.append({
                "type": "container",
                "source_name": "rapids/notebooks",
                "source_version": f"{rapids_version}-cuda{cuda_ver_short}-py{python_ver}"
            })

    # Add the generic resource artifact
    artifacts.append({
        "type": "resource",
        "source_name": "rapids",
        "source_version": rapids_version
    })

    return artifacts

def generate_config(args, matrix_data=None) -> Dict[str, Any]:
    """Generate NGC publishing configuration YAML"""
    if matrix_data:
        artifacts = generate_artifacts_from_matrix(args.rapids_version, matrix_data)
    else:
        # Fallback to empty artifact list
        artifacts = [{
            "type": "resource",
            "source_name": "rapids",
            "source_version": args.rapids_version
        }]

    config = {
        "nspect_id": args.nspect_id,
        "source": {
            "org": args.source_org,
            "team": args.source_team
        },
        "target": {
            "org": args.target_org,
            "team": args.target_team
        },
        "artifacts": artifacts,
        "options": {
            "searchable": args.searchable,
            "public": args.public
        }
    }

    return config

def write_config_file(config: Dict[str, Any], args) -> str:
    """Write config to a YAML file and return the file path"""
    # Create output directory if it doesn't exist
    os.makedirs(args.output_dir, exist_ok=True)

    # Generate filename based on RAPIDS version
    filename = f"rapids-{args.rapids_version}.yaml"
    file_path = os.path.join(args.output_dir, filename)

    # Write YAML file
    with open(file_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

    logger.info(f"Configuration written to {file_path}")
    return file_path

def clone_repository(gitlab_token: str) -> str:
    """Clone the NGC publishing repository and return the local path"""
    # Create a unique temporary directory in /tmp
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    temp_dir = os.path.join("/tmp", f"ngc-publishing-{timestamp}")

    # Format repository URL with token
    repo_url = f"https://oauth2:{gitlab_token}@gitlab-master.nvidia.com/{NGC_PUBLISHING_REPO}.git"

    try:
        subprocess.run(["git", "clone", repo_url, temp_dir], check=True)
        logger.info(f"Cloned repository to {temp_dir}")
        return temp_dir
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to clone repository: {str(e)}")
        raise

def create_and_checkout_branch(repo_path: str) -> str:
    """Create a new branch and checkout"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    branch_name = f"rapids-{timestamp}"

    try:
        subprocess.run(["git", "checkout", "-b", branch_name], cwd=repo_path, check=True)
        logger.info(f"Created and checked out branch: {branch_name}")
        return branch_name
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to create branch: {str(e)}")
        raise

def add_file_to_repo(repo_path: str, file_path: str, rapids_version: str) -> None:
    """Add the config file to the repository"""
    dest_path = os.path.join(repo_path, "configs", "rapids", f"rapids-{rapids_version}.yaml")
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)

    try:
        # Copy the file to the repository
        subprocess.run(["cp", file_path, dest_path], check=True)

        # Add and commit the file
        subprocess.run(["git", "add", dest_path], cwd=repo_path, check=True)
        subprocess.run(
            ["git", "commit", "-m", f"Add RAPIDS {rapids_version} docker images to NGC"],
            cwd=repo_path,
            check=True
        )
        logger.info(f"Added and committed file to repository")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to add file to repository: {str(e)}")
        raise

def push_and_create_mr(repo_path: str, branch_name: str, rapids_version: str, gitlab_token: str) -> str:
    """Push the branch and create a merge request"""
    try:
        # Configure git to use the token for pushing
        subprocess.run(["git", "config", "--local", "http.extraHeader", f"Authorization: Bearer {gitlab_token}"],
                      cwd=repo_path, check=True)

        # Push the branch
        subprocess.run(["git", "push", "-u", "origin", branch_name], cwd=repo_path, check=True)

        # Create merge request using GitLab CLI
        mr_title = f"Add RAPIDS {rapids_version} publishing configuration"
        mr_description = f"""
This MR adds publishing configuration for RAPIDS {rapids_version} docker images to NGC.
        """

        # Configure glab to use the token
        subprocess.run(["glab", "auth", "login", "--token", gitlab_token], check=True)

        result = subprocess.run(
            ["glab", "mr", "create", "--title", mr_title, "--description", mr_description, "--target-branch", "jawe/fake-main"],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )

        # Extract MR URL from the output
        mr_url = result.stdout.strip()
        logger.info(f"Created merge request: {mr_url}")
        return mr_url
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to push branch or create merge request: {str(e)}")
        raise

def main():
    """Main function to run the NGC publishing pipeline"""
    args = parse_args()

    if not validate_args(args):
        sys.exit(1)

    try:
        # Load matrix YAML to get CUDA and Python versions
        matrix_data = load_matrix_yaml(args.matrix_yaml)

        # Generate and write configuration
        config = generate_config(args, matrix_data)
        config_file = write_config_file(config, args)

        if args.dry_run:
            logger.info("Dry run mode - skipping GitLab MR creation")
            logger.info(f"Generated config file: {config_file}")
            sys.exit(0)

        # Clone repository and create MR
        repo_path = clone_repository(args.gitlab_token)
        branch_name = create_and_checkout_branch(repo_path)
        add_file_to_repo(repo_path, config_file, args.rapids_version)
        mr_url = push_and_create_mr(repo_path, branch_name, args.rapids_version, args.gitlab_token)

        # Output MR URL for tracking
        print(f"GitLab MR created: {mr_url}")
        print(f"Please track the MR status and ensure it is approved.")

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
