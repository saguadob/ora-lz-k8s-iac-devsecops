
``` sh

export oke_ocid="<oke>"
export bastion_ocid="<bastion>"
export oke_api_address="<oke_ip>"

oci ce cluster create-kubeconfig --cluster-id $oke_ocid --file $HOME/.kube/config --token-version 2.0.0 --kube-endpoint PRIVATE_ENDPOINT

ssh-keygen -t ssh-ed25519 -N "" -b 2048 -f ~/.ssh/k8s_bastion
# ssh-keygen -t rsa -N "" -b 2048 -f ~/.ssh/k8s_bastions
oci bastion session create-port-forwarding --bastion-id $bastion_ocid --ssh-public-key-file ~/.ssh/k8s_bastion.pub --key-type PUB --target-private-ip $oke_api_address --target-port 6443

ssh -i ~/.ssh/k8s_bastio -N -L "6443:${oke_api_address}:6443" -p 22 "${bastion_session_ocid}@host.bastion.eu-frankfurt-1.oci.oraclecloud.com"
#-o "ProxyCommand=nc -X connect -x www.proxy.com:80 %h %p"

#change kubectl server endpoint
kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook/all-in-one/guestbook-all-in-one.yaml -n gb
```

Deploy images to ocir
``` sh

kubectl create secret docker-registry <secret-name> --docker-server=<region-key>.ocir.io --docker-username=<tenancy-namespace>/<oci-username> --docker-password='<oci-auth-token>' --docker-email=<email-address>

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