echo "Please enter the cloud provider (aws, azure, gcp) to deploy or 'exit' to stop: "
read provider

case $provider in
  aws)
    cd aws
    ;;
  azure)
    cd azure
    ;;
  gcp)
    cd gcp
    ;;
  exit)
    echo "Exiting script."
    exit 0
    ;;
  *)
    echo "Invalid option. Exiting script."
    exit 1
    ;;
esac

terraform init -upgrade
# terraform plan
terraform apply --auto-approve