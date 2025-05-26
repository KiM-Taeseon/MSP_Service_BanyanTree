#!/bin/bash

# Update system
yum update -y

# Install required packages
yum install -y wget unzip python3 python3-pip git jq util-linux yum-utils

# Set up environment variables
cat > /etc/environment <<EOF
STATE_BUCKET=terraform-state-runner-157931043046
CONFIG_BUCKET=terraform-configs-runner-157931043046 
AWS_REGION=ap-northeast-1
KEY_NAME=server-key.pem
EOF

# Create terraform user
useradd terraform
mkdir -p /home/terraform/.aws
mkdir -p /home/terraform/projects
mkdir -p /home/terraform/logs
chown -R terraform:terraform /home/terraform

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# Install AWS CLI
pip3 install awscli --upgrade

mkdir -p /root/.ssh
chmod 700 /root/.ssh

cat > "/root/.ssh/$KEY_NAME" << 'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAwOe2zUByZVrE5Y/g8z2do+QAPLokd4+pj+PxEUExuBP5AQYm
0UvSsqdnSRM3XRpu4pO0eTMw/f4EKyQAdcTClcxSfmkxDXrWbKUfyubtBWm49VW8
AQJ9oJ5sArv1E7oAF1Rjop1B7oILRsJ1tX/rKgL4w81Fgd7kP7p/dJqSlE0ir1ry
T/cu4ti1F9RTJk/SzCDtxUzLEjEYxxEHRB13j/s3xXkWKJ+sp6DHiwN6BQOI5xNc
wqW/jpBnOHDOEYnvKVVHyPoqHH4dNWuomRwSskW2b8jc4vrSwcJicoJ1et2gcwTS
L6KR67iz+uXtnvB2dGyYNoA+uovppxgEyPfqiwIDAQABAoIBACi9hzToBID1X5of
/eFBRRbE42vv4B3EIIp8GICNZUO8LB2UQAR54ADNLBoZzdqC56JAkZ/7OMCbsiOu
Uc6NhI8AfPenna18IOcHJKTEipBXGLHvrmoELaYLb0JQkdzdroE+2GASmEcX/euu
zA9N+cuAnyszIhfgjBINgDePIZ/iIKWXmln0kj4WmNV0YH2UehjV8ICCV3ATmOgs
RLFOEJzDPnmWBkYg3FTIpSB9D9Wb/iamFwn05H4nEUigFxPwHitH6jOMkfhi9e6F
E7OnPjxcBvQZ5DpW2SPf+I9Ik7Ov3hijT0ljzBYXUITapSOJXC7xZfnY0SJyoifo
LRgo90kCgYEA5P4kNVDOG5kuXJt55YFmNXdzWlG10MkZBLzdmFFQSsZe0JqhIUvP
eO3A1ZTDdEvQ6NCFopBsaTT7tNWlhJJ5B/uwSBrTuvQhGGDfud3Ek9Kywq2MoKuF
AI0aokMqEEzG3N5RdKzvhyet965NYz4rDAPiNc9MmDoa7gcLC+G3DK0CgYEA16f/
kQDhyfoQBLLuLG3Ltn9rzHvz5sPGn4oKW1US8UoyO5zqkNpjSlpc8PXuoo4f0c+1
2bZNthoJmbyaR15q2JPn9ojnZBkWTbtRdptTnRDXh1pF/rIHwyx6ZBu4AApOvHgZ
QofgbAAI6WOHD+oE4UT0Kch01HC5ZrSq1WwWwxcCgYAUBlFeRDGx4iRWvtXbBwTM
GiUBOfH/TwacDnQGVN4Dm/NApLUAd2OuPIRHaRnqepLLOSjmfWCtlo+IUcKGpFRn
KVBSDd6EE8MtIZOO6mC9WIh/U7PffQBFexFgLSVphX1CZUKURGcx13t0FE76Jb6X
72MBt54IFdSzCfSiVluuhQKBgG85xXT7GHj8kRBrXK3rfvrEI0wWzgfCB4o3Pvo2
GYv7MYdPeid1i2pIytC4dvi+BqlG0MrV3KTELxlsjcGrb73+ItAjcfxNeBRlPTHI
EMrcadz0cU9YcOp34TQKm87hghRweM64l8X8Cpyc6YcKsrOgxbFbIu6CqQzQt59V
nTPHAoGAOcr0DPOTVfvSGMpR3/VYa7gSnzzQh3y8Tfu4hVuXXAmcgRK8KDe04Wz/
Ey/ex7NrTIMITEezZo3iB6Qp6+eA+MXzujVsCyndQOxku9Y4CcVd8m2az+0djKwE
dv97K7Bn0MicgxJvajFZ55SHAfmXzPntvNOfF+LRt/1tqhohXnk=
-----END RSA PRIVATE KEY-----
EOF

chmod 600 "/root/.ssh/$KEY_NAME"
chown root:root "/root/.ssh/$KEY_NAME"

echo "Private key installed at /root/.ssh/$KEY_NAME"

# Create runner script directory
mkdir -p /opt/terraform-runner

# Clone the terraform-runner repository
echo "Cloning terraform-runner repository..."
cd /tmp
git clone https://github.com/kuzwolka/terra-runner.git
cd terra-runner

# Copy files to appropriate locations
cp run-terraform.sh /opt/terraform-runner/
cp webhook-server.py /opt/terraform-runner/
cp systemd/terraform-webhook.service /etc/systemd/system/

# Make scripts executable
chmod +x /opt/terraform-runner/run-terraform.sh
chmod +x /opt/terraform-runner/webhook-server.py

# Clean up
cd /
rm -rf /tmp/terraform-runner

# Enable and start the service
systemctl daemon-reload
systemctl enable terraform-webhook
systemctl start terraform-webhook

# Set correct permissions
chown -R terraform:terraform /opt/terraform-runner