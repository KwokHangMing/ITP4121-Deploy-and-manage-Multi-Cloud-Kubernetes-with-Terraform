echo "Deploying Google Cloud Platform resources..."

cd gcp
terraform init -upgrade
# terraform plan
terraform apply --auto-approve
# Check if Terraform executed without errors
if [ $? -eq 0 ]; then
  echo "Google Cloud Platform resources deployed successfully!"
else
  echo "Error deploying Google Cloud Platform resources. Destroying..."
  terraform destroy --auto-approve
  if [ $? -ne 0 ]; then
    echo "Error destroying Google Cloud Platform resources. Exiting..."
    exit 1
  fi
fi
cd ..

echo "Deploying Azure Resources..."
cd azure
terraform init -upgrade
terraform apply --auto-approve
# Check if Terraform executed without errors
if [ $? -eq 0 ]; then
  echo "Azure resources deployed successfully!"
else
  echo "Error deploying Azure resources. Destroying..."
  terraform destroy --auto-approve
  if [ $? -ne 0 ]; then
    echo "Error destroying Azure resources. Exiting..."
    exit 1
  fi
fi