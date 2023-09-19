# Lab 05 - K8s native development tasks and concepts

## Goals
In this lab we are going to use the Bastion service to operate the OKE cluster using `kubectl`

### Intro
In our previous lab, our deployment failed to create the workload inside the cluster, let's remediate the workload. Following the CIS standards, the spoke networks should not have their own NAT gatway for egress traffic. It should be through a NVA deployed in the DMZ zone. For our workshop, we do not want to go with nuances of deploying the NVA. Instead we are going to make available the artifacts required to deploy the workload

## Task 1 - Create OCI Artifact Image registry repositories
k8s uses registries to fetch container images, these artifacts contains the applications that compose a given workload. Instead of building our own images we are going to use already developed example workloads, import them into a registry that is available to the OKE cluster. We are going to follow the guidelines in [Pull an Image from Oracle Cloud Infrastructure Registry when Deploying a Load-Balanced Application to a Cluster](https://www.oracle.com/webfolder/technetwork/tutorials/obe/oci/oke-and-registry/index.html).

``` sh
#Configure access from the cluster to the registry
kubectl create secret docker-registry ocirsecret --docker-server=<region-key>.ocir.io --docker-username=<tenancy-namespace>/<oci-username> --docker-password='<oci-auth-token>' --docker-email=<email-address>

docker login fra.ocir.io
# use <tenancy-namespace>/<username
export compartment_id="<substitute-value-of-compartment_id>"

oci artifacts container repository create --compartment-id $compartment_id --display-name sebcegal-cir-app1/redis
docker pull arm64v8/redis:6.0
docker tag arm64v8/redis:6.0 fra.ocir.io/nose/sebcegal-cir-app1/redis:v6 
docker push fra.ocir.io/nose/sebcegal-cir-app1/redis:v6

oci artifacts container repository create --compartment-id $compartment_id --display-name sebcegal-cir-app1/gb-redisslave
docker pull gcr.io/google-samples/gb-redisslave-arm64:v3
docker tag gcr.io/google-samples/gb-redisslave-arm64:v3 fra.ocir.io/nose/sebcegal-cir-app1/gb-redisslave:v3 
docker push fra.ocir.io/nose/sebcegal-cir-app1/gb-redisslave:v3

oci artifacts container repository create --compartment-id $compartment_id --display-name sebcegal-cir-app1/gb-frontend
docker pull gcr.io/google-samples/gb-frontend-arm64:v6
docker tag gcr.io/google-samples/gb-frontend-arm64:v6 fra.ocir.io/nose/sebcegal-cir-app1/gb-frontend:v6
docker push fra.ocir.io/nose/sebcegal-cir-app1/gb-frontend:v6
```
## Task 2 - Redeploy and updated workload definition

Now we can deploy an updated version of the workload using the k8s defintion file [`gb.yml`](../../app-team/src/gb.yml).
```sh
kubectl apply -f app-team/src/gb.yml -n gb
```

# Some agnostic Cloud Native concepts
- [The twelve-factor App](https://12factor.net/)
- Discussion: Opinionated technology stacks in k8s (PPT)