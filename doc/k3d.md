# K3D on macOS with accessible load balancers

> **Note**
> Use the latest docker and k3d versions!

## Install K3D

Since k3d install is just a single command, no need for ansible playbook. Go ahead and install it:

```shell
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

## Create cluster

* K3D built-in servicelb grabs ports on every node and breaks our load balancers, traefik takes port 443
  * Disable servicelb and traefik
  * Use metallb instead

```shell
k3d cluster create cfk-lab --servers 1 --agents 2 --k3s-arg "--disable=traefik@server:*" --k3s-arg "--disable=servicelb@server:*"

# test - K3D sets itself as default in ~/.kube/config
kubectl get nodes
```

## MetalLB
* Instruction source:
  1. https://metallb.universe.tf/installation/
  2. https://github.com/keunlee/k3d-metallb-starter-kit

### Installation

```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
```

### Setup

Some scripts from this repository need to be run on the macOS. Easiest to just clone the repo.

```shell
git clone https://github.com/GeoffWilliams/aws_macos
cd aws_macos

./scripts/configure_metallb_ingress_range.sh cfk-lab
```

## Test it!

Test networking end-to-end by deploying [httpbin](https://httpbin.org/) mini http service...

```shell
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml
```

A load balancer...

```shell
kubectl apply -f k8s/test-lb.yaml
```

Checking the IP was allocated (172.18.0.100)...

```
ec2-user@ip-172-31-45-145 aws_macos % kubectl get service -o wide
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE     SELECTOR
httpbin      LoadBalancer   10.43.247.113   172.18.0.100   80:31539/TCP,443:32159/TCP   6m35s   <none>
kubernetes   ClusterIP      10.43.0.1       <none>         443/TCP                      38m     <none>
```

And finally, testing the teapot:

```shell
curl -k http://172.18.0.100/status/418


    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
```

If you see the teapot you have Docker + K3D + K3S + Kubernetes + Load balancer + bridged networking working - well done!

## Troubleshooting

* Docker wont start until you login
* K3d does not like reboots (I had to recreate cluster - theres probably an easier way)
* Your computer will be very slow! (use k3d command to stop the cluster)
* Some kubernetes apps (eg CFK/CP) fail to start fully - check your kubernetes node didnt randomly die. See next point
* Some kubernetes apps will crash nodes/laptop/everything - macs are just not hardcore enough for some tasks, even with a ton of swap allocated. Get yourself a thinkpad or run workload on a spare Linux PC or the cloud.