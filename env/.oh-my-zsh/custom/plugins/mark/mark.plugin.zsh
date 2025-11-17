# Docker
alias dup='docker compose up --build'
alias dce='docker compose exec'

# minikube
alias mk='minikube'
alias mks='minikube start'
alias mksp='minikube stop'
alias mkst='minikube status'
alias mkt='minikube tunnel'
alias mkcv='minikube config view'
alias mkcg='minikube config get'
alias mkcs='minikube config set'
alias mknl='minikube node list'
alias mkd='minikube delete'
alias mkpl='minikube profile list'

# helm
alias hrl='helm repo ls'
alias hra='helm repo add'
alias hla='helm ls --Aa'
alias hin='helm install'
alias hup='helm upgrade'
alias hun='helm uninstall --keep-history'
alias hs='helm status'
alias hrb='helm rollback'
alias hsr='helm search repo -l'
