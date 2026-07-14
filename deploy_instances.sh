#!/bin/bash
# =========================================================================
# SCRIPT DE AUTOMATIZACIÓN DE INSTANCIAS EC2 - BUYMAX
# Propósito: Despliegue elástico de servidores web estandarizados
# Diseñado por Diego Aravena para Infraestructura Cloud I (INY1104)
# =========================================================================

# 1. Parámetros de Red Base (Deben reemplazarse con los IDs generados en AWS)
VPC_ID="vpc-xxxxxx"                 # ID de tu buymax-vpc
SG_ID="sg-xxxxxx"                  # ID de tu sg-app-inst
SUBNET_ID_A="subnet-xxxxxx"         # ID de Subred Aplicación X (us-east-1a)
SUBNET_ID_B="subnet-xxxxxx"         # ID de Subred Aplicación Y (us-east-1b)

# 2. Configuración del Hardware Virtual
AMI_ID="ami-0c7217cdde317cfec"      # Amazon Linux 2023 AMI (us-east-1)
INSTANCE_TYPE="t2.micro"            # Hardware académico optimizado en costos

# 3. Script de Arranque (User Data) - Instalación automática del servicio
cat << 'EOF' > user_data.sh
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
# Creación de landing page dinámica para corroborar balanceo posterior
echo "<h1>BuyMax E-Commerce - Procesando en Nodo: $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
EOF

# 4. Ejecución del aprovisionamiento mediante CLI (Lanzamiento en Subred A)
echo "Desplegando Instancia en Subred Aplicación X..."
aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID_A" \
    --security-group-ids "$SG_ID" \
    --user-data file://user_data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-app-node-A}]' \
    --output json

# 5. Ejecución del aprovisionamiento mediante CLI (Lanzamiento en Subred B)
echo "Desplegando Instancia en Subred Aplicación Y..."
aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID_B" \
    --security-group-ids "$SG_ID" \
    --user-data file://user_data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-app-node-B}]' \
    --output json

echo "¡Despliegue automático completado con éxito!"
