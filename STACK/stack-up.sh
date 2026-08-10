#!/bin/bash
set -e

# Define the new cluster shared storage base directory
BASE_DIR="/media/cluster/common/stack-prototype"

echo "Creating persistent directory trees on shared storage..."
sudo mkdir -p "$BASE_DIR/mariadb_data"
sudo mkdir -p "$BASE_DIR/moodle_data"
sudo mkdir -p "$BASE_DIR/plugins/stack"
sudo mkdir -p "$BASE_DIR/plugins/dfexplicitvaildate"
sudo mkdir -p "$BASE_DIR/plugins/dfcbmexplicitvaildate"
sudo mkdir -p "$BASE_DIR/plugins/adaptivemultipart"
sudo mkdir -p "$BASE_DIR/plugins/importasversion"

echo "Cloning STACK question type and dependent behaviors..."
sudo git clone --depth 1 https://github.com/maths/moodle-qtype_stack.git "$BASE_DIR/plugins/stack"
sudo git clone --depth 1 https://github.com/maths/moodle-qbehaviour_dfexplicitvaildate.git "$BASE_DIR/plugins/dfexplicitvaildate"
sudo git clone --depth 1 https://github.com/maths/moodle-qbehaviour_dfcbmexplicitvaildate.git "$BASE_DIR/plugins/dfcbmexplicitvaildate"
sudo git clone --depth 1 https://github.com/maths/moodle-qbehaviour_adaptivemultipart.git "$BASE_DIR/plugins/adaptivemultipart"
sudo git clone --depth 1 https://github.com/maths/moodle-qbank_importasversion.git "$BASE_DIR/plugins/importasversion"

echo "Setting file permissions for container runtimes..."
sudo chmod -R 777 "$BASE_DIR"

echo "=========================================================="
echo "Bootstrap complete! Target directories updated to cluster mount."
echo "=========================================================="