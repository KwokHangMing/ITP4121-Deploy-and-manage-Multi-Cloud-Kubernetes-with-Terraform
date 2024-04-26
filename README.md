# ITP4121-Deploy-and-manage-Multi-Cloud-Kubernetes-with-Terraform

create multiple public cloud infrastructures and Kubernetes deployment with Terraform

| Task Description                                       | Max Mark | Mark |
|--------------------------------------------------------|----------|------|
| Setup GitHub Project and shared to lecturer            | 5        |      |
| Using multiple Cloud Providers (only 1 ZERO mark)      | 15       |      |
| Multiple VMs in VPC and 2 private subnets              | 5        |      |
| Unique Kubernetes Application with database            | 5        |      |
| Cluster AutoScaler                                     | 5        |      |
| Connect to Database                                   | 5        |      |
| Using Kubernetes Secret properly                       | 5        |      |
| Using Cloud native load balancer                       | 5        |      |
| With SSL/TLS                                           | 5        |      |
| Stream application log data to cloud logging services  | 5        |      |
| Multiple Cloud High Availability                       | 5        |      |
| Demo deployment during Lab                             | 15       |      |

Please make sure to prepare your own Google Cloud Project and Azure Subscriptions before running the script.
Useful commands below:
```
gcloud auth application-default login

gcloud auth application-default set-quota-project <PROJECT_ID>

gcloud auth configure-docker \
    us-east1-docker.pkg.dev

az login --use-device-code
az account show
```
