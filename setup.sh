#!/bin/bash

terraform init

terraform validate

if [ $? -eq 0 ]; then
    terraform plan -out=tfplan

    if [ $? -eq 0 ]; then
        terraform apply -auto-approve tfplan

        rm -f tfplan
    else
        echo "Erreur lors de la génération du plan. Vérifiez les messages d'erreur ci-dessus."
    fi
else
    echo "Erreur de validation. Vérifiez les messages d'erreur ci-dessus."
fi
