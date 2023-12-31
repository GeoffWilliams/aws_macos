# App setup

Some creature comfort/essential apps are needed for macOS, you can do by hand:

1. golang: `brew install golang`
2. JDK: `brew install java` and follow the instructions to update your shell
3. `yq`: `brew install yq`
4. `jq`: `brew install jq`
5. Confluent CLI: `brew install confluentinc/tap/cli`
6. CFSSL: `go install github.com/cloudflare/cfssl/cmd/...@latest`
7. [helm](https://helm.sh/): `brew install helm`
8. Update `$PATH` to add binaries installed by go

Or via Ansible:

```shell
cd ansible

# one time
ansible-galaxy collection install community.general

# general apps
ansible-playbook -i hosts.yml playbooks/apps.yml

# Confluent SDK/CLI
ansible-playbook -i hosts.yml playbooks/confluent.yml
```

Dont forget to logout and back in again to refresh `$PATH`
