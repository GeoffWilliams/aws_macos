# AWS macOS

Run macOS in AWS for testing out systems macOS compatibility

All done with Terraform and ansible

## How do you know to do this?

Easy! I follow Tony on YouTube 😂

* [How to run mac in the cloud (macOS on AWS)](https://www.youtube.com/watch?v=-lvEK0A142c)
* [How can I access my Amazon EC2 Mac instance through a GUI?](https://repost.aws/knowledge-center/ec2-mac-instance-gui-access)

## Prerequisites

1. You must allow dedicated mac1/mac2 quotas for EC2: ![mac1/mac2 quotas](./images/quotas.png)
2. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and adjust as required

## Create a macOS box accessible via SSH

```shell
cd terraform

# one time
# terraform init

terraform apply
```

Paste the `sshconfig` output into `~/.ssh/config` and then login to the macOS by ssh:

```shell
ssh macos
```

Enjoy!

## GUI access

Since most macOS programs are GUI apps, its just about impossible to do all tasks over SSH so we must enable VNC and access via a tunnel. Set this up with Ansible:

```shell
cd ansible

# test connectivity
ansible -m ping all -i hosts.yml

ansible-playbook -i hosts.yml playbooks/vnc.yml
```

Now SSH to the box and open an SSH tunnel:

```shell
ssh -L 5900:localhost:5900 macos

# set a password we need it for VNC
sudo /usr/bin/dscl . -passwd /Users/ec2-user
```

Finally, you can connect via VNC:

* Client software for Linux: [remmina](https://remmina.org/)
* Server: localhost
* Port: 5900
* Username: ec2-user
* Password: whatever you just set