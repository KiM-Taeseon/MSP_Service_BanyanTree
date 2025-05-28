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

mkdir -p /home/terraform/.ssh
chmod 700 /home/terraform/.ssh

cat > "/home/terraform/.ssh/$KEY_NAME" << 'EOF'
----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABFwAAAAdzc2gtcn
NhAAAAAwEAAQAAAQEApskiaxZ2Wt5DeeL7be25ToeufhPR01Cu9CaLAJXf3+Xh+j9mDtj7
gifTaX7LoefVIctCjkpOf/NNgdHlEL6Nc+Skuk5i6TwidLuHV7mG3tsk7Xv34DUTRT4xBN
Of9ncxa1eEU26Kr+zO25nmTTZcV2cAOkn3k11eRnlD/lIZsZCM5D1Vw1jGZ1o9nceqAzVr
huyuC09JyEXL6yGhsBVOIr/yvxwrkNkI/RhnRKlCxSalklWr8X6HeAdHCNS6cYlUxd4EQN
eDG+q7H5GSBceZ8z4QblJPvmhJ9435U9vCGi/xz2IKVy0GU4UzzKOgfuXqcxP/8jSDjx/T
XCSI6rZc/QAAA8it5my3reZstwAAAAdzc2gtcnNhAAABAQCmySJrFnZa3kN54vtt7blOh6
5+E9HTUK70JosAld/f5eH6P2YO2PuCJ9Npfsuh59Uhy0KOSk5/802B0eUQvo1z5KS6TmLp
PCJ0u4dXuYbe2yTte/fgNRNFPjEE05/2dzFrV4RTboqv7M7bmeZNNlxXZwA6SfeTXV5GeU
P+UhmxkIzkPVXDWMZnWj2dx6oDNWuG7K4LT0nIRcvrIaGwFU4iv/K/HCuQ2Qj9GGdEqULF
JqWSVavxfod4B0cI1LpxiVTF3gRA14Mb6rsfkZIFx5nzPhBuUk++aEn3jflT28IaL/HPYg
pXLQZThTPMo6B+5epzE//yNIOPH9NcJIjqtlz9AAAAAwEAAQAAAQASAY5JCBMdsE08ms1m
NXoCCRKaOJg4kMddQyP9RjD17SLpGhsckz8OnYTCKOw3EzOmra5bykM7URBsaYqqCh3KBe
860JJLzTAzG2PQjA5hf5XhsGE3FW56f+0EMQyzVnRBZctlbn5j4SmxT6Yrbn5S+U3EUo6l
8Y3nXIQuBWhnYPUHAEATRIrBfN0DbgGcY8Ra56UhRaCrjGRg31F00SI17sSyiB17VZigRM
CjRKG7hxIy9AZm4OS5ewdAJuBHpeEDG35U85AH5fkeIdvELhU0Pb1aZ3hgBW1L9XP07A/V
eF2ahUqujTU7Oc9146mVf2qs64TUSI8Qj8eufOy9j3CJAAAAgQC/NPIZcIeymaAtH3MvsS
t1vH0zpJKp3GW0NP6IflM04vC9Atd0arpbLei5Wu5rD6qFcsBXOzcuc7Y7MeYA/NOhGzyW
Z1W+edsaaOcPDu8bFc38Y3o6L+hQnWqi4aDojOBlOIlBgTq6TKxNZ54bVq1eLYkbsQp0UH
sGAtOdOaScrgAAAIEAw+38RAjIcpxFhH8QmHmTv9zAxFSpIVgGNwKGYTg+6w4DUc7B2zJw
mqO4TcbHRJ69ryPTGw5KXZ0G2e5Pp5t+GN/IxnW5T5yz2dhDmQ7tOC7Ml+cyO3ydBw1Sx5
XiuE5qrM0c0j1A9LFjia4PSiI6j7AalzD62iDr+F32XOy5lxsAAACBANnrtxSLVgBCizBp
43yMvddrsnwY0dgGBxeTlvJDA7Kw73pSYHC2GStw/RKdzDL4VVBIag7RCrBqPkVhmdOSKR
7eg8L5uWkjYluwzNrDT6h6vhIgoMM0GagHodVwr/KC/T2SUJvx+y08kScaY9MA2fNjsBbe
sxaWW7Hz6Ca9gSXHAAAAEnJvb3RAaXAtMTAtMC0wLTE1NQ==
-----END OPENSSH PRIVATE KEY-----
EOF

chmod 600 "/home/terraform/.ssh/$KEY_NAME"
chown terraform:terraform "/home/terraform/.ssh/$KEY_NAME"

echo "Private key installed at /home/terraform/$KEY_NAME"

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