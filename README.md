# FoF Terraform
the fof infrastructure 

## Running this

* Install Terraform
* Install `glcould` cli
* add your ssh key to your account. Command below. See https://cloud.google.com/compute/docs/instances/managing-instance-access#add_oslogin_keys
```bash
gcloud compute os-login ssh-keys add \
    --key-file [KEY_FILE_PATH] \
    --ttl [EXPIRE_TIME]
```
* Update the variables if needed