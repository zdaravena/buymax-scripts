#!/bin/bash
# =========================================================================
# SCRIPT DE AUTOMATIZACIÓN DE INSTANCIAS EC2 - BUYMAX
# Diseñado para: AWS Learner Lab
# =========================================================================

# 1. PARÁMETROS BASE
SG_ID="sg-01f94d57c9c75a907"                  # ID de Grupo de Seguridad 'sg-app-inst'
SUBNET_A="subnet-0f9385881d0cb3869"           # ID de 'app-subnet-X' (us-east-1a)
SUBNET_B="subnet-0a4e97ae77e8a1613"           # ID de 'app-subnet-Y' (us-east-1b)

# 2. RESOLUCIÓN DINÁMICA DE AMI
echo "Consultando a AWS por la última versión de Amazon Linux 2023..."
AMI_ID=$(aws ssm get-parameters \
    --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
    --query "Parameters[0].Value" \
    --output text)

echo "AMI Oficial Identificada: $AMI_ID"
INSTANCE_TYPE="t2.micro"

# 3. CREACIÓN DEL USER DATA (Nginx Automatizado)
cat << 'USERDATA' > user_data.sh
#!/bin/bash
sleep 10
dnf update -y
dnf install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>BuyMax E-Commerce - Servidor Activo en: \$(hostname -f)</h1>" > /usr/share/nginx/html/index.html
USERDATA

# 4. DESPLIEGUE DEL NODO A (us-east-1a)
echo "Aprovisionando web-app-node-A con perfil de IAM (SSM)..."
aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_A" \
    --security-group-ids "$SG_ID" \
    --iam-instance-profile Name="LabInstanceProfile" \
    --key-name "vockey" \
    --user-data file://user_data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-app-node-A}]' \
    --output json > /dev/null

# 5. DESPLIEGUE DEL NODO B (us-east-1b)
echo "Aprovisionando web-app-node-B con perfil de IAM (SSM)..."
aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_B" \
    --security-group-ids "$SG_ID" \
    --iam-instance-profile Name="LabInstanceProfile" \
    --key-name "vockey" \
    --user-data file://user_data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-app-node-B}]' \
    --output json > /dev/null

echo "¡Aprovisionamiento automático completado con éxito!"
